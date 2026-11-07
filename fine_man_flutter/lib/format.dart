import 'package:intl/intl.dart';

final _whole = NumberFormat('#,##0', 'en_US');
final _fraction = NumberFormat('#,##0.00', 'en_US');
final _date = DateFormat('d MMMM y');

/// Formats an amount in kobo as naira, dropping ".00" for whole amounts.
String naira(int kobo) {
  final value = kobo / 100;
  final text = kobo % 100 == 0 ? _whole.format(value) : _fraction.format(value);
  return '₦$text';
}

String nairaInput(int kobo) {
  if (kobo == 0) return '';
  return kobo % 100 == 0 ? '${kobo ~/ 100}' : (kobo / 100).toStringAsFixed(2);
}

/// Parses user input like "12,500.50" or "₦4000" into kobo.
/// Returns null when the text is not a valid amount.
int? parseNaira(String input) {
  final cleaned = input.replaceAll(RegExp(r'[₦,\s]'), '');
  if (cleaned.isEmpty) return 0;
  final value = double.tryParse(cleaned);
  if (value == null || value < 0) return null;
  return (value * 100).round();
}

String createdLabel(DateTime date) => 'Created ${_date.format(date)}';
