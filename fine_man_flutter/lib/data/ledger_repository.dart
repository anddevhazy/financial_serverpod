import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/ledger.dart';

abstract class LedgerRepository {
  Stream<List<LedgerTable>> watchTables();
  Stream<LedgerTable?> watchTable(String id);
  Future<LedgerTable> createTable(String name);
  Future<void> renameTable(String id, String name);
  Future<void> deleteTable(String id);

  /// Persists every column of [table] (entries and sub-entries).
  Future<void> saveColumns(LedgerTable table);

  /// Replaces the notes of the table with [tableId].
  Future<void> saveNotes(String tableId, List<NoteBlock> notes);

  /// Persists the order of [table]'s single list.
  Future<void> saveListOrder(LedgerTable table);

  Future<List<LedgerTable>> allTables();

  /// Adds [tables], keeping their ids and creation dates.
  /// A table with the same id is replaced.
  Future<void> importTables(List<LedgerTable> tables);
}

/// Keeps tables in this browser's storage. Data survives reloads but
/// belongs to this exact address (e.g. localhost:5050) only.
class LocalLedgerRepository implements LedgerRepository {
  LocalLedgerRepository._(this._prefs, this._tables);

  /// Memory only, nothing is saved. Used by tests and previews.
  LocalLedgerRepository.inMemory() : this._(null, []);

  static const _key = 'fine_man.tables.v1';
  static const _movedKey = 'fine_man.tables.moved_to_account';

  static Future<LocalLedgerRepository> open() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    final tables = raw == null
        ? <LedgerTable>[]
        : [
            for (final t in jsonDecode(raw) as List)
              LedgerTable.fromJson(Map<String, dynamic>.from(t as Map)),
          ];
    return LocalLedgerRepository._(prefs, tables);
  }

  final SharedPreferences? _prefs;
  final List<LedgerTable> _tables;
  final _changes = StreamController<void>.broadcast();

  List<LedgerTable> get _sorted =>
      [..._tables]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  LedgerTable? _find(String id) {
    for (final t in _tables) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<void> _commit() async {
    _changes.add(null);
    await _prefs?.setString(
      _key,
      jsonEncode([for (final t in _tables) t.toJson()]),
    );
  }

  void _replace(LedgerTable table) {
    final i = _tables.indexWhere((t) => t.id == table.id);
    if (i != -1) _tables[i] = table;
  }

  @override
  Stream<List<LedgerTable>> watchTables() async* {
    yield _sorted;
    yield* _changes.stream.map((_) => _sorted);
  }

  @override
  Stream<LedgerTable?> watchTable(String id) async* {
    yield _find(id);
    yield* _changes.stream.map((_) => _find(id));
  }

  @override
  Future<LedgerTable> createTable(String name) async {
    final table = LedgerTable(
      id: newId(),
      name: name,
      createdAt: nowForStorage(),
      columns: LedgerTable.columnsFromMap(null),
    );
    _tables.add(table);
    await _commit();
    return table;
  }

  @override
  Future<void> renameTable(String id, String name) async {
    final table = _find(id);
    if (table == null) return;
    _replace(table.copyWith(name: name));
    await _commit();
  }

  @override
  Future<void> deleteTable(String id) async {
    _tables.removeWhere((t) => t.id == id);
    await _commit();
  }

  @override
  Future<void> saveColumns(LedgerTable table) async {
    final current = _find(table.id);
    if (current == null) return;
    _replace(current.copyWith(columns: table.columns));
    await _commit();
  }

  @override
  Future<void> saveNotes(String tableId, List<NoteBlock> notes) async {
    final current = _find(tableId);
    if (current == null) return;
    _replace(current.copyWith(notes: notes));
    await _commit();
  }

  @override
  Future<void> saveListOrder(LedgerTable table) async {
    final current = _find(table.id);
    if (current == null) return;
    _replace(current.copyWith(listOrder: table.listOrder));
    await _commit();
  }

  @override
  Future<List<LedgerTable>> allTables() async => _sorted;

  @override
  Future<void> importTables(List<LedgerTable> tables) async {
    for (final t in tables) {
      _tables.removeWhere((existing) => existing.id == t.id);
      _tables.add(t);
    }
    await _commit();
  }

  /// Empties local storage once its tables are safely in the account.
  /// A copy is kept under a separate key in case anything goes wrong.
  Future<void> clearAfterMove() async {
    await _prefs?.setString(
      _movedKey,
      jsonEncode([for (final t in _tables) t.toJson()]),
    );
    _tables.clear();
    await _commit();
  }
}
