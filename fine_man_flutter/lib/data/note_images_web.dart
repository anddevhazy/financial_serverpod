import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'package:fine_man_client/fine_man_client.dart';

import '../client.dart';
import '../models/ledger.dart';
import 'ledger_mapping.dart';

/// An image file chosen, pasted or dropped by the user.
class PickedImage {
  const PickedImage._(this._file);

  final web.File _file;

  String get name => _file.name;
}

List<PickedImage> _images(web.FileList? files) => [
  for (var i = 0; i < (files?.length ?? 0); i++)
    if (files!.item(i)!.type.startsWith('image/'))
      PickedImage._(files.item(i)!),
];

/// Opens the browser's file picker for images. Returns an empty list when
/// nothing is chosen.
Future<List<PickedImage>> pickImages() {
  final completer = Completer<List<PickedImage>>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = 'image/*'
    ..multiple = true;
  input.addEventListener(
    'change',
    (web.Event _) {
      completer.complete(_images(input.files));
    }.toJS,
  );
  input.addEventListener(
    'cancel',
    (web.Event _) {
      if (!completer.isCompleted) completer.complete(const []);
    }.toJS,
  );
  input.click();
  return completer.future;
}

/// Uploads [image] to the server's cloud storage and returns it as a note
/// block. The server decides where it goes and checks it's really an image.
Future<ImageBlock> uploadImage(PickedImage image) async {
  try {
    final buffer = await image._file.arrayBuffer().toDart;
    final bytes = ByteData.view(buffer.toDart);
    final upload = await client.noteImages.createUpload(
      image._file.type,
      bytes.lengthInBytes,
    );
    final sent = await FileUploader(upload.description).uploadByteData(bytes);
    if (!sent) throw Exception('Image upload failed. Try again.');
    final note = await client.noteImages.confirmUpload(upload.path);
    return noteFromData(note)! as ImageBlock;
  } on LedgerException catch (e) {
    throw Exception('Image upload failed: ${e.message}');
  } on ServerpodClientNetworkException {
    throw Exception('Couldn’t reach the server. Check your connection.');
  }
}

/// Calls [onImages] whenever images are pasted or dropped onto the page.
/// Pasted or dropped text is left alone. Returns a function that stops
/// listening.
void Function() listenForImages(void Function(List<PickedImage>) onImages) {
  final onPaste = (web.Event event) {
    final images = _images((event as web.ClipboardEvent).clipboardData?.files);
    if (images.isEmpty) return;
    event.preventDefault();
    onImages(images);
  }.toJS;

  final onDragOver = (web.Event event) {
    final types = (event as web.DragEvent).dataTransfer?.types.toDart ?? [];
    // Allows dropping files instead of the browser opening them.
    if (types.any((t) => t.toDart == 'Files')) event.preventDefault();
  }.toJS;

  final onDrop = (web.Event event) {
    final images = _images((event as web.DragEvent).dataTransfer?.files);
    if (images.isEmpty) return;
    event.preventDefault();
    onImages(images);
  }.toJS;

  // Capture phase, so this sees the paste before Flutter's text input.
  final capture = web.AddEventListenerOptions(capture: true);
  web.document.addEventListener('paste', onPaste, capture);
  web.window.addEventListener('dragover', onDragOver);
  web.window.addEventListener('drop', onDrop);

  return () {
    web.document.removeEventListener(
      'paste',
      onPaste,
      web.EventListenerOptions(capture: true),
    );
    web.window.removeEventListener('dragover', onDragOver);
    web.window.removeEventListener('drop', onDrop);
  };
}
