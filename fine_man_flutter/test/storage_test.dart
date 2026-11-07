import 'package:fine_man_flutter/data/backup.dart';
import 'package:fine_man_flutter/data/ledger_repository.dart';
import 'package:fine_man_flutter/models/ledger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('local tables survive reopening storage', () async {
    final repo = await LocalLedgerRepository.open();
    final table = await repo.createTable('October');
    await repo.saveColumns(
      table
          .addEntry(LedgerColumn.need, const Entry(id: 'e', name: 'Food'))
          .addSub(
            LedgerColumn.need,
            'e',
            const SubEntry(id: 's', name: 'Rice', amount: 1200),
          ),
    );

    final reopened = await LocalLedgerRepository.open();
    final tables = await reopened.allTables();
    expect(tables.single.name, 'October');
    expect(tables.single.createdAt, table.createdAt);
    expect(tables.single.columnTotal(LedgerColumn.need), 1200);
  });

  test('backup keeps ids, dates and entries', () async {
    final repo = await LocalLedgerRepository.open();
    final table = await repo.createTable('Trip');
    await repo.saveColumns(
      table.addEntry(
        LedgerColumn.luxury,
        const Entry(id: 'e', name: 'Hotel', amount: 900),
      ),
    );

    final restored = decodeBackup(encodeBackup(await repo.allTables()));
    expect(restored.single.id, table.id);
    expect(restored.single.createdAt, table.createdAt);
    expect(restored.single.columnTotal(LedgerColumn.luxury), 900);
  });

  test('importing the same backup twice does not duplicate tables', () async {
    final source = await LocalLedgerRepository.open();
    await source.createTable('A');
    final backup = encodeBackup(await source.allTables());

    final target = LocalLedgerRepository.inMemory();
    await target.importTables(decodeBackup(backup));
    await target.importTables(decodeBackup(backup));
    expect(await target.allTables(), hasLength(1));
  });

  test('moving clears local tables but keeps a safety copy', () async {
    final local = await LocalLedgerRepository.open();
    await local.createTable('A');
    await local.clearAfterMove();
    expect(await local.allTables(), isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString('fine_man.tables.moved_to_account'),
      contains('"A"'),
    );
  });

  test('rejects files that are not backups', () {
    expect(() => decodeBackup('{"hello": 1}'), throwsFormatException);
    expect(() => decodeBackup('not json'), throwsFormatException);
  });
}
