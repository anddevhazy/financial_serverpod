import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';

import '../generated/protocol.dart';

const _storageId = 'public';
const _maxImageBytes = 10 * 1024 * 1024;

/// The image types notes accept, with the file extension to store each under.
/// SVG is left out on purpose: it can carry scripts, and images are served from
/// the same address as the API.
const _extensions = {
  'image/png': 'png',
  'image/jpeg': 'jpg',
  'image/gif': 'gif',
  'image/webp': 'webp',
  'image/bmp': 'bmp',
};

/// Uploads for images in notes. The app asks for permission to upload, sends
/// the file straight to cloud storage, then has the server check what arrived.
///
/// Stored images are public to anyone with their link, which has a random part
/// so links can't be guessed.
class NoteImagesEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  Future<NoteImageUpload> createUpload(
    Session session,
    String contentType,
    int contentLength,
  ) async {
    final extension = _extensions[contentType];
    if (extension == null) {
      throw LedgerException(
        message: 'Use a PNG, JPEG, GIF, WebP or BMP image.',
      );
    }
    if (contentLength <= 0 || contentLength > _maxImageBytes) {
      throw LedgerException(message: 'Images can be at most 10 MB.');
    }

    final path = '${_folder(session)}${const Uuid().v4()}.$extension';
    final description = await session.storage.createUploadDescription(
      storageId: _storageId,
      path: path,
      options: UploadOptions(
        maxFileSize: _maxImageBytes,
        contentLength: contentLength,
        preventOverwrite: true,
        metadata: FileMetadata(
          contentType: contentType,
          cacheControl: 'public, max-age=31536000, immutable',
        ),
      ),
    );
    return NoteImageUpload(description: description, path: path);
  }

  /// Checks the file uploaded to [path] really is an image, and returns the
  /// note block that shows it.
  Future<LedgerNote> confirmUpload(Session session, String path) async {
    if (!path.startsWith(_folder(session))) {
      throw LedgerException(message: 'That upload isn’t yours.');
    }
    final verified = await session.storage.verifyUpload(
      storageId: _storageId,
      path: path,
    );
    if (!verified) {
      throw LedgerException(message: 'The image didn’t finish uploading.');
    }

    final file = await session.storage.retrieveFile(
      storageId: _storageId,
      path: path,
    );
    final size = _imageSize(Uint8List.sublistView(file));
    if (size == null) {
      await session.storage.deleteFile(storageId: _storageId, path: path);
      throw LedgerException(message: 'That file isn’t an image.');
    }

    final url = await session.storage.publicDownloadUrl(
      storageId: _storageId,
      path: path,
    );
    return LedgerNote(
      type: 'image',
      url: url.toString(),
      publicId: path,
      width: size.width,
      height: size.height,
    );
  }

  String _folder(Session session) =>
      'notes/${session.authenticated!.authUserId.uuid}/';

  /// Reads only the image's header, not all of its pixels.
  ({int width, int height})? _imageSize(Uint8List bytes) {
    final info = img.findDecoderForData(bytes)?.startDecode(bytes);
    if (info == null || info.width <= 0 || info.height <= 0) return null;
    return (width: info.width, height: info.height);
  }
}
