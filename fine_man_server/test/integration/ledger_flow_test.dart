import 'dart:async';
import 'dart:typed_data';

import 'package:fine_man_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

LedgerColumns _emptyColumns() => LedgerColumns(
  need: [],
  work: [],
  want: [],
  luxury: [],
  tithe: [],
);

LedgerTableData _table(String id, {String? name, DateTime? createdAt}) =>
    LedgerTableData(
      id: id,
      name: name ?? 'Table $id',
      createdAt: createdAt ?? DateTime.utc(2026, 10, 19),
      columns: _emptyColumns(),
      notes: [],
      listOrder: [],
    );

LedgerColumns _withRent() => _emptyColumns()
  ..need.add(
    LedgerEntry(
      id: 'e',
      name: 'Rent',
      amount: 5000,
      subs: [LedgerSubEntry(id: 's', name: 'Agent', amount: 100)],
    ),
  );

void main() {
  withServerpod('Ledger', (sessionBuilder, endpoints) {
    late TestSessionBuilder alice, bob;

    TestSessionBuilder signIn() => sessionBuilder.copyWith(
      authentication: AuthenticationOverride.authenticationInfo(
        const Uuid().v4(),
        {},
      ),
    );

    setUp(() {
      alice = signIn();
      bob = signIn();
    });

    test('requires sign-in', () async {
      expect(
        () => endpoints.ledger.list(sessionBuilder),
        throwsA(isA<ServerpodUnauthenticatedException>()),
      );
    });

    test('tables come back newest first with everything in them', () async {
      await endpoints.ledger.saveTables(alice, [
        _table('old', createdAt: DateTime.utc(2026, 1, 1)),
        _table('new', createdAt: DateTime.utc(2026, 6, 1)),
      ]);
      await endpoints.ledger.saveColumns(alice, 'new', _withRent());
      await endpoints.ledger.saveNotes(alice, 'new', [
        LedgerNote(type: 'text', text: 'Hello'),
        LedgerNote(
          type: 'image',
          url: 'https://x.test/a.png',
          publicId: 'a',
          width: 10,
          height: 20,
        ),
      ]);
      await endpoints.ledger.saveListOrder(alice, 'new', ['e']);

      final tables = await endpoints.ledger.list(alice);
      expect([for (final t in tables) t.id], ['new', 'old']);
      final table = tables.first;
      expect(table.columns.need.single.subs.single.name, 'Agent');
      expect(table.notes.last.height, 20);
      expect(table.listOrder, ['e']);
      expect(table.createdAt, DateTime.utc(2026, 6, 1));
    });

    test('saving one field leaves the others alone', () async {
      await endpoints.ledger.saveTables(alice, [_table('t')]);
      await endpoints.ledger.saveColumns(alice, 't', _withRent());
      await endpoints.ledger.saveNotes(alice, 't', [
        LedgerNote(type: 'text', text: 'Hello'),
      ]);
      await endpoints.ledger.rename(alice, 't', 'Renamed');

      final table = (await endpoints.ledger.list(alice)).single;
      expect(table.name, 'Renamed');
      expect(table.columns.need.single.name, 'Rent');
      expect(table.notes.single.text, 'Hello');
    });

    test('importing the same table twice replaces it', () async {
      await endpoints.ledger.saveTables(alice, [_table('t', name: 'First')]);
      await endpoints.ledger.saveTables(alice, [_table('t', name: 'Second')]);
      final tables = await endpoints.ledger.list(alice);
      expect(tables.single.name, 'Second');
    });

    test('a bad table in an import saves none of them', () async {
      await expectLater(
        endpoints.ledger.saveTables(alice, [
          _table('good'),
          _table('bad', name: ' '),
        ]),
        throwsA(isA<LedgerException>()),
      );
      expect(await endpoints.ledger.list(alice), isEmpty);
    });

    test('users can reach only their own tables', () async {
      await endpoints.ledger.saveTables(alice, [_table('t', name: 'Mine')]);

      expect(await endpoints.ledger.list(bob), isEmpty);
      await endpoints.ledger.rename(bob, 't', 'Hacked');
      await endpoints.ledger.saveColumns(bob, 't', _withRent());
      await endpoints.ledger.delete(bob, 't');

      final table = (await endpoints.ledger.list(alice)).single;
      expect(table.name, 'Mine');
      expect(table.columns.need, isEmpty);
    });

    test('two users can use the same table id', () async {
      await endpoints.ledger.saveTables(alice, [_table('t', name: 'Alice')]);
      await endpoints.ledger.saveTables(bob, [_table('t', name: 'Bob')]);
      expect((await endpoints.ledger.list(alice)).single.name, 'Alice');
      expect((await endpoints.ledger.list(bob)).single.name, 'Bob');
    });

    test('writing to a deleted table does nothing', () async {
      await endpoints.ledger.saveTables(alice, [_table('t')]);
      await endpoints.ledger.delete(alice, 't');
      await endpoints.ledger.saveColumns(alice, 't', _withRent());
      expect(await endpoints.ledger.list(alice), isEmpty);
    });

    test('the stream opens with a snapshot, then sends changes', () async {
      await endpoints.ledger.saveTables(alice, [_table('a')]);

      final events = <LedgerEvent>[];
      final done = Completer<void>();
      final sub = endpoints.ledger.events(alice).listen((event) {
        events.add(event);
        if (event.deletedId != null) done.complete();
      });
      addTearDown(sub.cancel);
      await flushEventQueue();
      while (events.isEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      await endpoints.ledger.saveTables(bob, [_table('other')]);
      await endpoints.ledger.rename(alice, 'a', 'Renamed');
      await endpoints.ledger.delete(alice, 'a');
      await done.future.timeout(const Duration(seconds: 10));

      expect([for (final t in events[0].snapshot!) t.id], ['a']);
      expect(events[1].updated!.name, 'Renamed');
      expect(events[2].deletedId, 'a');
      expect(events, hasLength(3), reason: 'Bob’s table isn’t sent to Alice');
    });
  });

  withServerpod('Note images', (sessionBuilder, endpoints) {
    late TestSessionBuilder alice;

    // A valid 1x1 PNG.
    final png = ByteData.sublistView(
      Uint8List.fromList([
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        0x00,
        0x00,
        0x00,
        0x0D,
        0x49,
        0x48,
        0x44,
        0x52,
        0x00,
        0x00,
        0x00,
        0x01,
        0x00,
        0x00,
        0x00,
        0x01,
        0x08,
        0x06,
        0x00,
        0x00,
        0x00,
        0x1F,
        0x15,
        0xC4,
        0x89,
        0x00,
        0x00,
        0x00,
        0x0A,
        0x49,
        0x44,
        0x41,
        0x54,
        0x78,
        0x9C,
        0x63,
        0x00,
        0x01,
        0x00,
        0x00,
        0x05,
        0x00,
        0x01,
        0x0D,
        0x0A,
        0x2D,
        0xB4,
        0x00,
        0x00,
        0x00,
        0x00,
        0x49,
        0x45,
        0x4E,
        0x44,
        0xAE,
        0x42,
        0x60,
        0x82,
      ]),
    );

    setUp(() {
      alice = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          const Uuid().v4(),
          {},
        ),
      );
    });

    /// Stores a file the way an upload does: not usable until it's verified.
    Future<void> arrive(Session session, String path, ByteData bytes) =>
        (session.serverpod.storage['public'] as DatabaseCloudStorage)
            .storeUnverifiedFile(session: session, path: path, byteData: bytes);

    test('refuses other file types and oversized images', () async {
      await expectLater(
        endpoints.noteImages.createUpload(alice, 'image/svg+xml', 100),
        throwsA(isA<LedgerException>()),
      );
      await expectLater(
        endpoints.noteImages.createUpload(alice, 'text/html', 100),
        throwsA(isA<LedgerException>()),
      );
      await expectLater(
        endpoints.noteImages.createUpload(alice, 'image/png', 11 * 1024 * 1024),
        throwsA(isA<LedgerException>()),
      );
    });

    test('an upload for someone else’s folder is refused', () async {
      await expectLater(
        endpoints.noteImages.confirmUpload(alice, 'notes/other-user/a.png'),
        throwsA(isA<LedgerException>()),
      );
    });

    test('an upload that never arrived is refused', () async {
      final upload = await endpoints.noteImages.createUpload(
        alice,
        'image/png',
        png.lengthInBytes,
      );
      await expectLater(
        endpoints.noteImages.confirmUpload(alice, upload.path),
        throwsA(isA<LedgerException>()),
      );
    });

    test('a stored image reports its size and link', () async {
      final session = alice.build();
      final upload = await endpoints.noteImages.createUpload(
        alice,
        'image/png',
        png.lengthInBytes,
      );
      expect(upload.path, endsWith('.png'));
      await arrive(session, upload.path, png);

      final note = await endpoints.noteImages.confirmUpload(alice, upload.path);
      expect(note.type, 'image');
      expect(note.width, 1);
      expect(note.height, 1);
      expect(note.publicId, upload.path);
      expect(note.url, contains('serverpod_cloud_storage'));
    });

    test('a file that is not an image is deleted', () async {
      final session = alice.build();
      final upload = await endpoints.noteImages.createUpload(
        alice,
        'image/png',
        5,
      );
      await arrive(
        session,
        upload.path,
        ByteData.sublistView(Uint8List.fromList([1, 2, 3, 4, 5])),
      );

      await expectLater(
        endpoints.noteImages.confirmUpload(alice, upload.path),
        throwsA(isA<LedgerException>()),
      );
      expect(
        await session.storage.fileExists(
          storageId: 'public',
          path: upload.path,
        ),
        isFalse,
      );
    });
  });
}
