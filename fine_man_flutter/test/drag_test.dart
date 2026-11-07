import 'package:fine_man_flutter/data/ledger_repository.dart';
import 'package:fine_man_flutter/models/ledger.dart';
import 'package:fine_man_flutter/screens/table_screen.dart';
import 'package:fine_man_flutter/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

List<String> names(List<Entry> entries) => [for (final e in entries) e.name];

void main() {
  group('model', () {
    final base =
        LedgerTable(
              id: 't',
              name: 'October',
              createdAt: DateTime(2026, 10, 19),
              columns: LedgerTable.columnsFromMap(null),
            )
            .addEntry(LedgerColumn.need, const Entry(id: 'a', name: 'A'))
            .addEntry(LedgerColumn.need, const Entry(id: 'b', name: 'B'))
            .addEntry(LedgerColumn.need, const Entry(id: 'c', name: 'C'))
            .addSub(
              LedgerColumn.need,
              'a',
              const SubEntry(id: 's1', name: 'S1', amount: 1),
            )
            .addSub(
              LedgerColumn.need,
              'a',
              const SubEntry(id: 's2', name: 'S2', amount: 2),
            );

    test('reorders entries down and up', () {
      expect(
        names(
          base
              .reorderEntry(LedgerColumn.need, 0, 3)
              .entriesIn(LedgerColumn.need),
        ),
        ['B', 'C', 'A'],
      );
      expect(
        names(
          base
              .reorderEntry(LedgerColumn.need, 2, 0)
              .entriesIn(LedgerColumn.need),
        ),
        ['C', 'A', 'B'],
      );
    });

    test('reorders sub-entries inside their entry', () {
      final subs = base
          .reorderSub(LedgerColumn.need, 'a', 1, 0)
          .entriesIn(LedgerColumn.need)
          .first
          .subs;
      expect([for (final s in subs) s.name], ['S2', 'S1']);
    });

    test(
      'moves an entry with its sub-entries to the bottom of another column',
      () {
        final moved = base
            .addEntry(LedgerColumn.want, const Entry(id: 'w', name: 'W'))
            .moveEntry('a', LedgerColumn.need, LedgerColumn.want);
        expect(names(moved.entriesIn(LedgerColumn.need)), ['B', 'C']);
        expect(names(moved.entriesIn(LedgerColumn.want)), ['W', 'A']);
        expect(moved.columnTotal(LedgerColumn.want), 3);
        expect(moved.grandTotal, base.grandTotal);
      },
    );

    test('moving onto the same column changes nothing', () {
      expect(
        base.moveEntry('a', LedgerColumn.need, LedgerColumn.need),
        same(base),
      );
    });
  });

  group('dragging', () {
    late LocalLedgerRepository repo;
    late String tableId;

    Future<void> pumpTable(
      WidgetTester tester, {
      required TargetPlatform platform,
    }) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      debugDefaultTargetPlatformOverride = platform;
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
              const Entry(id: 'a', name: 'Rent', amount: 100),
            )
            .addEntry(LedgerColumn.need, const Entry(id: 'b', name: 'Food'))
            .addSub(
              LedgerColumn.need,
              'b',
              const SubEntry(id: 's1', name: 'Rice', amount: 10),
            )
            .addSub(
              LedgerColumn.need,
              'b',
              const SubEntry(id: 's2', name: 'Oil', amount: 20),
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

    Future<LedgerTable> saved() async =>
        (await repo.allTables()).singleWhere((t) => t.id == tableId);

    Future<void> showSubEntries(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Show sub-entries'));
      await tester.pumpAndSettle();
    }

    Future<void> dragGrip(
      WidgetTester tester,
      String rowName,
      Offset by,
    ) async {
      final row = find
          .ancestor(of: find.text(rowName), matching: find.byType(Row))
          .first;
      final grip = find.descendant(
        of: row,
        matching: find.byIcon(Icons.drag_handle_rounded),
      );
      final gesture = await tester.startGesture(tester.getCenter(grip));
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(by / 10);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();
    }

    Future<void> dragRowTo(
      WidgetTester tester,
      String rowName,
      Offset target, {
      bool longPress = false,
    }) async {
      final gesture = await tester.startGesture(
        tester.getCenter(find.text(rowName)),
      );
      if (longPress) {
        await tester.pump(
          kLongPressTimeout + const Duration(milliseconds: 100),
        );
      }
      await gesture.moveBy(const Offset(30, 0));
      await tester.pump();
      await gesture.moveTo(target);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
    }

    testWidgets('the grip reorders entries', (tester) async {
      await pumpTable(tester, platform: TargetPlatform.macOS);
      await dragGrip(tester, 'Rent', const Offset(0, 200));
      expect(names((await saved()).entriesIn(LedgerColumn.need)), [
        'Food',
        'Rent',
      ]);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('the grip reorders sub-entries', (tester) async {
      await pumpTable(tester, platform: TargetPlatform.macOS);
      await showSubEntries(tester);
      await dragGrip(tester, 'Oil', const Offset(0, -60));
      final food = (await saved()).entriesIn(LedgerColumn.need).last;
      expect([for (final s in food.subs) s.name], ['Oil', 'Rice']);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('dragging a row moves it to another column (mouse)', (
      tester,
    ) async {
      await pumpTable(tester, platform: TargetPlatform.macOS);
      await showSubEntries(tester);
      final want = tester.getCenter(find.text('WANT'));
      await dragRowTo(tester, 'Food', want + const Offset(0, 150));
      final table = await saved();
      expect(names(table.entriesIn(LedgerColumn.need)), ['Rent']);
      expect(names(table.entriesIn(LedgerColumn.want)), ['Food']);
      expect(table.entriesIn(LedgerColumn.want).single.subs, hasLength(2));
      expect(find.text('Rice'), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('long-press drag moves a row to another column (touch)', (
      tester,
    ) async {
      await pumpTable(tester, platform: TargetPlatform.android);
      final tithe = tester.getCenter(find.text('TITHE'));
      await dragRowTo(
        tester,
        'Rent',
        tithe + const Offset(0, 150),
        longPress: true,
      );
      final table = await saved();
      expect(names(table.entriesIn(LedgerColumn.tithe)), ['Rent']);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('hovering a row reveals its add sub-entry button', (
      tester,
    ) async {
      await pumpTable(tester, platform: TargetPlatform.macOS);
      final addSub = find.byTooltip('Add sub-entry to Rent');
      double opacity() => tester
          .widget<AnimatedOpacity>(
            find.ancestor(of: addSub, matching: find.byType(AnimatedOpacity)),
          )
          .opacity;
      expect(opacity(), 0);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: tester.getCenter(find.text('Rent')));
      await tester.pumpAndSettle();
      expect(opacity(), 1);

      await tester.tap(addSub);
      await tester.pumpAndSettle();
      expect(find.text('Add sub-entry to Rent'), findsWidgets);
      await mouse.removePointer();
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('dropping back on the same column keeps the entry', (
      tester,
    ) async {
      await pumpTable(tester, platform: TargetPlatform.macOS);
      final need = tester.getCenter(find.text('NEED'));
      await dragRowTo(tester, 'Rent', need + const Offset(0, 250));
      expect(names((await saved()).entriesIn(LedgerColumn.need)), [
        'Rent',
        'Food',
      ]);
      debugDefaultTargetPlatformOverride = null;
    });
  });
}
