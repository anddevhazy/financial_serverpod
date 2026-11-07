import 'package:fine_man_flutter/data/ledger_repository.dart';
import 'package:fine_man_flutter/models/ledger.dart';
import 'package:fine_man_flutter/screens/table_screen.dart';
import 'package:fine_man_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  late LocalLedgerRepository repo;
  late String tableId;

  Future<void> pumpTable(WidgetTester tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    repo = LocalLedgerRepository.inMemory();
    final t = await repo.createTable('October');
    tableId = t.id;
    await repo.saveColumns(
      t
          .addEntry(
            LedgerColumn.need,
            const Entry(id: 'a', name: 'Rent', amount: 10000),
          )
          .addEntry(LedgerColumn.need, const Entry(id: 'b', name: 'Food'))
          .addSub(
            LedgerColumn.need,
            'b',
            const SubEntry(id: 's', name: 'Rice', amount: 2000),
          ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: TableScreen(repo: repo, tableId: tableId),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> showSubEntries(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Show sub-entries'));
    await tester.pumpAndSettle();
  }

  Future<List<Entry>> need() async => (await repo.allTables())
      .singleWhere((t) => t.id == tableId)
      .entriesIn(LedgerColumn.need);

  final mouse = TargetPlatformVariant.only(TargetPlatform.macOS);

  testWidgets('clicking a name edits it in place; Enter saves', (tester) async {
    await pumpTable(tester);
    await tester.tap(find.text('Rent'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);

    await tester.enterText(find.byType(TextField), 'House rent');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    expect(find.text('House rent'), findsOneWidget);
    expect((await need()).first.name, 'House rent');
  }, variant: mouse);

  testWidgets('clicking an amount edits it; clicking away saves', (
    tester,
  ) async {
    await pumpTable(tester);
    await tester.tap(find.text('₦100'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '2,500.50');
    await tester.pump();

    await tester.tap(find.text('NEED'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    expect((await need()).first.amount, 250050);
    expect(find.text('₦2,500.50'), findsOneWidget);
  }, variant: mouse);

  testWidgets('a sub-entry amount edits in place and updates the total', (
    tester,
  ) async {
    await pumpTable(tester);
    await showSubEntries(tester);
    await tester.tap(find.text('₦20').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '35');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final food = (await need()).last;
    expect(food.subs.single.amount, 3500);
    expect(food.total, 3500);
  }, variant: mouse);

  testWidgets('Esc cancels without saving', (tester) async {
    await pumpTable(tester);
    await showSubEntries(tester);
    await tester.tap(find.text('Rice'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Beans');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    expect(find.text('Rice'), findsOneWidget);
    expect((await need()).last.subs.single.name, 'Rice');
  }, variant: mouse);

  testWidgets('an empty name or bad amount is not saved', (tester) async {
    await pumpTable(tester);
    await tester.tap(find.text('₦100'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '12..5');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    // Still editing, so the mistake can be fixed.
    expect(find.byType(TextField), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rent'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text('NEED'));
    await tester.pumpAndSettle();

    final rent = (await need()).first;
    expect(rent.name, 'Rent');
    expect(rent.amount, 10000);
  }, variant: mouse);

  testWidgets('the total of an entry with sub-entries is not typed in', (
    tester,
  ) async {
    await pumpTable(tester);
    // Food's total (₦20) appears on its own row and on Rice's row.
    await tester.tap(find.text('₦20').first);
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
  }, variant: mouse);
}
