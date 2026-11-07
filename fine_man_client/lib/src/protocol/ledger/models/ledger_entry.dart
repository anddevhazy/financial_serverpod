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
import '../../ledger/models/ledger_sub_entry.dart' as _iyg9v8m6;

/// A row in a column. [amount] only counts while the entry has no sub-entries.
abstract class LedgerEntry
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  LedgerEntry._({
    required this.id,
    required this.name,
    required this.amount,
    required this.subs,
  });

  factory LedgerEntry({
    required String id,
    required String name,
    required int amount,
    required List<_iyg9v8m6.LedgerSubEntry> subs,
  }) = _LedgerEntryImpl;

  factory LedgerEntry.fromJson(Map<String, dynamic> jsonSerialization) {
    return LedgerEntry(
      id: jsonSerialization['id'] as String,
      name: jsonSerialization['name'] as String,
      amount: jsonSerialization['amount'] as int,
      subs: _ikiosg7s.Protocol().deserialize<List<_iyg9v8m6.LedgerSubEntry>>(
        jsonSerialization['subs'],
      ),
    );
  }

  String id;

  String name;

  int amount;

  List<_iyg9v8m6.LedgerSubEntry> subs;

  /// Returns a shallow copy of this [LedgerEntry]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  LedgerEntry copyWith({
    String? id,
    String? name,
    int? amount,
    List<_iyg9v8m6.LedgerSubEntry>? subs,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LedgerEntry',
      'id': id,
      'name': name,
      'amount': amount,
      'subs': subs.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LedgerEntry',
      'id': id,
      'name': name,
      'amount': amount,
      'subs': subs.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _LedgerEntryImpl extends LedgerEntry {
  _LedgerEntryImpl({
    required String id,
    required String name,
    required int amount,
    required List<_iyg9v8m6.LedgerSubEntry> subs,
  }) : super._(
         id: id,
         name: name,
         amount: amount,
         subs: subs,
       );

  /// Returns a shallow copy of this [LedgerEntry]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  LedgerEntry copyWith({
    String? id,
    String? name,
    int? amount,
    List<_iyg9v8m6.LedgerSubEntry>? subs,
  }) {
    return LedgerEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      subs: subs ?? this.subs.map((e0) => e0.copyWith()).toList(),
    );
  }
}
