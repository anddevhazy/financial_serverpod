import 'dart:convert';

import 'package:intl/intl.dart';

import '../models/ledger.dart';

/// Backup files are plain JSON so they can move between local storage,
/// accounts, and any version of the app. The format is unchanged from the
/// Firebase version of Fine Man, so its backups import here.
const _format = 'fine_man_backup';
const _version = 1;

String encodeBackup(List<LedgerTable> tables) =>
    const JsonEncoder.withIndent('  ').convert({
      'format': _format,
      'version': _version,
      'exportedAt': DateTime.now().toIso8601String(),
      'tables': [for (final t in tables) t.toJson()],
    });

/// Returns the tables in a backup file, or throws [FormatException]
/// when the text is not a Fine Man backup.
List<LedgerTable> decodeBackup(String text) {
  try {
    final json = jsonDecode(text);
    if (json is! Map || json['format'] != _format) {
      throw const FormatException('Not a Fine Man backup file.');
    }
    return [
      for (final t in json['tables'] as List)
        LedgerTable.fromJson(Map<String, dynamic>.from(t as Map)),
    ];
  } on FormatException {
    rethrow;
  } catch (_) {
    throw const FormatException('The backup file is damaged.');
  }
}

String backupFileName() =>
    'fine-man-backup-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.json';
