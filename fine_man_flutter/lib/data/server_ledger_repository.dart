import 'dart:async';

import 'package:fine_man_client/fine_man_client.dart';
import 'package:flutter/foundation.dart';

import '../models/ledger.dart';
import 'ledger_mapping.dart';
import 'ledger_repository.dart';

/// The part of the server this repository talks to. Tests replace it.
abstract interface class LedgerApi {
  Stream<LedgerEvent> events();
  Future<List<LedgerTableData>> list();
  Future<void> saveTables(List<LedgerTableData> tables);
  Future<void> rename(String tableId, String name);
  Future<void> delete(String tableId);
  Future<void> saveColumns(String tableId, LedgerColumns columns);
  Future<void> saveNotes(String tableId, List<LedgerNote> notes);
  Future<void> saveListOrder(String tableId, List<String> listOrder);
}

class ClientLedgerApi implements LedgerApi {
  ClientLedgerApi(this._client);

  final Client _client;

  @override
  Stream<LedgerEvent> events() => _client.ledger.events();
  @override
  Future<List<LedgerTableData>> list() => _client.ledger.list();
  @override
  Future<void> saveTables(List<LedgerTableData> tables) =>
      _client.ledger.saveTables(tables);
  @override
  Future<void> rename(String tableId, String name) =>
      _client.ledger.rename(tableId, name);
  @override
  Future<void> delete(String tableId) => _client.ledger.delete(tableId);
  @override
  Future<void> saveColumns(String tableId, LedgerColumns columns) =>
      _client.ledger.saveColumns(tableId, columns);
  @override
  Future<void> saveNotes(String tableId, List<LedgerNote> notes) =>
      _client.ledger.saveNotes(tableId, notes);
  @override
  Future<void> saveListOrder(String tableId, List<String> listOrder) =>
      _client.ledger.saveListOrder(tableId, listOrder);
}

/// Thrown to anyone watching while the first load keeps failing. Watchers get
/// the tables as soon as a retry succeeds.
class LedgerUnavailable implements Exception {
  const LedgerUnavailable();

  @override
  String toString() => 'Can’t reach the server. Still trying…';
}

typedef _Tables = Map<String, LedgerTable>;

/// One change waiting to reach the server.
class _Write {
  _Write(this.apply, this.send);

  /// Makes the change to a local copy of the tables.
  final void Function(_Tables tables) apply;

  /// Makes the change on the server.
  final Future<void> Function() send;

  final done = Completer<void>();
  int serverErrors = 0;
}

/// Stores tables on the server and keeps them in sync across devices.
///
/// The screens expect every save to show up immediately, including while
/// typing fast, so a change is visible as soon as it's made:
///
/// * [_confirmed] is the tables as last heard from the server, kept current by
///   one event stream that reconnects whenever it drops.
/// * [_pending] is local changes the server hasn't accepted yet. They're sent
///   one at a time, in order, and retried until the connection returns.
/// * What the screens see is [_confirmed] with [_pending] applied on top, so an
///   update from the server can't undo a change that's still on its way.
///
/// If the server refuses a change, it's dropped, the screens go back to what
/// the server has, and [onRejected] is told why.
class ServerLedgerRepository implements LedgerRepository {
  ServerLedgerRepository(
    this._api, {
    this.onRejected,
    Duration Function(int attempt)? backoff,
  }) : _backoff = backoff ?? _defaultBackoff;

  final LedgerApi _api;

  /// Called with a message for the user when the server refuses a change.
  final void Function(String message)? onRejected;

  final Duration Function(int attempt) _backoff;

  /// Tables per save when importing, to stay under the server's request limit.
  static const _importBatch = 20;

  /// Times to retry a write the server failed on, as opposed to one that
  /// couldn't reach it. More than this and it's unlikely to go through later.
  static const _maxServerErrors = 5;

  static Duration _defaultBackoff(int attempt) =>
      Duration(seconds: attempt < 5 ? 1 << attempt : 30);

  final _Tables _confirmed = {};
  final List<_Write> _pending = [];
  final _changes = StreamController<void>.broadcast();

  StreamSubscription<LedgerEvent>? _events;
  Timer? _reconnect;
  int _reconnectAttempts = 0;
  bool _started = false;
  bool _loaded = false;
  bool _failedToLoad = false;
  bool _draining = false;
  bool _disposed = false;

  final _connected = ValueNotifier(true);

  /// False while the server can't be reached.
  ValueListenable<bool> get connected => _connected;

  /// Stops syncing. Changes still waiting are abandoned, so call [flush] first
  /// when they matter.
  void dispose() {
    _disposed = true;
    _reconnect?.cancel();
    _events?.cancel();
    _changes.close();
    _connected.dispose();
    for (final write in _pending) {
      write.done.completeError(StateError('Signed out before saving.'));
    }
    _pending.clear();
  }

  /// Completes once every change made so far has reached the server.
  Future<void> flush() =>
      _pending.isEmpty ? Future.value() : _pending.last.done.future;

  // ---- Reading ----

  _Tables get _view {
    final tables = {..._confirmed};
    for (final write in _pending) {
      write.apply(tables);
    }
    return tables;
  }

  List<LedgerTable> _sorted(_Tables tables) =>
      tables.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Stream<T> _watch<T>(T Function(_Tables tables) read) {
    late final StreamController<T> out;
    StreamSubscription<void>? sub;

    void push() {
      if (out.isClosed) return;
      if (_loaded) {
        out.add(read(_view));
      } else if (_failedToLoad) {
        out.addError(const LedgerUnavailable());
      }
    }

    out = StreamController<T>(
      onListen: () {
        _connect();
        sub = _changes.stream.listen((_) => push());
        push();
      },
      onCancel: () => sub?.cancel(),
    );
    return out.stream;
  }

  @override
  Stream<List<LedgerTable>> watchTables() => _watch(_sorted);

  @override
  Stream<LedgerTable?> watchTable(String id) => _watch((tables) => tables[id]);

  @override
  Future<List<LedgerTable>> allTables() async {
    if (_loaded) return _sorted(_view);
    return [for (final t in await _api.list()) tableFromData(t)];
  }

  // ---- The event stream ----

  void _connect() {
    if (_started || _disposed) return;
    _started = true;
    _listen();
  }

  void _listen() {
    if (_disposed) return;
    _events = _api.events().listen(
      _onEvent,
      onError: (Object _) => _onDropped(),
      onDone: _onDropped,
      cancelOnError: true,
    );
  }

  void _onEvent(LedgerEvent event) {
    if (_disposed) return;
    if (event.snapshot case final snapshot?) {
      _confirmed
        ..clear()
        ..addAll({for (final t in snapshot) t.id: tableFromData(t)});
      _loaded = true;
      _failedToLoad = false;
      _reconnectAttempts = 0;
      _setConnected(true);
    } else if (event.updated case final updated?) {
      _confirmed[updated.id] = tableFromData(updated);
    } else if (event.deletedId case final id?) {
      _confirmed.remove(id);
    }
    _changes.add(null);
  }

  void _onDropped() {
    if (_disposed) return;
    _setConnected(false);
    if (!_loaded) {
      _failedToLoad = true;
      _changes.add(null);
    }
    _reconnect = Timer(_backoff(_reconnectAttempts++), _listen);
  }

  void _setConnected(bool value) {
    if (!_disposed) _connected.value = value;
  }

  // ---- Writing ----

  Future<void> _enqueue(_Write write) {
    if (_disposed) {
      return Future.error(StateError('Signed out before saving.'));
    }
    _connect();
    _pending.add(write);
    // Callers often don't wait for a save. A refusal reaches onRejected, so
    // it mustn't also surface as an unhandled error.
    write.done.future.ignore();
    _changes.add(null);
    unawaited(_drain());
    return write.done.future;
  }

  Future<void> _drain() async {
    if (_draining) return;
    _draining = true;
    var attempt = 0;
    while (_pending.isNotEmpty && !_disposed) {
      final write = _pending.first;
      try {
        await write.send();
        if (_disposed) break;
        attempt = 0;
        _setConnected(true);
        write.apply(_confirmed);
        _pending.removeAt(0);
        _changes.add(null);
        write.done.complete();
      } catch (error) {
        if (_disposed) break;
        if (_shouldRetry(error, write)) {
          if (error is! ServerpodClientInternalServerError) {
            _setConnected(false);
          }
          await Future<void>.delayed(_backoff(attempt++));
        } else {
          attempt = 0;
          _pending.removeAt(0);
          _changes.add(null);
          write.done.completeError(error);
          onRejected?.call(_describe(error));
        }
      }
    }
    _draining = false;
  }

  bool _shouldRetry(Object error, _Write write) => switch (error) {
    ServerpodClientInternalServerError() =>
      ++write.serverErrors < _maxServerErrors,
    LedgerException() || ServerpodClientHttpException() => false,
    // Everything else means the request never got an answer.
    _ => true,
  };

  String _describe(Object error) => switch (error) {
    LedgerException(:final message) => message,
    ServerpodClientUnauthorized() =>
      'You’ve been signed out, so that change wasn’t saved.',
    _ => 'That change couldn’t be saved.',
  };

  void Function(_Tables) _patch(
    String id,
    LedgerTable Function(LedgerTable table) change,
  ) => (tables) {
    final table = tables[id];
    if (table != null) tables[id] = change(table);
  };

  @override
  Future<LedgerTable> createTable(String name) async {
    final table = LedgerTable(
      id: newId(),
      name: name,
      createdAt: nowForStorage(),
      columns: LedgerTable.columnsFromMap(null),
    );
    unawaited(_saveTables([table]));
    return table;
  }

  Future<void> _saveTables(List<LedgerTable> tables) => _enqueue(
    _Write(
      (view) => view.addAll({for (final t in tables) t.id: t}),
      () => _api.saveTables([for (final t in tables) tableToData(t)]),
    ),
  );

  @override
  Future<void> importTables(List<LedgerTable> tables) async {
    final batches = [
      for (var i = 0; i < tables.length; i += _importBatch)
        _saveTables(tables.skip(i).take(_importBatch).toList()),
    ];
    await Future.wait(batches);
  }

  @override
  Future<void> renameTable(String id, String name) => _enqueue(
    _Write(
      _patch(id, (t) => t.copyWith(name: name)),
      () => _api.rename(id, name),
    ),
  );

  @override
  Future<void> deleteTable(String id) => _enqueue(
    _Write((view) => view.remove(id), () => _api.delete(id)),
  );

  @override
  Future<void> saveColumns(LedgerTable table) {
    final columns = table.columns;
    final data = columnsToData(table);
    return _enqueue(
      _Write(
        _patch(table.id, (t) => t.copyWith(columns: columns)),
        () => _api.saveColumns(table.id, data),
      ),
    );
  }

  @override
  Future<void> saveNotes(String tableId, List<NoteBlock> notes) {
    final data = notesToData(notes);
    return _enqueue(
      _Write(
        _patch(tableId, (t) => t.copyWith(notes: notes)),
        () => _api.saveNotes(tableId, data),
      ),
    );
  }

  @override
  Future<void> saveListOrder(LedgerTable table) {
    final order = table.listOrder;
    return _enqueue(
      _Write(
        _patch(table.id, (t) => t.copyWith(listOrder: order)),
        () => _api.saveListOrder(table.id, order),
      ),
    );
  }
}
