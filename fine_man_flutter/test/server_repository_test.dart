import 'dart:async';

import 'package:fine_man_client/fine_man_client.dart';
import 'package:fine_man_flutter/data/ledger_mapping.dart';
import 'package:fine_man_flutter/data/server_ledger_repository.dart';
import 'package:fine_man_flutter/models/ledger.dart';
import 'package:flutter_test/flutter_test.dart';

/// A server that answers only when the test says so, and records what it got.
class FakeApi implements LedgerApi {
  final calls = <String>[];
  final List<Completer<void>> answers = [];
  bool holdWrites = false;
  Object? failWith;
  int connections = 0;
  late StreamController<LedgerEvent> stream;

  void pushSnapshot(List<LedgerTable> tables) => stream.add(
    LedgerEvent(snapshot: [for (final t in tables) tableToData(t)]),
  );

  Future<void> _call(String name) async {
    calls.add(name);
    if (failWith case final error?) throw error;
    if (holdWrites) {
      final answer = Completer<void>();
      answers.add(answer);
      await answer.future;
    }
  }

  @override
  Stream<LedgerEvent> events() {
    connections++;
    stream = StreamController<LedgerEvent>();
    return stream.stream;
  }

  @override
  Future<List<LedgerTableData>> list() async => [];
  @override
  Future<void> saveTables(List<LedgerTableData> tables) =>
      _call('saveTables ${tables.length}');
  @override
  Future<void> rename(String tableId, String name) => _call('rename $name');
  @override
  Future<void> delete(String tableId) => _call('delete $tableId');
  @override
  Future<void> saveColumns(String tableId, LedgerColumns columns) =>
      _call('saveColumns ${columns.need.length}');
  @override
  Future<void> saveNotes(String tableId, List<LedgerNote> notes) =>
      _call('saveNotes');
  @override
  Future<void> saveListOrder(String tableId, List<String> listOrder) =>
      _call('saveListOrder');
}

LedgerTable table(String id, {String? name}) => LedgerTable(
  id: id,
  name: name ?? id,
  createdAt: DateTime(2026, 10, 19),
  columns: LedgerTable.columnsFromMap(null),
);

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 5));

void main() {
  late FakeApi api;
  late ServerLedgerRepository repo;
  late List<String> rejections;

  setUp(() {
    api = FakeApi();
    rejections = [];
    repo = ServerLedgerRepository(
      api,
      onRejected: rejections.add,
      backoff: (_) => Duration.zero,
    );
  });

  tearDown(() => repo.dispose());

  Future<List<LedgerTable>> loaded(List<LedgerTable> tables) async {
    final first = repo.watchTables().first;
    await settle();
    api.pushSnapshot(tables);
    return first;
  }

  test('watchers wait for the first snapshot, newest first', () async {
    final older = LedgerTable(
      id: 'old',
      name: 'Old',
      createdAt: DateTime(2025),
      columns: LedgerTable.columnsFromMap(null),
    );
    final tables = await loaded([older, table('new')]);
    expect([for (final t in tables) t.id], ['new', 'old']);
  });

  test('dates arrive in local time and survive the trip', () {
    final original = table('t');
    final back = tableFromData(tableToData(original));
    expect(back.createdAt, original.createdAt);
    expect(back.createdAt.isUtc, isFalse);
  });

  test('everything in a table survives the trip', () {
    final original = table('t')
        .addEntry(LedgerColumn.tithe, const Entry(id: 'e', name: 'Church'))
        .addSub(
          LedgerColumn.tithe,
          'e',
          const SubEntry(id: 's', name: 'Offering', amount: 500),
        )
        .copyWith(
          listOrder: const ['e'],
          notes: const [
            TextBlock('Hello'),
            ImageBlock(url: 'https://a.test/b.png', publicId: 'b', width: 2),
          ],
        );
    final back = tableFromData(tableToData(original));
    expect(back.toJson(), original.toJson());
  });

  test('a change shows at once, before the server answers', () async {
    await loaded([table('t')]);
    api.holdWrites = true;
    unawaited(repo.renameTable('t', 'Renamed'));
    final view = await repo.watchTable('t').first;
    expect(view!.name, 'Renamed');
    api.answers.single.complete();
  });

  test('a new table can be opened before the server answers', () async {
    await loaded([]);
    api.holdWrites = true;
    final created = await repo.createTable('October');
    expect((await repo.watchTable(created.id).first)!.name, 'October');
    api.answers.single.complete();
  });

  test('changes reach the server one at a time, in order', () async {
    await loaded([table('t')]);
    api.holdWrites = true;
    final base = table('t');
    final one = base.addEntry(
      LedgerColumn.need,
      const Entry(id: 'a', name: 'A'),
    );
    final two = one.addEntry(
      LedgerColumn.need,
      const Entry(id: 'b', name: 'B'),
    );
    unawaited(repo.saveColumns(one));
    unawaited(repo.saveColumns(two));
    await settle();
    expect(api.calls, ['saveColumns 1']);

    api.answers[0].complete();
    await settle();
    expect(api.calls, ['saveColumns 1', 'saveColumns 2']);
    api.answers[1].complete();
    await repo.flush();
  });

  test('a server update can’t undo a change still on its way', () async {
    await loaded([table('t', name: 'Before')]);
    api.holdWrites = true;
    unawaited(repo.renameTable('t', 'Mine'));
    await settle();

    api.stream.add(
      LedgerEvent(updated: tableToData(table('t', name: 'Theirs'))),
    );
    await settle();
    expect((await repo.watchTable('t').first)!.name, 'Mine');

    api.answers.single.complete();
    await settle();
    expect((await repo.watchTable('t').first)!.name, 'Mine');
  });

  test('changes from other devices show up', () async {
    await loaded([table('a')]);
    final seen = <List<String>>[];
    final sub = repo.watchTables().listen(
      (tables) => seen.add([for (final t in tables) t.name]),
    );
    addTearDown(sub.cancel);
    await settle();

    api.stream.add(LedgerEvent(updated: tableToData(table('b', name: 'B'))));
    await settle();
    expect(seen.last, containsAll(['a', 'B']));
    api.stream.add(LedgerEvent(deletedId: 'a'));
    await settle();
    expect(seen.last, ['B']);
  });

  test('a refused change is undone and the user is told', () async {
    await loaded([table('t', name: 'Before')]);
    api.failWith = LedgerException(message: 'That amount is too large.');
    await expectLater(
      repo.renameTable('t', 'After'),
      throwsA(isA<LedgerException>()),
    );
    expect(rejections, ['That amount is too large.']);
    expect((await repo.watchTable('t').first)!.name, 'Before');
  });

  test('a refused change doesn’t block the ones after it', () async {
    await loaded([table('t')]);
    api.failWith = LedgerException(message: 'No');
    unawaited(repo.renameTable('t', 'A'));
    await settle();
    api.failWith = null;
    await repo.renameTable('t', 'B');
    expect((await repo.watchTable('t').first)!.name, 'B');
  });

  test('a lost connection retries until the change gets through', () async {
    await loaded([table('t')]);
    api.failWith = const ServerpodClientNetworkException('offline');
    final save = repo.renameTable('t', 'After');
    await settle();
    expect(api.calls.length, greaterThan(1));
    expect(repo.connected.value, isFalse);
    expect((await repo.watchTable('t').first)!.name, 'After');

    api.failWith = null;
    await save;
    expect(repo.connected.value, isTrue);
    expect(rejections, isEmpty);
  });

  test('a server that keeps failing eventually gives up', () async {
    await loaded([table('t', name: 'Before')]);
    api.failWith = ServerpodClientInternalServerError();
    await expectLater(
      repo.renameTable('t', 'After'),
      throwsA(isA<ServerpodClientInternalServerError>()),
    );
    expect(api.calls, hasLength(5));
    expect(rejections, hasLength(1));
    expect((await repo.watchTable('t').first)!.name, 'Before');
  });

  test('a dropped stream reconnects and catches up', () async {
    await loaded([table('t', name: 'Before')]);
    await api.stream.close();
    await settle();
    expect(api.connections, 2);
    expect(repo.connected.value, isFalse);

    api.pushSnapshot([table('t', name: 'Missed')]);
    await settle();
    expect(repo.connected.value, isTrue);
    expect((await repo.watchTable('t').first)!.name, 'Missed');
  });

  test('a change made while disconnected survives the catch-up', () async {
    await loaded([table('t', name: 'Before')]);
    await api.stream.close();
    await settle();
    api.holdWrites = true;
    unawaited(repo.renameTable('t', 'Mine'));
    await settle();

    api.pushSnapshot([table('t', name: 'Before')]);
    await settle();
    expect((await repo.watchTable('t').first)!.name, 'Mine');
    api.answers.single.complete();
  });

  test('watchers hear when the first load fails, then get the data', () async {
    final seen = <Object>[];
    final sub = repo.watchTables().listen(seen.add, onError: seen.add);
    addTearDown(sub.cancel);
    await settle();
    api.stream.addError(const ServerpodClientNetworkException('offline'));
    await settle();
    expect(seen.first, isA<LedgerUnavailable>());

    api.pushSnapshot([table('t')]);
    await settle();
    expect(seen.last, isA<List<LedgerTable>>());
  });

  test('imports go in batches and finish when all have landed', () async {
    await loaded([]);
    await repo.importTables([for (var i = 0; i < 45; i++) table('t$i')]);
    expect(api.calls, ['saveTables 20', 'saveTables 20', 'saveTables 5']);
    expect(await repo.allTables(), hasLength(45));
  });

  test('flush waits for everything on its way', () async {
    await loaded([table('t')]);
    api.holdWrites = true;
    unawaited(repo.renameTable('t', 'A'));
    unawaited(repo.renameTable('t', 'B'));
    var flushed = false;
    unawaited(repo.flush().then((_) => flushed = true));
    await settle();
    expect(flushed, isFalse);
    api.answers[0].complete();
    await settle();
    expect(flushed, isFalse);
    api.answers[1].complete();
    await settle();
    expect(flushed, isTrue);
  });
}
