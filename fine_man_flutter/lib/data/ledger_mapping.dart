import 'package:fine_man_client/fine_man_client.dart';

import '../models/ledger.dart';

/// Converts between the app's ledger classes and the ones the server sends.

LedgerTable tableFromData(LedgerTableData data) => LedgerTable(
  id: data.id,
  name: data.name,
  // The server speaks UTC; the app shows and compares local dates.
  createdAt: data.createdAt.toLocal(),
  columns: columnsFromData(data.columns),
  notes: [for (final n in data.notes) ?noteFromData(n)],
  listOrder: data.listOrder,
);

LedgerTableData tableToData(LedgerTable table) => LedgerTableData(
  id: table.id,
  name: table.name,
  createdAt: table.createdAt.toUtc(),
  columns: columnsToData(table),
  notes: notesToData(table.notes),
  listOrder: table.listOrder,
);

Map<LedgerColumn, List<Entry>> columnsFromData(LedgerColumns data) => {
  LedgerColumn.need: _entriesFromData(data.need),
  LedgerColumn.work: _entriesFromData(data.work),
  LedgerColumn.want: _entriesFromData(data.want),
  LedgerColumn.luxury: _entriesFromData(data.luxury),
  LedgerColumn.tithe: _entriesFromData(data.tithe),
};

LedgerColumns columnsToData(LedgerTable table) => LedgerColumns(
  need: _entriesToData(table.entriesIn(LedgerColumn.need)),
  work: _entriesToData(table.entriesIn(LedgerColumn.work)),
  want: _entriesToData(table.entriesIn(LedgerColumn.want)),
  luxury: _entriesToData(table.entriesIn(LedgerColumn.luxury)),
  tithe: _entriesToData(table.entriesIn(LedgerColumn.tithe)),
);

List<Entry> _entriesFromData(List<LedgerEntry> entries) => [
  for (final e in entries)
    Entry(
      id: e.id,
      name: e.name,
      amount: e.amount,
      subs: [
        for (final s in e.subs)
          SubEntry(id: s.id, name: s.name, amount: s.amount),
      ],
    ),
];

List<LedgerEntry> _entriesToData(List<Entry> entries) => [
  for (final e in entries)
    LedgerEntry(
      id: e.id,
      name: e.name,
      amount: e.amount,
      subs: [
        for (final s in e.subs)
          LedgerSubEntry(id: s.id, name: s.name, amount: s.amount),
      ],
    ),
];

/// Returns null for notes this version of the app doesn't understand.
NoteBlock? noteFromData(LedgerNote note) => switch (note.type) {
  'text' => TextBlock(note.text ?? ''),
  'image' => ImageBlock(
    url: note.url ?? '',
    publicId: note.publicId ?? '',
    width: note.width,
    height: note.height,
  ),
  _ => null,
};

List<LedgerNote> notesToData(List<NoteBlock> notes) => [
  for (final n in notes)
    switch (n) {
      TextBlock(:final text) => LedgerNote(type: 'text', text: text),
      ImageBlock() => LedgerNote(
        type: 'image',
        url: n.url,
        publicId: n.publicId,
        width: n.width,
        height: n.height,
      ),
    },
];
