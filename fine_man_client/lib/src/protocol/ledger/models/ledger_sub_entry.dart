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
import 'package:serverpod_client/serverpod_client.dart' as _isc;

/// A line inside an entry. Amounts are in kobo (1/100 naira).
abstract class LedgerSubEntry
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  LedgerSubEntry._({
    required this.id,
    required this.name,
    required this.amount,
  });

  factory LedgerSubEntry({
    required String id,
    required String name,
    required int amount,
  }) = _LedgerSubEntryImpl;

  factory LedgerSubEntry.fromJson(Map<String, dynamic> jsonSerialization) {
    return LedgerSubEntry(
      id: jsonSerialization['id'] as String,
      name: jsonSerialization['name'] as String,
      amount: jsonSerialization['amount'] as int,
    );
  }

  String id;

  String name;

  int amount;

  /// Returns a shallow copy of this [LedgerSubEntry]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  LedgerSubEntry copyWith({
    String? id,
    String? name,
    int? amount,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LedgerSubEntry',
      'id': id,
      'name': name,
      'amount': amount,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LedgerSubEntry',
      'id': id,
      'name': name,
      'amount': amount,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _LedgerSubEntryImpl extends LedgerSubEntry {
  _LedgerSubEntryImpl({
    required String id,
    required String name,
    required int amount,
  }) : super._(
         id: id,
         name: name,
         amount: amount,
       );

  /// Returns a shallow copy of this [LedgerSubEntry]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  LedgerSubEntry copyWith({
    String? id,
    String? name,
    int? amount,
  }) {
    return LedgerSubEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
    );
  }
}
