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
import '../../ledger/models/ledger_table_data.dart' as _i311tf5i;

/// A change to the signed-in user's tables. Exactly one field is set. A stream
/// always opens with [snapshot], so reconnecting catches up on anything missed.
abstract class LedgerEvent
    implements _is.SerializableModel, _is.ProtocolSerialization {
  LedgerEvent._({
    this.snapshot,
    this.updated,
    this.deletedId,
  });

  factory LedgerEvent({
    List<_i311tf5i.LedgerTableData>? snapshot,
    _i311tf5i.LedgerTableData? updated,
    String? deletedId,
  }) = _LedgerEventImpl;

  factory LedgerEvent.fromJson(Map<String, dynamic> jsonSerialization) {
    return LedgerEvent(
      snapshot: jsonSerialization['snapshot'] == null
          ? null
          : _i1iyzdmn.Protocol().deserialize<List<_i311tf5i.LedgerTableData>>(
              jsonSerialization['snapshot'],
            ),
      updated: jsonSerialization['updated'] == null
          ? null
          : _i1iyzdmn.Protocol().deserialize<_i311tf5i.LedgerTableData>(
              jsonSerialization['updated'],
            ),
      deletedId: jsonSerialization['deletedId'] as String?,
    );
  }

  List<_i311tf5i.LedgerTableData>? snapshot;

  _i311tf5i.LedgerTableData? updated;

  String? deletedId;

  /// Returns a shallow copy of this [LedgerEvent]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  LedgerEvent copyWith({
    List<_i311tf5i.LedgerTableData>? snapshot,
    _i311tf5i.LedgerTableData? updated,
    String? deletedId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LedgerEvent',
      if (snapshot != null)
        'snapshot': snapshot?.toJson(valueToJson: (v) => v.toJson()),
      if (updated != null) 'updated': updated?.toJson(),
      if (deletedId != null) 'deletedId': deletedId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LedgerEvent',
      if (snapshot != null)
        'snapshot': snapshot?.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      if (updated != null) 'updated': updated?.toJsonForProtocol(),
      if (deletedId != null) 'deletedId': deletedId,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LedgerEventImpl extends LedgerEvent {
  _LedgerEventImpl({
    List<_i311tf5i.LedgerTableData>? snapshot,
    _i311tf5i.LedgerTableData? updated,
    String? deletedId,
  }) : super._(
         snapshot: snapshot,
         updated: updated,
         deletedId: deletedId,
       );

  /// Returns a shallow copy of this [LedgerEvent]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  LedgerEvent copyWith({
    Object? snapshot = _Undefined,
    Object? updated = _Undefined,
    Object? deletedId = _Undefined,
  }) {
    return LedgerEvent(
      snapshot: snapshot is List<_i311tf5i.LedgerTableData>?
          ? snapshot
          : this.snapshot?.map((e0) => e0.copyWith()).toList(),
      updated: updated is _i311tf5i.LedgerTableData?
          ? updated
          : this.updated?.copyWith(),
      deletedId: deletedId is String? ? deletedId : this.deletedId,
    );
  }
}
