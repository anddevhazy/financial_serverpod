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
import 'package:serverpod/serverpod.dart' as _is;

/// Permission to upload one note image. Upload the file with [description],
/// then pass [path] to `noteImages.confirmUpload`.
abstract class NoteImageUpload
    implements _is.SerializableModel, _is.ProtocolSerialization {
  NoteImageUpload._({
    required this.description,
    required this.path,
  });

  factory NoteImageUpload({
    required String description,
    required String path,
  }) = _NoteImageUploadImpl;

  factory NoteImageUpload.fromJson(Map<String, dynamic> jsonSerialization) {
    return NoteImageUpload(
      description: jsonSerialization['description'] as String,
      path: jsonSerialization['path'] as String,
    );
  }

  String description;

  String path;

  /// Returns a shallow copy of this [NoteImageUpload]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  NoteImageUpload copyWith({
    String? description,
    String? path,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'NoteImageUpload',
      'description': description,
      'path': path,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'NoteImageUpload',
      'description': description,
      'path': path,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _NoteImageUploadImpl extends NoteImageUpload {
  _NoteImageUploadImpl({
    required String description,
    required String path,
  }) : super._(
         description: description,
         path: path,
       );

  /// Returns a shallow copy of this [NoteImageUpload]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  NoteImageUpload copyWith({
    String? description,
    String? path,
  }) {
    return NoteImageUpload(
      description: description ?? this.description,
      path: path ?? this.path,
    );
  }
}
