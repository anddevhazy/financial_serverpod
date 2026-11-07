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
import 'package:fine_man_client/src/protocol/protocol.dart' as _ikiosg7s;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import '../../ledger/models/ledger_columns.dart' as _i2gra6di;
import '../../ledger/models/ledger_note.dart' as _i9z5lido;

/// A table as it travels between the app and the server. [id] is chosen by the
/// app, so tables keep their ids through backups and imports.
abstract class LedgerTableData
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  LedgerTableData._({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.columns,
    required this.notes,
    required this.listOrder,
  });

  factory LedgerTableData({
    required String id,
    required String name,
    required DateTime createdAt,
    required _i2gra6di.LedgerColumns columns,
    required List<_i9z5lido.LedgerNote> notes,
    required List<String> listOrder,
  }) = _LedgerTableDataImpl;

  factory LedgerTableData.fromJson(Map<String, dynamic> jsonSerialization) {
    return LedgerTableData(
      id: jsonSerialization['id'] as String,
      name: jsonSerialization['name'] as String,
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      columns: _ikiosg7s.Protocol().deserialize<_i2gra6di.LedgerColumns>(
        jsonSerialization['columns'],
      ),
      notes: _ikiosg7s.Protocol().deserialize<List<_i9z5lido.LedgerNote>>(
        jsonSerialization['notes'],
      ),
      listOrder: _ikiosg7s.Protocol().deserialize<List<String>>(
        jsonSerialization['listOrder'],
      ),
    );
  }

  String id;

  String name;

  DateTime createdAt;

  _i2gra6di.LedgerColumns columns;

  List<_i9z5lido.LedgerNote> notes;

  List<String> listOrder;

  /// Returns a shallow copy of this [LedgerTableData]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  LedgerTableData copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    _i2gra6di.LedgerColumns? columns,
    List<_i9z5lido.LedgerNote>? notes,
    List<String>? listOrder,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LedgerTableData',
      'id': id,
      'name': name,
      'createdAt': createdAt.toJson(),
      'columns': columns.toJson(),
      'notes': notes.toJson(valueToJson: (v) => v.toJson()),
      'listOrder': listOrder.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LedgerTableData',
      'id': id,
      'name': name,
      'createdAt': createdAt.toJson(),
      'columns': columns.toJsonForProtocol(),
      'notes': notes.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'listOrder': listOrder.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _LedgerTableDataImpl extends LedgerTableData {
  _LedgerTableDataImpl({
    required String id,
    required String name,
    required DateTime createdAt,
    required _i2gra6di.LedgerColumns columns,
    required List<_i9z5lido.LedgerNote> notes,
    required List<String> listOrder,
  }) : super._(
         id: id,
         name: name,
         createdAt: createdAt,
         columns: columns,
         notes: notes,
         listOrder: listOrder,
       );

  /// Returns a shallow copy of this [LedgerTableData]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  LedgerTableData copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    _i2gra6di.LedgerColumns? columns,
    List<_i9z5lido.LedgerNote>? notes,
    List<String>? listOrder,
  }) {
    return LedgerTableData(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      columns: columns ?? this.columns.copyWith(),
      notes: notes ?? this.notes.map((e0) => e0.copyWith()).toList(),
      listOrder: listOrder ?? this.listOrder.map((e0) => e0).toList(),
    );
  }
}
