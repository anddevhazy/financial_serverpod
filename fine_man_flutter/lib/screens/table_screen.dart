import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/ledger_repository.dart';
import '../format.dart';
import '../models/ledger.dart';
import '../theme.dart';
import '../widgets/column_sheet.dart';
import '../widgets/common.dart';
import 'entries_screen.dart';
import 'notes_screen.dart';

/// Columns never get narrower than this; below it the table scrolls sideways.
const _minColumnWidth = 210.0;

class TableScreen extends StatefulWidget {
  const TableScreen({super.key, required this.repo, required this.tableId});

  final LedgerRepository repo;
  final String tableId;

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  late final Stream<LedgerTable?> _table = widget.repo.watchTable(
    widget.tableId,
  );

  Future<void> _rename(LedgerTable table) async {
    final name = await showNameDialog(
      context,
      title: 'Rename table',
      confirmLabel: 'Rename',
      initial: table.name,
    );
    if (name != null) widget.repo.renameTable(table.id, name);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<LedgerTable?>(
      stream: _table,
      builder: (context, snap) {
        if (snap.hasError) {
          return _Scaffold(child: Center(child: Text('${snap.error}')));
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const _Scaffold(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final table = snap.data;
        if (table == null) {
          return const _Scaffold(
            child: Center(child: Text('This table no longer exists.')),
          );
        }

        final narrow = MediaQuery.sizeOf(context).width < 600;
        final gutter = narrow ? 8.0 : 16.0;
        return _Scaffold(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TableHeader(
                  table: table,
                  narrow: narrow,
                  onRename: () => _rename(table),
                  onOpenNotes: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          NotesScreen(repo: widget.repo, tableId: table.id),
                    ),
                  ),
                  onOpenList: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          EntriesScreen(repo: widget.repo, tableId: table.id),
                    ),
                  ),
                ),
                _LedgerGrid(table: table, repo: widget.repo),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// All five columns on one sheet: a header row across the top, rows
/// below, and a divider between every column.
class _LedgerGrid extends StatefulWidget {
  const _LedgerGrid({required this.table, required this.repo});

  final LedgerTable table;
  final LedgerRepository repo;

  @override
  State<_LedgerGrid> createState() => _LedgerGridState();
}

class _LedgerGridState extends State<_LedgerGrid> {
  final _horizontal = ScrollController();

  /// Entries whose sub-entries are shown; all start closed.
  final _expanded = <String>{};

  @override
  void dispose() {
    _horizontal.dispose();
    super.dispose();
  }

  void _toggle(String entryId) => setState(() {
    if (!_expanded.remove(entryId)) _expanded.add(entryId);
  });

  @override
  Widget build(BuildContext context) {
    const columns = LedgerColumn.values;
    final table = widget.table;

    // Every column draws the same number of rows, like a spreadsheet, with
    // a few spare rows below the longest one.
    var rowCount = 12;
    for (final c in columns) {
      rowCount = math.max(rowCount, rowsIn(table, c, _expanded) + 3);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // The sheet's 1px border sits outside the columns.
        final inner = constraints.maxWidth - 2;
        final fits = inner >= _minColumnWidth * columns.length;
        final columnWidth = fits ? inner / columns.length : _minColumnWidth;
        final amountWidths = {
          for (final c in columns)
            c: amountWidthFor(
              context,
              table,
              c,
              maxWidth: maxAmountWidthFor(columnWidth),
            ),
        };

        Widget cells(Widget Function(LedgerColumn c) build) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final c in columns)
              SizedBox(width: columnWidth, child: build(c)),
          ],
        );

        final sheet = Container(
          decoration: BoxDecoration(
            color: Palette.sheet,
            border: Border.all(color: Palette.grid),
          ),
          child: SizedBox(
            width: columnWidth * columns.length,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    cells(
                      (c) => ColumnHeader(
                        column: c,
                        total: table.columnTotal(c),
                        count: table.entriesIn(c).length,
                        amountWidth: amountWidths[c]!,
                      ),
                    ),
                    Container(height: 1, color: Palette.grid),
                    cells(
                      (c) => ColumnEntries(
                        table: table,
                        column: c,
                        repo: widget.repo,
                        amountWidth: amountWidths[c]!,
                        expanded: _expanded,
                        onToggle: _toggle,
                        rowCount: rowCount,
                      ),
                    ),
                  ],
                ),
                // Full-height drop zones that also draw the column dividers.
                Positioned.fill(
                  child: Row(
                    children: [
                      for (var i = 0; i < columns.length; i++)
                        SizedBox(
                          width: columnWidth,
                          child: ColumnDropZone(
                            column: columns[i],
                            showDivider: i > 0,
                            onMove: (entryId, from) => widget.repo.saveColumns(
                              table.moveEntry(entryId, from, columns[i]),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

        if (fits) return sheet;
        return Scrollbar(
          controller: _horizontal,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _horizontal,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 14),
            child: sheet,
          ),
        );
      },
    );
  }
}

class _Scaffold extends StatelessWidget {
  const _Scaffold({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(body: SafeArea(child: child));
}

/// A compact bar above the sheet: back, the table's name and creation
/// date, and the grand total.
class _TableHeader extends StatelessWidget {
  const _TableHeader({
    required this.table,
    required this.narrow,
    required this.onRename,
    required this.onOpenNotes,
    required this.onOpenList,
  });

  final LedgerTable table;
  final bool narrow;
  final VoidCallback onRename;
  final VoidCallback onOpenNotes;
  final VoidCallback onOpenList;

  @override
  Widget build(BuildContext context) {
    final title = Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'All tables',
          icon: const Icon(Icons.arrow_back, size: 20, color: Palette.muted),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      table.name,
                      overflow: TextOverflow.ellipsis,
                      style: Fonts.display(20),
                    ),
                  ),
                  IconButton(
                    onPressed: onRename,
                    tooltip: 'Rename table',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: Palette.muted,
                    ),
                  ),
                ],
              ),
              Text(
                createdLabel(table.createdAt),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Palette.muted),
              ),
            ],
          ),
        ),
      ],
    );
    final notes = TextButton.icon(
      onPressed: onOpenNotes,
      icon: Icon(
        table.hasNotes ? Icons.sticky_note_2_outlined : Icons.add,
        size: 18,
      ),
      label: Text(table.hasNotes ? 'Notes' : 'Add notes'),
      style: TextButton.styleFrom(foregroundColor: Palette.ink),
    );
    final list = TextButton.icon(
      onPressed: onOpenList,
      icon: const Icon(Icons.view_list_outlined, size: 18),
      label: const Text('All entries'),
      style: TextButton.styleFrom(foregroundColor: Palette.ink),
    );
    final buttons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [list, const SizedBox(width: 4), notes],
    );

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                Padding(
                  padding: const EdgeInsets.only(left: 44, top: 2),
                  child: buttons,
                ),
              ],
            )
          : Row(
              children: [
                Expanded(child: title),
                const SizedBox(width: 24),
                buttons,
              ],
            ),
    );
  }
}
