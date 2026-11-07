import '../models/ledger.dart';

/// An image file chosen, pasted or dropped by the user.
class PickedImage {
  const PickedImage(this.name);
  final String name;
}

Future<List<PickedImage>> pickImages() =>
    throw UnsupportedError('Note images are only supported on web.');

Future<ImageBlock> uploadImage(PickedImage image) =>
    throw UnsupportedError('Note images are only supported on web.');

/// Calls [onImages] whenever images are pasted or dropped onto the page.
/// Returns a function that stops listening.
void Function() listenForImages(void Function(List<PickedImage>) onImages) =>
    () {};
