import 'package:fine_man_flutter/data/ledger_repository.dart';
import 'package:fine_man_flutter/models/ledger.dart';
import 'package:fine_man_flutter/screens/entries_screen.dart';
import 'package:fine_man_flutter/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

List<String> names(List<Entry> entries) => [for (final e in entries) e.name];

final base =
    LedgerTable(
          id: 't',
          name: 'October',
          createdAt: DateTime(2026, 10, 19),
          columns: LedgerTable.columnsFromMap(null),
        )
        .addEntry(LedgerColumn.want, const Entry(id: 'w', name: 'Movies'))
        .addEntry(LedgerColumn.tithe, const Entry(id: 't1', name: 'Church'))
        .addEntry(LedgerColumn.need, const Entry(id: 'n1', name: 'Rent'))
        .addEntry(LedgerColumn.luxury, const Entry(id: 'l', name: 'Watch'))
        .addEntry(LedgerColumn.need, const Entry(id: 'n2', name: 'Food'))
        .addEntry(LedgerColumn.work, const Entry(id: 'k', name: 'Laptop'));

void main() {
  group('model', () {
    test(
      'lists Need, Work, Want and Luxury in column order, without Tithe',
      () {
        expect(names(base.listEntries), [
          'Rent',
          'Food',
          'Laptop',
          'Movies',
          'Watch',
        ]);
      },
    );

    test('reordering the list leaves the columns alone', () {
      final moved = base.reorderList(4, 0);
      expect(names(moved.listEntries), [
        'Watch',
        'Rent',
        'Food',
        'Laptop',
        'Movies',
      ]);
      expect(moved.columns, same(base.columns));
    });

    test('new entries go to the end; deleted ones drop out', () {
      final next = base
          .reorderList(4, 0)
          .addEntry(LedgerColumn.need, const Entry(id: 'n3', name: 'Water'))
          .removeEntry(LedgerColumn.need, 'n1');
      expect(names(next.listEntries), [
        'Watch',
        'Food',
        'Laptop',
        'Movies',
        'Water',
      ]);
    });

    test('moving an entry between listed columns keeps its place', () {
      final next = base
          .reorderList(4, 0)
          .moveEntry('l', LedgerColumn.luxury, LedgerColumn.need);
      expect(names(next.listEntries).first, 'Watch');
    });

    test('the list order survives JSON', () {
      final moved = base.reorderList(4, 0);
      final back = LedgerTable.fromJson(moved.toJson());
      expect(names(back.listEntries), names(moved.listEntries));
    });
  });

  testWidgets('the grip reorders the list but not the sheet', (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo = LocalLedgerRepository.inMemory();
    final t = await repo.createTable('October');
    await repo.saveColumns(
      t
          .addEntry(LedgerColumn.need, const Entry(id: 'a', name: 'Rent'))
          .addEntry(LedgerColumn.work, const Entry(id: 'b', name: 'Laptop'))
          .addSub(
            LedgerColumn.work,
            'b',
            const SubEntry(id: 's', name: 'Charger', amount: 500),
          )
          .addEntry(LedgerColumn.tithe, const Entry(id: 'c', name: 'Church')),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: EntriesScreen(repo: repo, tableId: t.id),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rent'), findsOneWidget);
    expect(find.text('Laptop'), findsOneWidget);
    expect(find.text('Church'), findsNothing);

    // Sub-entries open from the chevron.
    expect(find.text('Charger'), findsNothing);
    await tester.tap(find.byTooltip('Show sub-entries'));
    await tester.pumpAndSettle();
    expect(find.text('Charger'), findsOneWidget);

    final grip = find.descendant(
      of: find
          .ancestor(of: find.text('Rent'), matching: find.byType(Row))
          .first,
      matching: find.byIcon(Icons.drag_handle_rounded),
    );
    final gesture = await tester.startGesture(tester.getCenter(grip));
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(0, 10));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    final saved = (await repo.allTables()).single;
    expect(names(saved.listEntries), ['Laptop', 'Rent']);
    expect(names(saved.entriesIn(LedgerColumn.need)), ['Rent']);
    expect(names(saved.entriesIn(LedgerColumn.work)), ['Laptop']);
    debugDefaultTargetPlatformOverride = null;
  });
}
