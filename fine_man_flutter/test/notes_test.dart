import 'dart:async';

import 'package:fine_man_flutter/data/backup.dart';
import 'package:fine_man_flutter/data/ledger_repository.dart';
import 'package:fine_man_flutter/data/note_images.dart';
import 'package:fine_man_flutter/models/ledger.dart';
import 'package:fine_man_flutter/screens/notes_screen.dart';
import 'package:fine_man_flutter/screens/table_screen.dart';
import 'package:fine_man_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

const _photo = ImageBlock(
  url: 'https://res.cloudinary.com/demo/image/upload/v1/fine_man/notes/a.png',
  publicId: 'fine_man/notes/a',
  width: 400,
  height: 200,
);

void main() {
  late LocalLedgerRepository repo;
  late String tableId;

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    repo = LocalLedgerRepository.inMemory();
    tableId = (await repo.createTable('October')).id;
  });

  Future<LedgerTable> saved() async =>
      (await repo.allTables()).singleWhere((t) => t.id == tableId);

  test('notes survive backups', () async {
    await repo.saveNotes(tableId, const [
      TextBlock('Rent goes up in January.'),
      _photo,
      TextBlock('Receipt above.'),
    ]);
    final restored = decodeBackup(encodeBackup(await repo.allTables())).single;
    expect(restored.notes, hasLength(3));
    expect((restored.notes[0] as TextBlock).text, 'Rent goes up in January.');
    expect((restored.notes[1] as ImageBlock).publicId, 'fine_man/notes/a');
    expect((restored.notes[1] as ImageBlock).width, 400);
    expect(restored.hasNotes, isTrue);
  });

  test('tables from older backups have empty notes', () {
    final table = LedgerTable.fromJson({
      'id': 't',
      'name': 'Old',
      'createdAt': 0,
      'columns': <String, dynamic>{},
    });
    expect(table.notes, isEmpty);
    expect(table.hasNotes, isFalse);
  });

  testWidgets('the table page links to notes and has no grand total', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: TableScreen(repo: repo, tableId: tableId),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('TOTAL'), findsNothing);
    expect(find.text('Add notes'), findsOneWidget);

    await tester.tap(find.text('Add notes'));
    await tester.pumpAndSettle();
    expect(find.byType(NotesScreen), findsOneWidget);
  });

  group('editor', () {
    late void Function(List<PickedImage>) paste;
    late Completer<ImageBlock> upload;

    Future<void> pumpNotes(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      upload = Completer();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(),
          home: NotesScreen(
            repo: repo,
            tableId: tableId,
            upload: (_) => upload.future,
            listen: (onImages) {
              paste = onImages;
              return () {};
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('typing saves after a short pause', (tester) async {
      await pumpNotes(tester);
      await tester.enterText(find.byType(TextField), 'Remember the tithe.');
      await tester.pump();
      expect(find.text('Saving…'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
      expect(find.text('Saved'), findsOneWidget);
      final notes = (await saved()).notes;
      expect((notes.single as TextBlock).text, 'Remember the tithe.');
    });

    testWidgets('a pasted image goes in at the cursor', (tester) async {
      await pumpNotes(tester);
      final field = find.byType(TextField);
      await tester.enterText(field, 'BeforeAfter');
      final controller = tester.widget<TextField>(field).controller!;
      controller.selection = const TextSelection.collapsed(offset: 6);
      await tester.pump();

      paste([const PickedImage('receipt.png')]);
      await tester.pump();
      expect(find.text('Uploading receipt.png…'), findsOneWidget);

      upload.complete(_photo);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      final notes = (await saved()).notes;
      expect(notes, hasLength(3));
      expect((notes[0] as TextBlock).text, 'Before');
      expect((notes[1] as ImageBlock).url, _photo.url);
      expect((notes[2] as TextBlock).text, 'After');
    });

    testWidgets('a failed upload removes its placeholder and says why', (
      tester,
    ) async {
      await pumpNotes(tester);
      await tester.enterText(find.byType(TextField), 'Notes');
      paste([const PickedImage('big.png')]);
      await tester.pump();

      upload.completeError(Exception('Image upload failed: File too large'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('Uploading big.png…'), findsNothing);
      expect(find.text('Image upload failed: File too large'), findsOneWidget);
      final notes = (await saved()).notes;
      expect((notes.single as TextBlock).text, 'Notes');
    });

    testWidgets('removing an image joins the text around it; Undo restores', (
      tester,
    ) async {
      await repo.saveNotes(tableId, const [
        TextBlock('Top'),
        _photo,
        TextBlock('Bottom'),
      ]);
      await pumpNotes(tester);

      await tester.tap(find.byTooltip('Remove image'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      var notes = (await saved()).notes;
      expect((notes.single as TextBlock).text, 'Top\nBottom');

      await tester.tap(find.text('Undo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      notes = (await saved()).notes;
      expect(notes, hasLength(3));
      expect(notes[1], isA<ImageBlock>());
      await tester.pumpAndSettle();
    });
  });
}
