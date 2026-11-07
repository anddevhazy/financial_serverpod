import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Saves [text] as a file through the browser's download.
Future<void> downloadTextFile(String fileName, String text) async {
  final blob = web.Blob(
    [text.toJS].toJS,
    web.BlobPropertyBag(type: 'application/json'),
  );
  final url = web.URL.createObjectURL(blob);
  final link = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  web.document.body!.append(link);
  link.click();
  link.remove();
  web.URL.revokeObjectURL(url);
}

/// Opens the browser's file picker. Returns the file's text,
/// or null if no file was chosen.
Future<String?> pickTextFile() {
  final completer = Completer<String?>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = '.json,application/json';

  input.addEventListener(
    'change',
    (web.Event _) {
      final file = input.files?.item(0);
      if (file == null) {
        completer.complete(null);
        return;
      }
      file.text().toDart.then(
        (text) => completer.complete(text.toDart),
        onError: completer.completeError,
      );
    }.toJS,
  );
  input.addEventListener(
    'cancel',
    (web.Event _) {
      if (!completer.isCompleted) completer.complete(null);
    }.toJS,
  );
  input.click();
  return completer.future;
}
