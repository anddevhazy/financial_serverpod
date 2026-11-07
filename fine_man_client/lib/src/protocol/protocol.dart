/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: dead_code, unnecessary_type_check

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:fine_man_client/src/protocol/ledger/models/ledger_note.dart'
    as _iscdy98t;
import 'package:fine_man_client/src/protocol/ledger/models/ledger_table_data.dart'
    as _iv0b9j4t;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _iacc;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _iaic;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'ledger/models/ledger_columns.dart' as _i18f1xrg;
import 'ledger/models/ledger_entry.dart' as _iim39nfj;
import 'ledger/models/ledger_event.dart' as _i9hotj01;
import 'ledger/models/ledger_exception.dart' as _i3zugcda;
import 'ledger/models/ledger_note.dart' as _i3ezx3pk;
import 'ledger/models/ledger_sub_entry.dart' as _iyave5fl;
import 'ledger/models/ledger_table_data.dart' as _iwist8hr;
import 'notes/note_image_upload.dart' as _i4yfyzdj;
export 'ledger/models/ledger_columns.dart';
export 'ledger/models/ledger_entry.dart';
export 'ledger/models/ledger_event.dart';
export 'ledger/models/ledger_exception.dart';
export 'ledger/models/ledger_note.dart';
export 'ledger/models/ledger_sub_entry.dart';
export 'ledger/models/ledger_table_data.dart';
export 'notes/note_image_upload.dart';
export 'client.dart';

class Protocol extends _isc.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._().._registerHostProtocols();

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on _isc.DeserializationClassNameNotFoundException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i18f1xrg.LedgerColumns) {
      return _i18f1xrg.LedgerColumns.fromJson(data) as T;
    }
    if (t == _iim39nfj.LedgerEntry) {
      return _iim39nfj.LedgerEntry.fromJson(data) as T;
    }
    if (t == _i9hotj01.LedgerEvent) {
      return _i9hotj01.LedgerEvent.fromJson(data) as T;
    }
    if (t == _i3zugcda.LedgerException) {
      return _i3zugcda.LedgerException.fromJson(data) as T;
    }
    if (t == _i3ezx3pk.LedgerNote) {
      return _i3ezx3pk.LedgerNote.fromJson(data) as T;
    }
    if (t == _iyave5fl.LedgerSubEntry) {
      return _iyave5fl.LedgerSubEntry.fromJson(data) as T;
    }
    if (t == _iwist8hr.LedgerTableData) {
      return _iwist8hr.LedgerTableData.fromJson(data) as T;
    }
    if (t == _i4yfyzdj.NoteImageUpload) {
      return _i4yfyzdj.NoteImageUpload.fromJson(data) as T;
    }
    if (t == _isc.getType<_i18f1xrg.LedgerColumns?>()) {
      return (data != null ? _i18f1xrg.LedgerColumns.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iim39nfj.LedgerEntry?>()) {
      return (data != null ? _iim39nfj.LedgerEntry.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i9hotj01.LedgerEvent?>()) {
      return (data != null ? _i9hotj01.LedgerEvent.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i3zugcda.LedgerException?>()) {
      return (data != null ? _i3zugcda.LedgerException.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i3ezx3pk.LedgerNote?>()) {
      return (data != null ? _i3ezx3pk.LedgerNote.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iyave5fl.LedgerSubEntry?>()) {
      return (data != null ? _iyave5fl.LedgerSubEntry.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iwist8hr.LedgerTableData?>()) {
      return (data != null ? _iwist8hr.LedgerTableData.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i4yfyzdj.NoteImageUpload?>()) {
      return (data != null ? _i4yfyzdj.NoteImageUpload.fromJson(data) : null)
          as T;
    }
    if (t == List<_iim39nfj.LedgerEntry>) {
      return (data as List)
              .map((e) => deserialize<_iim39nfj.LedgerEntry>(e))
              .toList()
          as T;
    }
    if (t == List<_iyave5fl.LedgerSubEntry>) {
      return (data as List)
              .map((e) => deserialize<_iyave5fl.LedgerSubEntry>(e))
              .toList()
          as T;
    }
    if (t == List<_iwist8hr.LedgerTableData>) {
      return (data as List)
              .map((e) => deserialize<_iwist8hr.LedgerTableData>(e))
              .toList()
          as T;
    }
    if (t == _isc.getType<List<_iwist8hr.LedgerTableData>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_iwist8hr.LedgerTableData>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i3ezx3pk.LedgerNote>) {
      return (data as List)
              .map((e) => deserialize<_i3ezx3pk.LedgerNote>(e))
              .toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_iv0b9j4t.LedgerTableData>) {
      return (data as List)
              .map((e) => deserialize<_iv0b9j4t.LedgerTableData>(e))
              .toList()
          as T;
    }
    if (t == List<_iscdy98t.LedgerNote>) {
      return (data as List)
              .map((e) => deserialize<_iscdy98t.LedgerNote>(e))
              .toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    try {
      return _iaic.Protocol().deserialize<T>(data, t);
    } on _isc.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _iacc.Protocol().deserialize<T>(data, t);
    } on _isc.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i18f1xrg.LedgerColumns => 'LedgerColumns',
      _iim39nfj.LedgerEntry => 'LedgerEntry',
      _i9hotj01.LedgerEvent => 'LedgerEvent',
      _i3zugcda.LedgerException => 'LedgerException',
      _i3ezx3pk.LedgerNote => 'LedgerNote',
      _iyave5fl.LedgerSubEntry => 'LedgerSubEntry',
      _iwist8hr.LedgerTableData => 'LedgerTableData',
      _i4yfyzdj.NoteImageUpload => 'NoteImageUpload',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('fine_man.', '');
    }

    switch (data) {
      case _i18f1xrg.LedgerColumns():
        return 'LedgerColumns';
      case _iim39nfj.LedgerEntry():
        return 'LedgerEntry';
      case _i9hotj01.LedgerEvent():
        return 'LedgerEvent';
      case _i3zugcda.LedgerException():
        return 'LedgerException';
      case _i3ezx3pk.LedgerNote():
        return 'LedgerNote';
      case _iyave5fl.LedgerSubEntry():
        return 'LedgerSubEntry';
      case _iwist8hr.LedgerTableData():
        return 'LedgerTableData';
      case _i4yfyzdj.NoteImageUpload():
        return 'NoteImageUpload';
    }
    className = _iaic.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_idp.$className';
    }
    className = _iacc.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_core.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'LedgerColumns') {
      return deserialize<_i18f1xrg.LedgerColumns>(data['data']);
    }
    if (dataClassName == 'LedgerEntry') {
      return deserialize<_iim39nfj.LedgerEntry>(data['data']);
    }
    if (dataClassName == 'LedgerEvent') {
      return deserialize<_i9hotj01.LedgerEvent>(data['data']);
    }
    if (dataClassName == 'LedgerException') {
      return deserialize<_i3zugcda.LedgerException>(data['data']);
    }
    if (dataClassName == 'LedgerNote') {
      return deserialize<_i3ezx3pk.LedgerNote>(data['data']);
    }
    if (dataClassName == 'LedgerSubEntry') {
      return deserialize<_iyave5fl.LedgerSubEntry>(data['data']);
    }
    if (dataClassName == 'LedgerTableData') {
      return deserialize<_iwist8hr.LedgerTableData>(data['data']);
    }
    if (dataClassName == 'NoteImageUpload') {
      return deserialize<_i4yfyzdj.NoteImageUpload>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _iaic.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _iacc.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  void _registerHostProtocols() {
    _iaic.Protocol().registerHostProtocol('fine_man', this);
    _iacc.Protocol().registerHostProtocol('fine_man', this);
  }

  @override
  String getModuleName() => 'fine_man';

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    try {
      return _iaic.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _iacc.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
