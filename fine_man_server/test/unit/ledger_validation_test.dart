import 'package:fine_man_server/src/generated/protocol.dart';
import 'package:fine_man_server/src/ledger/ledger_validation.dart';
import 'package:test/test.dart';

LedgerColumns _columns(int amount) => LedgerColumns(
  need: [
    LedgerEntry(id: 'e', name: 'Food', amount: amount, subs: const []),
  ],
  work: const [],
  want: const [],
  luxury: const [],
  tithe: const [],
);

void main() {
  final refused = throwsA(isA<LedgerException>());

  test('a table needs a name', () {
    expect(() => validateName('   '), refused);
    validateName('October');
  });

  test('amounts must survive the trip through the web app', () {
    validateColumns(_columns(maxAmount));
    expect(() => validateColumns(_columns(maxAmount + 1)), refused);
  });

  test('notes must be text or an image with a web link', () {
    validateNotes([LedgerNote(type: 'text', text: 'Hi')]);
    validateNotes([LedgerNote(type: 'image', url: 'https://x.test/a.png')]);
    expect(() => validateNotes([LedgerNote(type: 'video')]), refused);
    expect(() => validateNotes([LedgerNote(type: 'text')]), refused);
    expect(
      () => validateNotes([LedgerNote(type: 'image', url: 'javascript:x')]),
      refused,
    );
  });
}
