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

/// A request the server refused. [message] can be shown to the user.
abstract class LedgerException
    implements
        _isc.SerializableException,
        _isc.SerializableModel,
        _isc.ProtocolSerialization {
  LedgerException._({required this.message});

  factory LedgerException({required String message}) = _LedgerExceptionImpl;

  factory LedgerException.fromJson(Map<String, dynamic> jsonSerialization) {
    return LedgerException(message: jsonSerialization['message'] as String);
  }

  String message;

  /// Returns a shallow copy of this [LedgerException]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  LedgerException copyWith({String? message});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LedgerException',
      'message': message,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LedgerException',
      'message': message,
    };
  }

  @override
  String toString() {
    return 'LedgerException(message: $message)';
  }
}

class _LedgerExceptionImpl extends LedgerException {
  _LedgerExceptionImpl({required String message}) : super._(message: message);

  /// Returns a shallow copy of this [LedgerException]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  LedgerException copyWith({String? message}) {
    return LedgerException(message: message ?? this.message);
  }
}
