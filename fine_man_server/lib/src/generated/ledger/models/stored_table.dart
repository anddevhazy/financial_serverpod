/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:fine_man_server/src/generated/protocol.dart' as _i1iyzdmn;
import 'package:serverpod/serverpod.dart' as _is;
import '../../ledger/models/ledger_columns.dart' as _i2gra6di;
import '../../ledger/models/ledger_note.dart' as _i9z5lido;

/// A table in the database. The entries, notes and list order always load and
/// save together with their table, so they live inside its row as JSON.
abstract class StoredTable
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  StoredTable._({
    this.id,
    required this.ownerId,
    required this.tableId,
    required this.name,
    required this.createdAt,
    required this.entries,
    required this.notes,
    required this.listOrder,
  });

  factory StoredTable({
    int? id,
    required _is.UuidValue ownerId,
    required String tableId,
    required String name,
    required DateTime createdAt,
    required _i2gra6di.LedgerColumns entries,
    required List<_i9z5lido.LedgerNote> notes,
    required List<String> listOrder,
  }) = _StoredTableImpl;

  factory StoredTable.fromJson(Map<String, dynamic> jsonSerialization) {
    return StoredTable(
      id: jsonSerialization['id'] as int?,
      ownerId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['ownerId'],
      ),
      tableId: jsonSerialization['tableId'] as String,
      name: jsonSerialization['name'] as String,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      entries: _i1iyzdmn.Protocol().deserialize<_i2gra6di.LedgerColumns>(
        jsonSerialization['entries'],
      ),
      notes: _i1iyzdmn.Protocol().deserialize<List<_i9z5lido.LedgerNote>>(
        jsonSerialization['notes'],
      ),
      listOrder: _i1iyzdmn.Protocol().deserialize<List<String>>(
        jsonSerialization['listOrder'],
      ),
    );
  }

  static final t = StoredTableTable();

  static const db = StoredTableRepository._();

  @override
  int? id;

  _is.UuidValue ownerId;

  String tableId;

  String name;

  DateTime createdAt;

  _i2gra6di.LedgerColumns entries;

  List<_i9z5lido.LedgerNote> notes;

  List<String> listOrder;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [StoredTable]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  StoredTable copyWith({
    int? id,
    _is.UuidValue? ownerId,
    String? tableId,
    String? name,
    DateTime? createdAt,
    _i2gra6di.LedgerColumns? entries,
    List<_i9z5lido.LedgerNote>? notes,
    List<String>? listOrder,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'StoredTable',
      if (id != null) 'id': id,
      'ownerId': ownerId.toJson(),
      'tableId': tableId,
      'name': name,
      'createdAt': createdAt.toJson(),
      'entries': entries.toJson(),
      'notes': notes.toJson(valueToJson: (v) => v.toJson()),
      'listOrder': listOrder.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static StoredTableInclude include() {
    return StoredTableInclude._();
  }

  static StoredTableIncludeList includeList({
    _is.WhereExpressionBuilder<StoredTableTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<StoredTableTable>? orderBy,
    _is.OrderByListBuilder<StoredTableTable>? orderByList,
    StoredTableInclude? include,
  }) {
    return StoredTableIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(StoredTable.t),
      orderByList: orderByList?.call(StoredTable.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _StoredTableImpl extends StoredTable {
  _StoredTableImpl({
    int? id,
    required _is.UuidValue ownerId,
    required String tableId,
    required String name,
    required DateTime createdAt,
    required _i2gra6di.LedgerColumns entries,
    required List<_i9z5lido.LedgerNote> notes,
    required List<String> listOrder,
  }) : super._(
         id: id,
         ownerId: ownerId,
         tableId: tableId,
         name: name,
         createdAt: createdAt,
         entries: entries,
         notes: notes,
         listOrder: listOrder,
       );

  /// Returns a shallow copy of this [StoredTable]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  StoredTable copyWith({
    Object? id = _Undefined,
    _is.UuidValue? ownerId,
    String? tableId,
    String? name,
    DateTime? createdAt,
    _i2gra6di.LedgerColumns? entries,
    List<_i9z5lido.LedgerNote>? notes,
    List<String>? listOrder,
  }) {
    return StoredTable(
      id: id is int? ? id : this.id,
      ownerId: ownerId ?? this.ownerId,
      tableId: tableId ?? this.tableId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      entries: entries ?? this.entries.copyWith(),
      notes: notes ?? this.notes.map((e0) => e0.copyWith()).toList(),
      listOrder: listOrder ?? this.listOrder.map((e0) => e0).toList(),
    );
  }
}

class StoredTableUpdateTable extends _is.UpdateTable<StoredTableTable> {
  StoredTableUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> ownerId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.ownerId,
        value,
      );

  _is.ColumnValue<String, String> tableId(String value) => _is.ColumnValue(
    table.tableId,
    value,
  );

  _is.ColumnValue<String, String> name(String value) => _is.ColumnValue(
    table.name,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );

  _is.ColumnValue<_i2gra6di.LedgerColumns, _i2gra6di.LedgerColumns> entries(
    _i2gra6di.LedgerColumns value,
  ) => _is.ColumnValue(
    table.entries,
    value,
  );

  _is.ColumnValue<List<_i9z5lido.LedgerNote>, List<_i9z5lido.LedgerNote>> notes(
    List<_i9z5lido.LedgerNote> value,
  ) => _is.ColumnValue(
    table.notes,
    value,
  );

  _is.ColumnValue<List<String>, List<String>> listOrder(List<String> value) =>
      _is.ColumnValue(
        table.listOrder,
        value,
      );
}

class StoredTableTable extends _is.Table<int?> {
  StoredTableTable({super.tableRelation}) : super(tableName: 'stored_table') {
    updateTable = StoredTableUpdateTable(this);
    ownerId = _is.ColumnUuid(
      'ownerId',
      this,
    );
    tableId = _is.ColumnString(
      'tableId',
      this,
    );
    name = _is.ColumnString(
      'name',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
    entries = _is.ColumnSerializable<_i2gra6di.LedgerColumns>(
      'entries',
      this,
    );
    notes = _is.ColumnSerializable<List<_i9z5lido.LedgerNote>>(
      'notes',
      this,
    );
    listOrder = _is.ColumnSerializable<List<String>>(
      'listOrder',
      this,
    );
  }

  late final StoredTableUpdateTable updateTable;

  late final _is.ColumnUuid ownerId;

  late final _is.ColumnString tableId;

  late final _is.ColumnString name;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnSerializable<_i2gra6di.LedgerColumns> entries;

  late final _is.ColumnSerializable<List<_i9z5lido.LedgerNote>> notes;

  late final _is.ColumnSerializable<List<String>> listOrder;

  @override
  List<_is.Column> get columns => [
    id,
    ownerId,
    tableId,
    name,
    createdAt,
    entries,
    notes,
    listOrder,
  ];
}

class StoredTableInclude extends _is.IncludeObject {
  StoredTableInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => StoredTable.t;
}

class StoredTableIncludeList extends _is.IncludeList {
  StoredTableIncludeList._({
    _is.WhereExpressionBuilder<StoredTableTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(StoredTable.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => StoredTable.t;
}

class StoredTableRepository {
  const StoredTableRepository._();

  /// Returns a list of [StoredTable]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<StoredTable>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<StoredTableTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<StoredTableTable>? orderBy,
    _is.OrderByListBuilder<StoredTableTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<StoredTable>(
      where: where?.call(StoredTable.t),
      orderBy: orderBy?.call(StoredTable.t),
      orderByList: orderByList?.call(StoredTable.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [StoredTable] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<StoredTable?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<StoredTableTable>? where,
    int? offset,
    _is.OrderByBuilder<StoredTableTable>? orderBy,
    _is.OrderByListBuilder<StoredTableTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<StoredTable>(
      where: where?.call(StoredTable.t),
      orderBy: orderBy?.call(StoredTable.t),
      orderByList: orderByList?.call(StoredTable.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [StoredTable] by its [id] or null if no such row exists.
  Future<StoredTable?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<StoredTable>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [StoredTable]s in the list and returns the inserted rows.
  ///
  /// The returned [StoredTable]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  ///
  /// If [noReturn] is set to `true`, the inserted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<StoredTable>> insert(
    _is.DatabaseSession session,
    List<StoredTable> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<StoredTable>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [StoredTable] and returns the inserted row.
  ///
  /// The returned [StoredTable] will have its `id` field set.
  Future<StoredTable> insertRow(
    _is.DatabaseSession session,
    StoredTable row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<StoredTable>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [StoredTable]s in the list and returns the resulting rows.
  ///
  /// If a row conflicts on the given [conflictColumns], the existing row is
  /// updated with the new values. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies to rows matching the
  /// given expression. Conflicting rows that don't match are skipped and not
  /// returned, so the resulting list may be shorter than [rows].
  ///
  /// The returned [StoredTable]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<StoredTable>> upsert(
    _is.DatabaseSession session,
    List<StoredTable> rows, {
    required _is.ColumnSelections<StoredTableTable> conflictColumns,
    _is.ColumnSelections<StoredTableTable>? updateColumns,
    _is.WhereExpressionBuilder<StoredTableTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<StoredTable>(
      rows,
      conflictColumns: conflictColumns(StoredTable.t),
      updateColumns: updateColumns?.call(StoredTable.t),
      updateWhere: updateWhere?.call(StoredTable.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [StoredTable] and returns the resulting row.
  ///
  /// If the row conflicts on the given [conflictColumns], the existing row is
  /// updated. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies when the existing
  /// row matches the expression. Returns `null` if no row was affected — for
  /// example when [updateWhere] does not match the conflicting row.
  ///
  /// The returned [StoredTable] will have its `id` field set.
  Future<StoredTable?> upsertRow(
    _is.DatabaseSession session,
    StoredTable row, {
    required _is.ColumnSelections<StoredTableTable> conflictColumns,
    _is.ColumnSelections<StoredTableTable>? updateColumns,
    _is.WhereExpressionBuilder<StoredTableTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<StoredTable>(
      row,
      conflictColumns: conflictColumns(StoredTable.t),
      updateColumns: updateColumns?.call(StoredTable.t),
      updateWhere: updateWhere?.call(StoredTable.t),
      transaction: transaction,
    );
  }

  /// Updates all [StoredTable]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<StoredTable>> update(
    _is.DatabaseSession session,
    List<StoredTable> rows, {
    _is.ColumnSelections<StoredTableTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<StoredTable>(
      rows,
      columns: columns?.call(StoredTable.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [StoredTable]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<StoredTable> updateRow(
    _is.DatabaseSession session,
    StoredTable row, {
    _is.ColumnSelections<StoredTableTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<StoredTable>(
      row,
      columns: columns?.call(StoredTable.t),
      transaction: transaction,
    );
  }

  /// Updates a single [StoredTable] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<StoredTable?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<StoredTableUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<StoredTable>(
      id,
      columnValues: columnValues(StoredTable.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [StoredTable]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<StoredTable>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<StoredTableUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<StoredTableTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<StoredTableTable>? orderBy,
    _is.OrderByListBuilder<StoredTableTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<StoredTable>(
      columnValues: columnValues(StoredTable.t.updateTable),
      where: where(StoredTable.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(StoredTable.t),
      orderByList: orderByList?.call(StoredTable.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [StoredTable]s in the list and returns the deleted rows.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<StoredTable>> delete(
    _is.DatabaseSession session,
    List<StoredTable> rows, {
    _is.OrderByBuilder<StoredTableTable>? orderBy,
    _is.OrderByListBuilder<StoredTableTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<StoredTable>(
      rows,
      orderBy: orderBy?.call(StoredTable.t),
      orderByList: orderByList?.call(StoredTable.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [StoredTable].
  Future<StoredTable> deleteRow(
    _is.DatabaseSession session,
    StoredTable row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<StoredTable>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<StoredTable>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<StoredTableTable> where,
    _is.OrderByBuilder<StoredTableTable>? orderBy,
    _is.OrderByListBuilder<StoredTableTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<StoredTable>(
      where: where(StoredTable.t),
      orderBy: orderBy?.call(StoredTable.t),
      orderByList: orderByList?.call(StoredTable.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<StoredTableTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<StoredTable>(
      where: where?.call(StoredTable.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [StoredTable] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<StoredTableTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<StoredTable>(
      where: where(StoredTable.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
