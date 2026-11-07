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

/// One piece of a table's notes: a run of text or an uploaded image.
abstract class LedgerNote
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  LedgerNote._({
    required this.type,
    this.text,
    this.url,
    this.publicId,
    this.width,
    this.height,
  });

  factory LedgerNote({
    required String type,
    String? text,
    String? url,
    String? publicId,
    int? width,
    int? height,
  }) = _LedgerNoteImpl;

  factory LedgerNote.fromJson(Map<String, dynamic> jsonSerialization) {
    return LedgerNote(
      type: jsonSerialization['type'] as String,
      text: jsonSerialization['text'] as String?,
      url: jsonSerialization['url'] as String?,
      publicId: jsonSerialization['publicId'] as String?,
      width: jsonSerialization['width'] as int?,
      height: jsonSerialization['height'] as int?,
    );
  }

  /// "text" or "image".
  String type;

  String? text;

  String? url;

  /// Where the image is stored, needed to delete it later.
  String? publicId;

  int? width;

  int? height;

  /// Returns a shallow copy of this [LedgerNote]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  LedgerNote copyWith({
    String? type,
    String? text,
    String? url,
    String? publicId,
    int? width,
    int? height,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LedgerNote',
      'type': type,
      if (text != null) 'text': text,
      if (url != null) 'url': url,
      if (publicId != null) 'publicId': publicId,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LedgerNote',
      'type': type,
      if (text != null) 'text': text,
      if (url != null) 'url': url,
      if (publicId != null) 'publicId': publicId,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LedgerNoteImpl extends LedgerNote {
  _LedgerNoteImpl({
    required String type,
    String? text,
    String? url,
    String? publicId,
    int? width,
    int? height,
  }) : super._(
         type: type,
         text: text,
         url: url,
         publicId: publicId,
         width: width,
         height: height,
       );

  /// Returns a shallow copy of this [LedgerNote]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  LedgerNote copyWith({
    String? type,
    Object? text = _Undefined,
    Object? url = _Undefined,
    Object? publicId = _Undefined,
    Object? width = _Undefined,
    Object? height = _Undefined,
  }) {
    return LedgerNote(
      type: type ?? this.type,
      text: text is String? ? text : this.text,
      url: url is String? ? url : this.url,
      publicId: publicId is String? ? publicId : this.publicId,
      width: width is int? ? width : this.width,
      height: height is int? ? height : this.height,
    );
  }
}
