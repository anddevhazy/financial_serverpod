import 'dart:math';

/// The five fixed columns every table has, in display order.
enum LedgerColumn {
  need('Need'),
  work('Work'),
  want('Want'),
  luxury('Luxury'),
  tithe('Tithe');

  const LedgerColumn(this.label);
  final String label;
}

/// The columns whose entries appear in the single list, in the order they
/// start out in.
const listedColumns = [
  LedgerColumn.need,
  LedgerColumn.work,
  LedgerColumn.want,
  LedgerColumn.luxury,
];

final _random = Random();

String newId() =>
    '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${_random.nextInt(1 << 20).toRadixString(36)}';

/// Amounts are stored in kobo (1/100 naira) so totals never drift.
class SubEntry {
  const SubEntry({required this.id, required this.name, required this.amount});

  final String id;
  final String name;
  final int amount;

  SubEntry copyWith({String? name, int? amount}) =>
      SubEntry(id: id, name: name ?? this.name, amount: amount ?? this.amount);

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'amount': amount};

  factory SubEntry.fromMap(Map<String, dynamic> map) => SubEntry(
    id: map['id'] as String? ?? newId(),
    name: map['name'] as String? ?? '',
    amount: (map['amount'] as num?)?.toInt() ?? 0,
  );
}

class Entry {
  const Entry({
    required this.id,
    required this.name,
    this.amount = 0,
    this.subs = const [],
  });

  final String id;
  final String name;

  /// The entry's own amount. Only used while it has no sub-entries.
  final int amount;
  final List<SubEntry> subs;

  bool get hasSubs => subs.isNotEmpty;

  int get total =>
      hasSubs ? subs.fold(0, (sum, sub) => sum + sub.amount) : amount;

  Entry copyWith({String? name, int? amount, List<SubEntry>? subs}) => Entry(
    id: id,
    name: name ?? this.name,
    amount: amount ?? this.amount,
    subs: subs ?? this.subs,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'amount': amount,
    'subs': subs.map((s) => s.toMap()).toList(),
  };

  factory Entry.fromMap(Map<String, dynamic> map) => Entry(
    id: map['id'] as String? ?? newId(),
    name: map['name'] as String? ?? '',
    amount: (map['amount'] as num?)?.toInt() ?? 0,
    subs: [
      for (final s in (map['subs'] as List? ?? const []))
        SubEntry.fromMap(Map<String, dynamic>.from(s as Map)),
    ],
  );
}

/// One piece of a table's notes: a run of text or an uploaded image.
sealed class NoteBlock {
  const NoteBlock();

  Map<String, dynamic> toMap();

  /// Returns null for blocks this version of the app doesn't understand.
  static NoteBlock? fromMap(Map<String, dynamic> map) => switch (map['type']) {
    'text' => TextBlock(map['text'] as String? ?? ''),
    'image' => ImageBlock(
      url: map['url'] as String,
      publicId: map['publicId'] as String? ?? '',
      width: (map['width'] as num?)?.toInt(),
      height: (map['height'] as num?)?.toInt(),
    ),
    _ => null,
  };
}

class TextBlock extends NoteBlock {
  const TextBlock(this.text);

  final String text;

  @override
  Map<String, dynamic> toMap() => {'type': 'text', 'text': text};
}

class ImageBlock extends NoteBlock {
  const ImageBlock({
    required this.url,
    required this.publicId,
    this.width,
    this.height,
  });

  final String url;

  /// Where the image is stored, needed to delete it later.
  final String publicId;
  final int? width;
  final int? height;

  @override
  Map<String, dynamic> toMap() => {
    'type': 'image',
    'url': url,
    'publicId': publicId,
    'width': ?width,
    'height': ?height,
  };
}

List<NoteBlock> notesFromList(List? list) => [
  for (final b in list ?? const [])
    ?NoteBlock.fromMap(Map<String, dynamic>.from(b as Map)),
];

List<Map<String, dynamic>> notesToList(List<NoteBlock> notes) => [
  for (final b in notes) b.toMap(),
];

class LedgerTable {
  const LedgerTable({
    required this.id,
    required this.name,
    required this.createdAt,
    this.columns = const {},
    this.notes = const [],
    this.listOrder = const [],
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final Map<LedgerColumn, List<Entry>> columns;
  final List<NoteBlock> notes;

  /// Entry ids in the order the single list shows them. It's kept apart
  /// from the columns, so reordering the list never changes the sheet.
  final List<String> listOrder;

  /// Every entry in [listedColumns], as one list: the ones in [listOrder]
  /// first, in that order, then any others (e.g. new entries) in column
  /// order.
  List<Entry> get listEntries {
    final byId = {
      for (final c in listedColumns)
        for (final e in entriesIn(c)) e.id: e,
    };
    final ordered = [for (final id in listOrder) ?byId.remove(id)];
    return [...ordered, ...byId.values];
  }

  /// Moves the list entry at [oldIndex] to [newIndex], using
  /// [ReorderableListView]'s convention (indexes before removal).
  LedgerTable reorderList(int oldIndex, int newIndex) => copyWith(
    listOrder: [
      for (final e in _reordered(listEntries, oldIndex, newIndex)) e.id,
    ],
  );

  /// True when the notes hold any text or images.
  bool get hasNotes => notes.any(
    (b) => b is ImageBlock || (b is TextBlock && b.text.trim().isNotEmpty),
  );

  List<Entry> entriesIn(LedgerColumn column) => columns[column] ?? const [];

  int columnTotal(LedgerColumn column) =>
      entriesIn(column).fold(0, (sum, e) => sum + e.total);

  int get grandTotal =>
      LedgerColumn.values.fold(0, (sum, c) => sum + columnTotal(c));

  LedgerTable copyWith({
    String? name,
    Map<LedgerColumn, List<Entry>>? columns,
    List<NoteBlock>? notes,
    List<String>? listOrder,
  }) => LedgerTable(
    id: id,
    name: name ?? this.name,
    createdAt: createdAt,
    columns: columns ?? this.columns,
    notes: notes ?? this.notes,
    listOrder: listOrder ?? this.listOrder,
  );

  LedgerTable _withColumn(LedgerColumn column, List<Entry> entries) =>
      copyWith(columns: {...columns, column: entries});

  LedgerTable _mapEntry(
    LedgerColumn column,
    String entryId,
    Entry Function(Entry) f,
  ) => _withColumn(column, [
    for (final e in entriesIn(column)) e.id == entryId ? f(e) : e,
  ]);

  LedgerTable addEntry(LedgerColumn column, Entry entry) =>
      _withColumn(column, [...entriesIn(column), entry]);

  LedgerTable updateEntry(
    LedgerColumn column,
    String entryId, {
    String? name,
    int? amount,
  }) =>
      _mapEntry(column, entryId, (e) => e.copyWith(name: name, amount: amount));

  LedgerTable removeEntry(LedgerColumn column, String entryId) => _withColumn(
    column,
    entriesIn(column).where((e) => e.id != entryId).toList(),
  );

  /// Moves the entry at [oldIndex] so it lands at [newIndex], using
  /// [ReorderableListView]'s convention (indexes before removal).
  LedgerTable reorderEntry(LedgerColumn column, int oldIndex, int newIndex) =>
      _withColumn(column, _reordered(entriesIn(column), oldIndex, newIndex));

  /// Moves an entry, with its sub-entries, to the bottom of [to].
  LedgerTable moveEntry(String entryId, LedgerColumn from, LedgerColumn to) {
    if (from == to) return this;
    final entry = entriesIn(from).where((e) => e.id == entryId).firstOrNull;
    if (entry == null) return this;
    return removeEntry(from, entryId).addEntry(to, entry);
  }

  LedgerTable reorderSub(
    LedgerColumn column,
    String entryId,
    int oldIndex,
    int newIndex,
  ) => _mapEntry(
    column,
    entryId,
    (e) => e.copyWith(subs: _reordered(e.subs, oldIndex, newIndex)),
  );

  static List<T> _reordered<T>(List<T> items, int oldIndex, int newIndex) {
    final list = [...items];
    if (newIndex > oldIndex) newIndex -= 1;
    list.insert(newIndex, list.removeAt(oldIndex));
    return list;
  }

  LedgerTable addSub(LedgerColumn column, String entryId, SubEntry sub) =>
      _mapEntry(column, entryId, (e) => e.copyWith(subs: [...e.subs, sub]));

  LedgerTable updateSub(
    LedgerColumn column,
    String entryId,
    String subId, {
    String? name,
    int? amount,
  }) => _mapEntry(
    column,
    entryId,
    (e) => e.copyWith(
      subs: [
        for (final s in e.subs)
          s.id == subId ? s.copyWith(name: name, amount: amount) : s,
      ],
    ),
  );

  LedgerTable removeSub(LedgerColumn column, String entryId, String subId) =>
      _mapEntry(
        column,
        entryId,
        (e) => e.copyWith(subs: e.subs.where((s) => s.id != subId).toList()),
      );

  Map<String, dynamic> columnsToMap() => {
    for (final c in LedgerColumn.values)
      c.name: entriesIn(c).map((e) => e.toMap()).toList(),
  };

  /// Full table as plain JSON, used for local storage and backup files.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'columns': columnsToMap(),
    'notes': notesToList(notes),
    'listOrder': listOrder,
  };

  factory LedgerTable.fromJson(Map<String, dynamic> json) => LedgerTable(
    id: json['id'] as String,
    name: json['name'] as String? ?? 'Untitled',
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      (json['createdAt'] as num).toInt(),
    ),
    columns: columnsFromMap(json['columns'] as Map?),
    notes: notesFromList(json['notes'] as List?),
    listOrder: listOrderFromList(json['listOrder'] as List?),
  );

  static List<String> listOrderFromList(List? list) => [
    for (final id in list ?? const []) id as String,
  ];

  static Map<LedgerColumn, List<Entry>> columnsFromMap(Map? map) => {
    for (final c in LedgerColumn.values)
      c: [
        for (final e in (map?[c.name] as List? ?? const []))
          Entry.fromMap(Map<String, dynamic>.from(e as Map)),
      ],
  };
}

/// The current time at millisecond precision, the precision every
/// storage format (JSON, the database, backups) keeps.
DateTime nowForStorage() =>
    DateTime.fromMillisecondsSinceEpoch(DateTime.now().millisecondsSinceEpoch);
