import 'dart:async';

import 'package:flutter/material.dart';

import '../data/ledger_repository.dart';
import '../data/note_images.dart';
import '../models/ledger.dart';
import '../theme.dart';

/// Free-form notes for one table: text with images placed anywhere in it.
/// Typing saves on its own after a short pause; images can be pasted,
/// dropped or attached at the cursor.
class NotesScreen extends StatefulWidget {
  const NotesScreen({
    super.key,
    required this.repo,
    required this.tableId,
    this.upload = uploadImage,
    this.listen = listenForImages,
  });

  final LedgerRepository repo;
  final String tableId;

  /// Uploads an image; replaceable in tests.
  final Future<ImageBlock> Function(PickedImage image) upload;

  /// Listens for pasted or dropped images; replaceable in tests.
  final void Function() Function(void Function(List<PickedImage>) onImages)
  listen;

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  late final Stream<LedgerTable?> _table = widget.repo.watchTable(
    widget.tableId,
  );

  /// The editor's own copy of the notes. It's filled once from the stored
  /// notes and from then on is the source of truth, so saves never reset
  /// the cursor while typing.
  List<_Block>? _blocks;

  /// The text block that last had focus, and where its cursor was, so
  /// attached images land where the user was writing.
  _TextPart? _lastText;

  Timer? _saveTimer;
  bool _saving = false;
  bool _dirty = false;
  int _uploading = 0;
  String? _error;
  late final void Function() _stopListening;

  @override
  void initState() {
    super.initState();
    _stopListening = widget.listen(_insertImages);
    _load();
  }

  Future<void> _load() async {
    // A stream of its own: _table is already listened to by the header.
    final table = await widget.repo.watchTable(widget.tableId).first;
    if (!mounted || table == null) return;
    setState(() => _blocks = _fromNotes(table.notes));
  }

  @override
  void dispose() {
    _stopListening();
    if (_dirty) _saveNow();
    _saveTimer?.cancel();
    for (final b in _blocks ?? const <_Block>[]) {
      b.dispose();
    }
    super.dispose();
  }

  // ---- Converting between stored notes and editor blocks ----

  List<_Block> _fromNotes(List<NoteBlock> notes) => _normalize([
    for (final n in notes)
      switch (n) {
        TextBlock(:final text) => _newText(text),
        ImageBlock() => _ImagePart(n),
      },
  ]);

  List<NoteBlock> _toNotes() => [
    for (final b in _blocks ?? const <_Block>[])
      if (b is _TextPart && b.controller.text.isNotEmpty)
        TextBlock(b.controller.text)
      else if (b is _ImagePart)
        b.image,
  ];

  _TextPart _newText(String text) {
    final part = _TextPart(text);
    part.controller.addListener(_scheduleSave);
    part.focus.addListener(() {
      if (part.focus.hasFocus) _lastText = part;
    });
    return part;
  }

  /// Keeps a text block before, after and between every image, so there's
  /// always somewhere to type, and merges text blocks that end up next to
  /// each other.
  List<_Block> _normalize(List<_Block> blocks) {
    final out = <_Block>[];
    for (final b in blocks) {
      final last = out.isEmpty ? null : out.last;
      if (b is _TextPart && last is _TextPart) {
        final before = last.controller.text;
        final after = b.controller.text;
        last.controller.text = before.isEmpty || after.isEmpty
            ? before + after
            : '$before\n$after';
        if (_lastText == b) _lastText = last;
        _disposeLater(b);
        continue;
      }
      if (b is! _TextPart && last is! _TextPart) out.add(_newText(''));
      out.add(b);
    }
    if (out.isEmpty || out.last is! _TextPart) out.add(_newText(''));
    return out;
  }

  /// Disposes [block] once the frame that stops showing it is done; its
  /// text field still holds the controller until then.
  void _disposeLater(_Block block) =>
      WidgetsBinding.instance.addPostFrameCallback((_) => block.dispose());

  // ---- Saving ----

  void _scheduleSave() {
    _dirty = true;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 600), _saveNow);
    if (mounted && !_saving) setState(() => _saving = true);
  }

  Future<void> _saveNow() async {
    _saveTimer?.cancel();
    _dirty = false;
    try {
      await widget.repo.saveNotes(widget.tableId, _toNotes());
    } catch (_) {
      // The repository has already told the user. Typing again retries.
      _dirty = true;
    }
    if (mounted && !_dirty) setState(() => _saving = false);
  }

  // ---- Images ----

  Future<void> _attach() async {
    final images = await pickImages();
    _insertImages(images);
  }

  /// Splits the text where the cursor was and puts [images] there, each
  /// shown as "Uploading…" until its upload finishes.
  void _insertImages(List<PickedImage> images) {
    final blocks = _blocks;
    if (images.isEmpty || blocks == null) return;

    final target = _lastText != null && blocks.contains(_lastText)
        ? _lastText!
        : blocks.last as _TextPart;
    final index = blocks.indexOf(target);
    final text = target.controller.text;
    final offset = target.cursor.clamp(0, text.length);
    final placeholders = [for (final i in images) _UploadingPart(i.name)];

    setState(() {
      _error = null;
      _uploading += images.length;
      target.controller.text = text.substring(0, offset);
      _blocks = _normalize([
        ...blocks.sublist(0, index + 1),
        ...placeholders,
        _newText(text.substring(offset)),
        ...blocks.sublist(index + 1),
      ]);
    });

    for (var i = 0; i < images.length; i++) {
      _upload(images[i], placeholders[i]);
    }
  }

  Future<void> _upload(PickedImage image, _UploadingPart placeholder) async {
    try {
      final uploaded = await widget.upload(image);
      if (!mounted) return;
      _replace(placeholder, _ImagePart(uploaded));
    } catch (e) {
      if (!mounted) return;
      _replace(placeholder, null);
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _uploading--);
    }
  }

  void _replace(_Block old, _Block? replacement) {
    final blocks = _blocks!;
    final index = blocks.indexOf(old);
    if (index == -1) return;
    setState(() {
      _blocks = _normalize([
        ...blocks.sublist(0, index),
        ?replacement,
        ...blocks.sublist(index + 1),
      ]);
    });
    _scheduleSave();
  }

  void _removeImage(_ImagePart part) {
    final before = _toNotes();
    _replace(part, null);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Image removed'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              if (!mounted) return;
              final old = _blocks!;
              setState(() => _blocks = _fromNotes(before));
              old.forEach(_disposeLater);
              _scheduleSave();
            },
          ),
        ),
      );
  }

  /// Clicking below the notes puts the cursor at the end.
  void _focusEnd() {
    final last = _blocks?.last;
    if (last is! _TextPart) return;
    last.focus.requestFocus();
    last.controller.selection = TextSelection.collapsed(
      offset: last.controller.text.length,
    );
  }

  // ---- UI ----

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<LedgerTable?>(
          stream: _table,
          builder: (context, snap) {
            final table = snap.data;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                narrow ? 8 : 16,
                8,
                narrow ? 8 : 16,
                48,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _header(table),
                      const SizedBox(height: 12),
                      _editor(),
                      const SizedBox(height: 10),
                      _imageBar(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _header(LedgerTable? table) {
    final status = _uploading > 0
        ? 'Uploading $_uploading image${_uploading == 1 ? '' : 's'}…'
        : _saving
        ? 'Saving…'
        : 'Saved';
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: table == null ? 'Back' : 'Back to ${table.name}',
          icon: const Icon(Icons.arrow_back, size: 20, color: Palette.muted),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Notes', style: Fonts.display(20)),
              if (table != null)
                Text(
                  table.name,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Palette.muted),
                ),
            ],
          ),
        ),
        Text(
          status,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Palette.muted),
        ),
      ],
    );
  }

  Widget _editor() {
    final blocks = _blocks;
    final textStyle = Theme.of(
      context,
    ).textTheme.bodyLarge?.copyWith(fontSize: 15, height: 1.6);
    final empty =
        blocks != null &&
        blocks.length == 1 &&
        (blocks.single as _TextPart).controller.text.isEmpty;

    return Container(
      constraints: const BoxConstraints(minHeight: 420),
      decoration: BoxDecoration(
        color: Palette.sheet,
        border: Border.all(color: Palette.grid),
      ),
      child: blocks == null
          ? const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final b in blocks)
                        switch (b) {
                          _TextPart() => TextField(
                            key: ObjectKey(b),
                            controller: b.controller,
                            focusNode: b.focus,
                            autofocus: empty,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            style: textStyle,
                            decoration: _borderless(
                              hintText: empty
                                  ? 'Write anything about this table… paste or drop images in anywhere.'
                                  : null,
                              hintStyle: textStyle?.copyWith(
                                color: Palette.grid,
                              ),
                            ),
                          ),
                          _ImagePart() => _NoteImage(
                            key: ObjectKey(b),
                            image: b.image,
                            onRemove: () => _removeImage(b),
                          ),
                          _UploadingPart() => _UploadingImage(
                            key: ObjectKey(b),
                            name: b.name,
                          ),
                        },
                    ],
                  ),
                ),
                // The empty space under the notes; clicking it continues
                // writing at the end.
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _focusEnd,
                  child: const MouseRegion(
                    cursor: SystemMouseCursors.text,
                    child: SizedBox(height: 120),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _imageBar() {
    final small = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: Palette.muted);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 4,
      children: [
        OutlinedButton.icon(
          onPressed: _blocks == null ? null : _attach,
          icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
          label: const Text('Attach image'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Palette.ink,
            side: const BorderSide(color: Palette.grid),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        Text('or paste / drop images anywhere on the page', style: small),
        if (_error != null)
          Text(_error!, style: small?.copyWith(color: Palette.redRule)),
      ],
    );
  }
}

// ---- Editor blocks ----

sealed class _Block {
  void dispose() {}
}

class _TextPart extends _Block {
  _TextPart(String text) : controller = TextEditingController(text: text);

  final TextEditingController controller;
  final FocusNode focus = FocusNode();

  /// Where the cursor is, or the end of the text when it has none.
  int get cursor {
    final s = controller.selection;
    return s.isValid ? s.baseOffset : controller.text.length;
  }

  @override
  void dispose() {
    controller.dispose();
    focus.dispose();
  }
}

class _ImagePart extends _Block {
  _ImagePart(this.image);
  final ImageBlock image;
}

class _UploadingPart extends _Block {
  _UploadingPart(this.name);
  final String name;
}

/// An image in the notes, with a button to remove it.
class _NoteImage extends StatefulWidget {
  const _NoteImage({super.key, required this.image, required this.onRemove});

  final ImageBlock image;
  final VoidCallback onRemove;

  @override
  State<_NoteImage> createState() => _NoteImageState();
}

class _NoteImageState extends State<_NoteImage> {
  bool _hovered = false;

  /// Images uploaded by the Firebase version of the app are still on
  /// Cloudinary, so this asks it for a size that suits the page instead of
  /// the original upload. Other links don't contain this path.
  String get _displayUrl => widget.image.url.replaceFirst(
    '/image/upload/',
    '/image/upload/c_limit,w_1600,q_auto,f_auto/',
  );

  @override
  Widget build(BuildContext context) {
    final w = widget.image.width;
    final h = widget.image.height;
    final touch = switch (Theme.of(context).platform) {
      TargetPlatform.android || TargetPlatform.iOS => true,
      _ => false,
    };

    Widget picture = Image.network(
      _displayUrl,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const ColoredBox(
              color: Palette.headerFill,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
      errorBuilder: (context, error, stack) => Container(
        height: 120,
        color: Palette.headerFill,
        alignment: Alignment.center,
        child: const Text('This image couldn’t be loaded.'),
      ),
    );
    // Reserves the image's space before it loads, so text doesn't jump.
    if (w != null && h != null && w > 0 && h > 0) {
      picture = AspectRatio(aspectRatio: w / h, child: picture);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 520),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: picture,
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: AnimatedOpacity(
                    opacity: touch || _hovered ? 1 : 0,
                    duration: const Duration(milliseconds: 120),
                    child: IconButton.filled(
                      onPressed: widget.onRemove,
                      tooltip: 'Remove image',
                      iconSize: 18,
                      style: IconButton.styleFrom(
                        backgroundColor: Palette.ink.withValues(alpha: 0.75),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UploadingImage extends StatelessWidget {
  const _UploadingImage({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 96,
      decoration: BoxDecoration(
        color: Palette.headerFill,
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'Uploading $name…',
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Palette.muted),
            ),
          ),
        ],
      ),
    );
  }
}

/// A text field decoration with no box at all. The app theme gives text
/// fields an outlined, filled box, which the collapsed decoration alone
/// doesn't switch off.
InputDecoration _borderless({String? hintText, TextStyle? hintStyle}) =>
    InputDecoration(
      isCollapsed: true,
      filled: false,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      contentPadding: EdgeInsets.zero,
      hintText: hintText,
      hintStyle: hintStyle,
    );
