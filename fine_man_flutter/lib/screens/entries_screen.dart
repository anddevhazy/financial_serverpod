import 'package:flutter/material.dart';

import '../data/ledger_repository.dart';
import '../models/ledger.dart';
import '../theme.dart';
import '../widgets/column_sheet.dart';

/// One table's Need, Work, Want and Luxury entries as a single list.
class EntriesScreen extends StatefulWidget {
  const EntriesScreen({super.key, required this.repo, required this.tableId});

  final LedgerRepository repo;
  final String tableId;

  @override
  State<EntriesScreen> createState() => _EntriesScreenState();
}

class _EntriesScreenState extends State<EntriesScreen> {
  late final Stream<LedgerTable?> _table = widget.repo.watchTable(
    widget.tableId,
  );

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<LedgerTable?>(
          stream: _table,
          builder: (context, snap) {
            final table = snap.data;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                narrow ? 8 : 16,
                8,
                narrow ? 8 : 16,
                48,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _header(table),
                      const SizedBox(height: 12),
                      if (table != null)
                        Container(
                          decoration: BoxDecoration(
                            color: Palette.sheet,
                            border: Border.all(color: Palette.grid),
                          ),
                          child: EntryList(table: table, repo: widget.repo),
                        )
                      else if (snap.connectionState == ConnectionState.waiting)
                        const Center(child: CircularProgressIndicator())
                      else
                        const Center(
                          child: Text('This table no longer exists.'),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _header(LedgerTable? table) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: table == null ? 'Back' : 'Back to ${table.name}',
          icon: const Icon(Icons.arrow_back, size: 20, color: Palette.muted),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('All entries', style: Fonts.display(20)),
              if (table != null)
                Text(
                  table.name,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Palette.muted),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
