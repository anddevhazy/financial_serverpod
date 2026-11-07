import 'dart:async';

import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';

import '../generated/protocol.dart';
import 'ledger_validation.dart';

/// Reads and writes the signed-in user's tables. Every query is scoped to that
/// user, and every change is pushed to all of their open [events] streams.
///
/// Writes are safe to repeat, because the app retries them after losing its
/// connection. Writing to a table that no longer exists does nothing, which
/// happens when another device has just deleted it.
class LedgerEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// The current tables, followed by every change as it happens.
  Stream<LedgerEvent> events(Session session) async* {
    final channel = _channel(session);
    final updates = StreamController<LedgerEvent>();
    void onMessage(SerializableModel message) {
      if (message is LedgerEvent) updates.add(message);
    }

    // Listens before reading, so a change made during the read isn't missed.
    session.messages.addListener(channel, onMessage);
    try {
      yield LedgerEvent(snapshot: await list(session));
      yield* updates.stream;
    } finally {
      session.messages.removeListener(channel, onMessage);
      await updates.close();
    }
  }

  /// Every table, newest first.
  Future<List<LedgerTableData>> list(Session session) async {
    final rows = await StoredTable.db.find(
      session,
      where: (t) => t.ownerId.equals(_owner(session)),
      orderByList: (t) => [t.createdAt.desc()],
    );
    return [for (final row in rows) _toData(row)];
  }

  /// Adds [tables], keeping their ids and creation dates. A table with the same
  /// id is replaced. Either all of them are saved or none are.
  Future<void> saveTables(Session session, List<LedgerTableData> tables) async {
    tables.forEach(validateTable);
    final owner = _owner(session);
    await session.db.transaction((transaction) async {
      for (final table in tables) {
        await StoredTable.db.upsertRow(
          session,
          _toRow(owner, table),
          conflictColumns: (t) => [t.ownerId, t.tableId],
          transaction: transaction,
        );
      }
    });
    for (final table in tables) {
      await _publish(session, LedgerEvent(updated: table));
    }
  }

  Future<void> rename(Session session, String tableId, String name) async {
    validateName(name);
    await _update(session, tableId, (row) => row..name = name, (t) => [t.name]);
  }

  Future<void> saveColumns(
    Session session,
    String tableId,
    LedgerColumns columns,
  ) async {
    validateColumns(columns);
    await _update(
      session,
      tableId,
      (row) => row..entries = columns,
      (t) => [t.entries],
    );
  }

  Future<void> saveNotes(
    Session session,
    String tableId,
    List<LedgerNote> notes,
  ) async {
    validateNotes(notes);
    await _update(
      session,
      tableId,
      (row) => row..notes = notes,
      (t) => [t.notes],
    );
  }

  Future<void> saveListOrder(
    Session session,
    String tableId,
    List<String> listOrder,
  ) async {
    validateListOrder(listOrder);
    await _update(
      session,
      tableId,
      (row) => row..listOrder = listOrder,
      (t) => [t.listOrder],
    );
  }

  Future<void> delete(Session session, String tableId) async {
    final owner = _owner(session);
    final deleted = await StoredTable.db.deleteWhere(
      session,
      where: (t) => t.ownerId.equals(owner) & t.tableId.equals(tableId),
    );
    if (deleted.isNotEmpty) {
      await _publish(session, LedgerEvent(deletedId: tableId));
    }
  }

  /// Changes one field of a table, leaving the rest as they are so that a save
  /// of the notes can't undo a save of the columns from another device.
  Future<void> _update(
    Session session,
    String tableId,
    StoredTable Function(StoredTable row) change,
    List<Column> Function(StoredTableTable t) columns,
  ) async {
    final row = await StoredTable.db.findFirstRow(
      session,
      where: (t) =>
          t.ownerId.equals(_owner(session)) & t.tableId.equals(tableId),
    );
    if (row == null) return;
    final updated = await StoredTable.db.updateRow(
      session,
      change(row),
      columns: columns,
    );
    await _publish(session, LedgerEvent(updated: _toData(updated)));
  }

  Future<void> _publish(Session session, LedgerEvent event) =>
      session.messages.postMessage(_channel(session), event);

  String _channel(Session session) => 'ledger.${_owner(session).uuid}';

  UuidValue _owner(Session session) => session.authenticated!.authUserId;

  LedgerTableData _toData(StoredTable row) => LedgerTableData(
    id: row.tableId,
    name: row.name,
    createdAt: row.createdAt,
    columns: row.entries,
    notes: row.notes,
    listOrder: row.listOrder,
  );

  StoredTable _toRow(UuidValue owner, LedgerTableData table) => StoredTable(
    ownerId: owner,
    tableId: table.id,
    name: table.name,
    createdAt: table.createdAt,
    entries: table.columns,
    notes: table.notes,
    listOrder: table.listOrder,
  );
}
