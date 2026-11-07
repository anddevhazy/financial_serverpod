import '../generated/protocol.dart';

/// Largest amount that survives a round trip through the web app, where
/// integers are JavaScript numbers.
const maxAmount = 9007199254740991;

const _maxIdLength = 128;
const _maxNameLength = 1000;

/// Throws [LedgerException] when a table sent by the app can't be stored.
void validateTable(LedgerTableData table) {
  validateTableId(table.id);
  validateName(table.name);
  validateColumns(table.columns);
  validateNotes(table.notes);
  validateListOrder(table.listOrder);
}

void validateTableId(String id) {
  if (id.isEmpty || id.length > _maxIdLength) {
    throw LedgerException(message: 'That table id isn’t valid.');
  }
}

void validateName(String name) {
  if (name.trim().isEmpty) {
    throw LedgerException(message: 'A table needs a name.');
  }
  _checkLength(name);
}

void validateColumns(LedgerColumns columns) {
  for (final entries in [
    columns.need,
    columns.work,
    columns.want,
    columns.luxury,
    columns.tithe,
  ]) {
    for (final entry in entries) {
      _checkLength(entry.name);
      _checkAmount(entry.amount);
      for (final sub in entry.subs) {
        _checkLength(sub.name);
        _checkAmount(sub.amount);
      }
    }
  }
}

void validateNotes(List<LedgerNote> notes) {
  for (final note in notes) {
    switch (note.type) {
      case 'text':
        if (note.text == null) {
          throw LedgerException(message: 'A text note has no text.');
        }
      case 'image':
        final url = Uri.tryParse(note.url ?? '');
        if (url == null || !(url.isScheme('http') || url.isScheme('https'))) {
          throw LedgerException(message: 'An image note has a bad link.');
        }
      default:
        throw LedgerException(message: 'Unknown note type: ${note.type}.');
    }
  }
}

void validateListOrder(List<String> order) {
  for (final id in order) {
    if (id.length > _maxIdLength) {
      throw LedgerException(message: 'The list order isn’t valid.');
    }
  }
}

void _checkLength(String name) {
  if (name.length > _maxNameLength) {
    throw LedgerException(
      message: 'Names can be at most $_maxNameLength characters.',
    );
  }
}

void _checkAmount(int amount) {
  if (amount.abs() > maxAmount) {
    throw LedgerException(message: 'That amount is too large.');
  }
}
