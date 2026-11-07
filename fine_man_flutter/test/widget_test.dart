import 'package:fine_man_flutter/format.dart';
import 'package:fine_man_flutter/models/ledger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  LedgerTable emptyTable() => LedgerTable(
    id: 't',
    name: 'October',
    createdAt: DateTime(2026, 10, 19),
    columns: LedgerTable.columnsFromMap(null),
  );

  test('entry uses its own amount until it has sub-entries', () {
    var table = emptyTable().addEntry(
      LedgerColumn.need,
      const Entry(id: 'e', name: 'Food', amount: 5000),
    );
    expect(table.columnTotal(LedgerColumn.need), 5000);

    table = table
        .addSub(
          LedgerColumn.need,
          'e',
          const SubEntry(id: 's1', name: 'Rice', amount: 1200),
        )
        .addSub(
          LedgerColumn.need,
          'e',
          const SubEntry(id: 's2', name: 'Oil', amount: 800),
        );
    expect(table.columnTotal(LedgerColumn.need), 2000);

    table = table
        .removeSub(LedgerColumn.need, 'e', 's1')
        .removeSub(LedgerColumn.need, 'e', 's2');
    expect(table.columnTotal(LedgerColumn.need), 5000);
  });

  test('grand total sums every column', () {
    final table = emptyTable()
        .addEntry(
          LedgerColumn.need,
          const Entry(id: 'a', name: 'Rent', amount: 100),
        )
        .addEntry(
          LedgerColumn.tithe,
          const Entry(id: 'b', name: 'Church', amount: 50),
        );
    expect(table.grandTotal, 150);
  });

  test('columns round-trip through maps', () {
    final table = emptyTable()
        .addEntry(LedgerColumn.want, const Entry(id: 'a', name: 'Shoes'))
        .addSub(
          LedgerColumn.want,
          'a',
          const SubEntry(id: 's', name: 'Laces', amount: 300),
        );
    final restored = LedgerTable.columnsFromMap(table.columnsToMap());
    expect(restored[LedgerColumn.want]!.single.total, 300);
  });

  test('naira parsing and formatting', () {
    expect(parseNaira('12,500.50'), 1250050);
    expect(parseNaira('₦4000'), 400000);
    expect(parseNaira(''), 0);
    expect(parseNaira('abc'), isNull);
    expect(naira(1250000), '₦12,500');
    expect(naira(1250050), '₦12,500.50');
  });
}
