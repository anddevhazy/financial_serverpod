import 'package:fine_man_flutter/data/ledger_repository.dart';
import 'package:fine_man_flutter/screens/tables_screen.dart';
import 'package:fine_man_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  for (final width in [1110.0, 1440.0, 520.0]) {
    testWidgets('create a table at $width', (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = LocalLedgerRepository.inMemory();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(),
          home: TablesScreen(repo: repo),
        ),
      );
      await tester.pump();
      await tester.tap(
        find.text(width < 600 ? 'New table' : 'Create your first table').first,
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'October');
      await tester.tap(find.text('Create table'));
      await tester.pumpAndSettle();
      expect(find.text('October'), findsWidgets);
      expect(find.text('Add entry'), findsWidgets);

      // Clicking the add row turns it into a cell to type the name into.
      await tester.tap(find.text('Add entry').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Food');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('Food'), findsOneWidget);
      // Enter leaves the add row open for the next entry; Esc closes it.
      expect(find.byType(TextField), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);

      await tester.tap(find.byTooltip('Add sub-entry to Food'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'Rice');
      await tester.enterText(find.byType(TextField).at(1), '12,500');
      await tester.tap(find.widgetWithText(FilledButton, 'Add sub-entry'));
      await tester.pumpAndSettle();
      expect(find.text('Rice'), findsOneWidget);
      expect(find.text('₦12,500'), findsWidgets);
    });
  }
}
