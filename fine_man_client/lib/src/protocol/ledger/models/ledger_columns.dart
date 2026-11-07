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
import '../../ledger/models/ledger_entry.dart' as _i5f80ufj;

/// The five fixed columns every table has.
abstract class LedgerColumns
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  LedgerColumns._({
    required this.need,
    required this.work,
    required this.want,
    required this.luxury,
    required this.tithe,
  });

  factory LedgerColumns({
    required List<_i5f80ufj.LedgerEntry> need,
    required List<_i5f80ufj.LedgerEntry> work,
    required List<_i5f80ufj.LedgerEntry> want,
    required List<_i5f80ufj.LedgerEntry> luxury,
    required List<_i5f80ufj.LedgerEntry> tithe,
  }) = _LedgerColumnsImpl;

  factory LedgerColumns.fromJson(Map<String, dynamic> jsonSerialization) {
    return LedgerColumns(
      need: _ikiosg7s.Protocol().deserialize<List<_i5f80ufj.LedgerEntry>>(
        jsonSerialization['need'],
      ),
      work: _ikiosg7s.Protocol().deserialize<List<_i5f80ufj.LedgerEntry>>(
        jsonSerialization['work'],
      ),
      want: _ikiosg7s.Protocol().deserialize<List<_i5f80ufj.LedgerEntry>>(
        jsonSerialization['want'],
      ),
      luxury: _ikiosg7s.Protocol().deserialize<List<_i5f80ufj.LedgerEntry>>(
        jsonSerialization['luxury'],
      ),
      tithe: _ikiosg7s.Protocol().deserialize<List<_i5f80ufj.LedgerEntry>>(
        jsonSerialization['tithe'],
      ),
    );
  }

  List<_i5f80ufj.LedgerEntry> need;

  List<_i5f80ufj.LedgerEntry> work;

  List<_i5f80ufj.LedgerEntry> want;

  List<_i5f80ufj.LedgerEntry> luxury;

  List<_i5f80ufj.LedgerEntry> tithe;

  /// Returns a shallow copy of this [LedgerColumns]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  LedgerColumns copyWith({
    List<_i5f80ufj.LedgerEntry>? need,
    List<_i5f80ufj.LedgerEntry>? work,
    List<_i5f80ufj.LedgerEntry>? want,
    List<_i5f80ufj.LedgerEntry>? luxury,
    List<_i5f80ufj.LedgerEntry>? tithe,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LedgerColumns',
      'need': need.toJson(valueToJson: (v) => v.toJson()),
      'work': work.toJson(valueToJson: (v) => v.toJson()),
      'want': want.toJson(valueToJson: (v) => v.toJson()),
      'luxury': luxury.toJson(valueToJson: (v) => v.toJson()),
      'tithe': tithe.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LedgerColumns',
      'need': need.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'work': work.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'want': want.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'luxury': luxury.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'tithe': tithe.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _LedgerColumnsImpl extends LedgerColumns {
  _LedgerColumnsImpl({
    required List<_i5f80ufj.LedgerEntry> need,
    required List<_i5f80ufj.LedgerEntry> work,
    required List<_i5f80ufj.LedgerEntry> want,
    required List<_i5f80ufj.LedgerEntry> luxury,
    required List<_i5f80ufj.LedgerEntry> tithe,
  }) : super._(
         need: need,
         work: work,
         want: want,
         luxury: luxury,
         tithe: tithe,
       );

  /// Returns a shallow copy of this [LedgerColumns]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  LedgerColumns copyWith({
    List<_i5f80ufj.LedgerEntry>? need,
    List<_i5f80ufj.LedgerEntry>? work,
    List<_i5f80ufj.LedgerEntry>? want,
    List<_i5f80ufj.LedgerEntry>? luxury,
    List<_i5f80ufj.LedgerEntry>? tithe,
  }) {
    return LedgerColumns(
      need: need ?? this.need.map((e0) => e0.copyWith()).toList(),
      work: work ?? this.work.map((e0) => e0.copyWith()).toList(),
      want: want ?? this.want.map((e0) => e0.copyWith()).toList(),
      luxury: luxury ?? this.luxury.map((e0) => e0.copyWith()).toList(),
      tithe: tithe ?? this.tithe.map((e0) => e0.copyWith()).toList(),
    );
  }
}
