import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../format.dart';
import '../theme.dart';

/// The accountant's double underline drawn beneath a total.
class DoubleRule extends StatelessWidget {
  const DoubleRule({super.key, this.color = Palette.ink, this.width});

  final Color color;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: color, width: 1.2),
            bottom: BorderSide(color: color, width: 1.2),
          ),
        ),
      ),
    );
  }
}

/// A total figure with a label above and a double rule beneath.
class TotalFigure extends StatelessWidget {
  const TotalFigure({
    super.key,
    required this.label,
    required this.amount,
    this.color = Palette.ink,
    this.size = 22,
    this.alignEnd = false,
  });

  final String label;
  final int amount;
  final Color color;
  final double size;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label ${naira(amount)}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: alignEnd
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label.toUpperCase(), style: Fonts.label(color: color)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              naira(amount),
              maxLines: 1,
              style: Fonts.figure(size, color: color).copyWith(
                decoration: TextDecoration.underline,
                decorationStyle: TextDecorationStyle.double,
                decorationColor: color,
                decorationThickness: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LocalModeBanner extends StatelessWidget {
  const LocalModeBanner({super.key});

  @override
  Widget build(BuildContext context) => const _NoticeBanner(
    icon: Icons.save_outlined,
    message:
        'Saved in this browser only. Export a backup from the menu now and then.',
  );
}

/// Shown while the server can't be reached. Changes wait in memory until the
/// connection returns, so closing the app in the meantime loses them.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) => const _NoticeBanner(
    icon: Icons.cloud_off_outlined,
    message:
        'Can’t reach the server. Keep the app open and your changes will save when it’s back.',
  );
}

class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF3DED6),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: Palette.redRule),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style:
                      Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6E2420),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Asks for a single name. Returns the trimmed name, or null if cancelled.
Future<String?> showNameDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String initial = '',
  String hint = '',
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _EntryForm(
      title: title,
      confirmLabel: confirmLabel,
      initialName: initial,
      nameHint: hint,
      showAmount: false,
    ),
  );
}

typedef EntryInput = ({String name, int amount});

/// Asks for a name and, optionally, an amount in naira.
Future<EntryInput?> showEntryDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String initialName = '',
  int initialAmount = 0,
  bool showAmount = true,
  String? amountNote,
}) {
  return showDialog<EntryInput>(
    context: context,
    builder: (context) => _EntryForm(
      title: title,
      confirmLabel: confirmLabel,
      initialName: initialName,
      initialAmount: initialAmount,
      showAmount: showAmount,
      amountNote: amountNote,
      returnsEntry: true,
    ),
  );
}

class _EntryForm extends StatefulWidget {
  const _EntryForm({
    required this.title,
    required this.confirmLabel,
    required this.initialName,
    required this.showAmount,
    this.initialAmount = 0,
    this.nameHint = '',
    this.amountNote,
    this.returnsEntry = false,
  });

  final String title;
  final String confirmLabel;
  final String initialName;
  final int initialAmount;
  final bool showAmount;
  final String nameHint;
  final String? amountNote;
  final bool returnsEntry;

  @override
  State<_EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends State<_EntryForm> {
  late final _name = TextEditingController(text: widget.initialName);
  late final _amount = TextEditingController(
    text: nairaInput(widget.initialAmount),
  );
  String? _nameError;
  String? _amountError;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    final amount = widget.showAmount ? parseNaira(_amount.text) : 0;
    setState(() {
      _nameError = name.isEmpty ? 'Enter a name.' : null;
      _amountError = amount == null
          ? 'Enter a number, like 12500 or 12,500.50.'
          : null;
    });
    if (_nameError != null || _amountError != null) return;
    Navigator.of(context).pop(
      widget.returnsEntry
          ? (
              name: name,
              amount: widget.showAmount ? amount! : widget.initialAmount,
            )
          : name,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: widget.showAmount
                  ? TextInputAction.next
                  : TextInputAction.done,
              onSubmitted: widget.showAmount ? null : (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Name',
                hintText: widget.nameHint.isEmpty ? null : widget.nameHint,
                errorText: _nameError,
              ),
            ),
            if (widget.showAmount) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,₦ ]')),
                ],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                style: Fonts.figure(16),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₦ ',
                  prefixStyle: Fonts.figure(16, color: Palette.muted),
                  errorText: _amountError,
                ),
              ),
            ],
            if (widget.amountNote != null) ...[
              const SizedBox(height: 12),
              Text(
                widget.amountNote!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Palette.muted),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = true,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: Palette.redRule)
              : null,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
