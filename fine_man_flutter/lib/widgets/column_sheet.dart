import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/ledger_repository.dart';
import '../format.dart';
import '../models/ledger.dart';
import '../theme.dart';
import 'common.dart';

/// Every row of the sheet is this tall, so rows line up across columns.
const rowHeight = 28.0;

/// Height of the header row with each column's name and total.
const headerHeight = 32.0;

/// Horizontal padding inside a cell.
const _cellPadding = 8.0;

/// Extra indent for a sub-entry's name.
const _subIndent = 18.0;

/// What travels with an entry while it is dragged towards another column.
typedef EntryDrag = ({String entryId, LedgerColumn from});

/// How many rows [column] shows: its entries, the open entries'
/// sub-entries, and the row for adding an entry.
int rowsIn(LedgerTable table, LedgerColumn column, Set<String> expanded) {
  var rows = 1;
  for (final e in table.entriesIn(column)) {
    rows += 1;
    if (expanded.contains(e.id)) rows += e.subs.length;
  }
  return rows;
}

/// The width of [column]'s amount cells: just wide enough for its longest
/// amount (including the total in the header), but never more than
/// [maxWidth]. Every row shares it, so amounts line up.
double amountWidthFor(
  BuildContext context,
  LedgerTable table,
  LedgerColumn column, {
  required double maxWidth,
}) => _amountWidth(
  context,
  table.entriesIn(column),
  total: table.columnTotal(column),
  maxWidth: maxWidth,
);

/// The width of the amount cells for [entries] (and [total], when given):
/// just wide enough for the longest amount, but never more than [maxWidth].
double _amountWidth(
  BuildContext context,
  List<Entry> entries, {
  int? total,
  required double maxWidth,
}) {
  final scale = MediaQuery.textScalerOf(context);
  double widest = 0;
  void measure(int amount, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: naira(amount), style: style),
      textDirection: TextDirection.ltr,
      textScaler: scale,
    )..layout();
    widest = math.max(widest, painter.width);
    painter.dispose();
  }

  final bold = Fonts.figure(13, weight: FontWeight.w600);
  if (total != null) measure(total, bold);
  for (final e in entries) {
    measure(e.total, bold);
    for (final s in e.subs) {
      measure(s.amount, Fonts.figure(13));
    }
  }
  // A little slack covers the web font arriving after the first frame.
  return (widest + _cellPadding * 2 + 6).clamp(56.0, maxWidth);
}

/// The most room the amount cells may take in a column [columnWidth] wide;
/// larger amounts shrink to fit.
double maxAmountWidthFor(double columnWidth) => columnWidth * 0.4;

/// A column's header cell: a colour dot and its name, with the column
/// total above its amounts.
class ColumnHeader extends StatelessWidget {
  const ColumnHeader({
    super.key,
    required this.column,
    required this.total,
    required this.count,
    required this.amountWidth,
  });

  final LedgerColumn column;
  final int total;
  final int count;
  final double amountWidth;

  @override
  Widget build(BuildContext context) {
    final accent = Palette.of(column);
    return Tooltip(
      message: count == 1 ? '1 entry' : '$count entries',
      waitDuration: const Duration(milliseconds: 800),
      child: Container(
        height: headerHeight,
        color: Palette.headerFill,
        child: Row(
          children: [
            const SizedBox(width: _cellPadding),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                column.label.toUpperCase(),
                overflow: TextOverflow.ellipsis,
                style: Fonts.label(color: accent, size: 11.5),
              ),
            ),
            const _CellDivider(),
            SizedBox(
              width: amountWidth,
              child: _AmountText(
                naira(total),
                Fonts.figure(13, weight: FontWeight.w600, color: accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The rows of one column (e.g. Need) inside the shared sheet.
class ColumnEntries extends StatelessWidget {
  const ColumnEntries({
    super.key,
    required this.table,
    required this.column,
    required this.repo,
    required this.amountWidth,
    required this.expanded,
    required this.onToggle,
    required this.rowCount,
  });

  final LedgerTable table;
  final LedgerColumn column;
  final LedgerRepository repo;
  final double amountWidth;

  /// Ids of entries whose sub-entries are shown.
  final Set<String> expanded;
  final ValueChanged<String> onToggle;

  /// Total rows to draw, padding with empty rows so every column of the
  /// sheet is the same height.
  final int rowCount;

  void _save(BuildContext context, LedgerTable next, {String? undoMessage}) {
    final previous = table;
    repo.saveColumns(next);
    if (undoMessage == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(undoMessage),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => repo.saveColumns(previous),
          ),
        ),
      );
  }

  Widget _entry(BuildContext context, Entry entry, int index) {
    return _EntryBlock(
      key: ValueKey(entry.id),
      index: index,
      column: column,
      entry: entry,
      amountWidth: amountWidth,
      expanded: expanded.contains(entry.id),
      onToggle: () => onToggle(entry.id),
      onEdit: () async {
        final input = await showEntryDialog(
          context,
          title: 'Edit entry',
          confirmLabel: 'Save changes',
          initialName: entry.name,
          initialAmount: entry.amount,
          showAmount: !entry.hasSubs,
          amountNote: entry.hasSubs
              ? 'The amount is the sum of its ${entry.subs.length} sub-entries.'
              : null,
        );
        if (input == null || !context.mounted) return;
        _save(
          context,
          table.updateEntry(
            column,
            entry.id,
            name: input.name,
            amount: input.amount,
          ),
        );
      },
      onDelete: () => _save(
        context,
        table.removeEntry(column, entry.id),
        undoMessage: 'Deleted “${entry.name}”',
      ),
      onAddSub: () async {
        final input = await showEntryDialog(
          context,
          title: 'Add sub-entry to ${entry.name}',
          confirmLabel: 'Add sub-entry',
          amountNote: entry.hasSubs
              ? null
              : '“${entry.name}” will show the sum of its sub-entries from now on.',
        );
        if (input == null || !context.mounted) return;
        if (!expanded.contains(entry.id)) onToggle(entry.id);
        _save(
          context,
          table.addSub(
            column,
            entry.id,
            SubEntry(id: newId(), name: input.name, amount: input.amount),
          ),
        );
      },
      onEditSub: (sub) async {
        final input = await showEntryDialog(
          context,
          title: 'Edit sub-entry',
          confirmLabel: 'Save changes',
          initialName: sub.name,
          initialAmount: sub.amount,
        );
        if (input == null || !context.mounted) return;
        _save(
          context,
          table.updateSub(
            column,
            entry.id,
            sub.id,
            name: input.name,
            amount: input.amount,
          ),
        );
      },
      onDeleteSub: (sub) => _save(
        context,
        table.removeSub(column, entry.id, sub.id),
        undoMessage: 'Deleted “${sub.name}”',
      ),
      onReorderSubs: (oldIndex, newIndex) => _save(
        context,
        table.reorderSub(column, entry.id, oldIndex, newIndex),
      ),
      onRename: (name) =>
          _save(context, table.updateEntry(column, entry.id, name: name)),
      onAmount: (amount) =>
          _save(context, table.updateEntry(column, entry.id, amount: amount)),
      onRenameSub: (sub, name) =>
          _save(context, table.updateSub(column, entry.id, sub.id, name: name)),
      onSubAmount: (sub, amount) => _save(
        context,
        table.updateSub(column, entry.id, sub.id, amount: amount),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = table.entriesIn(column);
    final used = rowsIn(table, column, expanded);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (entries.isNotEmpty)
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            // Reordering starts only from the grip; dragging the rest of
            // the row moves the entry to another column instead.
            buildDefaultDragHandles: false,
            proxyDecorator: _liftedRow,
            itemCount: entries.length,
            onReorder: (oldIndex, newIndex) =>
                _save(context, table.reorderEntry(column, oldIndex, newIndex)),
            itemBuilder: (context, i) => _entry(context, entries[i], i),
          ),
        // Keyed so it keeps its typing state when the first entry
        // appears above it.
        _AddRow(
          key: const ValueKey('add-row'),
          column: column,
          amountWidth: amountWidth,
          onAdd: (name) => _save(
            context,
            table.addEntry(column, Entry(id: newId(), name: name)),
          ),
        ),
        for (var i = used; i < rowCount; i++)
          _EmptyRow(amountWidth: amountWidth),
      ],
    );
  }
}

/// Covers a whole column of the sheet and accepts entries dragged from
/// other columns. Paints the hover highlight and, unless it is the first
/// column, the divider on its left edge.
class ColumnDropZone extends StatelessWidget {
  const ColumnDropZone({
    super.key,
    required this.column,
    required this.showDivider,
    required this.onMove,
  });

  final LedgerColumn column;
  final bool showDivider;
  final void Function(String entryId, LedgerColumn from) onMove;

  @override
  Widget build(BuildContext context) {
    final accent = Palette.of(column);
    return DragTarget<EntryDrag>(
      onWillAcceptWithDetails: (d) => d.data.from != column,
      onAcceptWithDetails: (d) => onMove(d.data.entryId, d.data.from),
      builder: (context, candidates, _) {
        final hovering = candidates.isNotEmpty;
        // IgnorePointer keeps taps and scrolls going to the cells below;
        // the drag target still sees the dragged entry.
        return IgnorePointer(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: hovering ? accent.withValues(alpha: 0.08) : null,
              border: Border(
                left: showDivider
                    ? const BorderSide(color: Palette.grid)
                    : BorderSide.none,
              ),
            ),
            foregroundDecoration: hovering
                ? BoxDecoration(border: Border.all(color: accent, width: 2))
                : null,
          ),
        );
      },
    );
  }
}

/// Need, Work, Want and Luxury entries as one plain, read-only list. Its
/// grips reorder the list without touching the sheet; entries with
/// sub-entries open to show them.
class EntryList extends StatefulWidget {
  const EntryList({super.key, required this.table, required this.repo});

  final LedgerTable table;
  final LedgerRepository repo;

  @override
  State<EntryList> createState() => _EntryListState();
}

class _EntryListState extends State<EntryList> {
  /// Entries whose sub-entries are shown; all start closed.
  final _expanded = <String>{};

  void _toggle(String entryId) => setState(() {
    if (!_expanded.remove(entryId)) _expanded.add(entryId);
  });

  Widget _row(
    BuildContext context, {
    required String name,
    required int amount,
    required double amountWidth,
    required List<Widget> leading,
    bool isSub = false,
    bool bold = false,
  }) {
    final weight = bold ? FontWeight.w600 : FontWeight.w400;
    final color = isSub ? Palette.muted : null;
    return Container(
      height: rowHeight,
      decoration: BoxDecoration(
        color: isSub ? const Color(0xFFFAFAFB) : Palette.sheet,
        border: _rowBorder,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...leading,
          if (leading.length < 2) const SizedBox(width: 2),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  fontWeight: weight,
                  color: color,
                ),
              ),
            ),
          ),
          const _CellDivider(),
          SizedBox(
            width: amountWidth,
            child: _AmountText(
              naira(amount),
              Fonts.figure(13, weight: weight, color: color ?? Palette.ink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _entry(BuildContext context, Entry entry, int index, double width) {
    final open = entry.hasSubs && _expanded.contains(entry.id);
    return Column(
      key: ValueKey(entry.id),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _row(
          context,
          name: entry.name,
          amount: entry.total,
          amountWidth: width,
          bold: entry.hasSubs,
          leading: [
            _DragHandle(index: index, visible: true),
            if (entry.hasSubs)
              _Chevron(expanded: open, onPressed: () => _toggle(entry.id)),
          ],
        ),
        if (open)
          for (final sub in entry.subs)
            _row(
              context,
              name: sub.name,
              amount: sub.amount,
              amountWidth: width,
              isSub: true,
              leading: const [SizedBox(width: 18 + _subIndent)],
            ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final table = widget.table;
    final entries = table.listEntries;
    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No entries in Need, Work, Want or Luxury yet.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Palette.muted),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = _amountWidth(
          context,
          entries,
          maxWidth: maxAmountWidthFor(constraints.maxWidth),
        );
        return ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          proxyDecorator: _liftedRow,
          itemCount: entries.length,
          onReorder: (oldIndex, newIndex) =>
              widget.repo.saveListOrder(table.reorderList(oldIndex, newIndex)),
          itemBuilder: (context, i) => _entry(context, entries[i], i, width),
        );
      },
    );
  }
}

class _EntryBlock extends StatefulWidget {
  const _EntryBlock({
    super.key,
    required this.index,
    required this.column,
    required this.entry,
    required this.amountWidth,
    required this.expanded,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onAddSub,
    required this.onEditSub,
    required this.onDeleteSub,
    required this.onReorderSubs,
    required this.onRename,
    required this.onAmount,
    required this.onRenameSub,
    required this.onSubAmount,
  });

  /// Position in the column, for the reorder grip.
  final int index;
  final LedgerColumn column;
  final Entry entry;
  final double amountWidth;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddSub;
  final ValueChanged<SubEntry> onEditSub;
  final ValueChanged<SubEntry> onDeleteSub;
  final ReorderCallback onReorderSubs;
  final ValueChanged<String> onRename;
  final ValueChanged<int> onAmount;
  final void Function(SubEntry sub, String name) onRenameSub;
  final void Function(SubEntry sub, int amount) onSubAmount;

  @override
  State<_EntryBlock> createState() => _EntryBlockState();
}

class _EntryBlockState extends State<_EntryBlock> {
  /// True while the entry row's name or amount is being typed into; the
  /// row can't be dragged to another column then, so text selection works.
  bool _editingRow = false;

  Widget _entryRow(BuildContext context) {
    final entry = widget.entry;
    return _LedgerRow(
      amountWidth: widget.amountWidth,
      accent: Palette.of(widget.column),
      gripIndex: widget.index,
      leading: [
        if (entry.hasSubs)
          _Chevron(expanded: widget.expanded, onPressed: widget.onToggle),
      ],
      name: entry.name,
      nameStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontSize: 13,
        fontWeight: entry.hasSubs ? FontWeight.w600 : FontWeight.w400,
      ),
      onRename: widget.onRename,
      onEditingChanged: (editing) => setState(() => _editingRow = editing),
      menu: _RowMenu(
        label: entry.name,
        items: [
          ('Edit', Icons.edit_outlined, widget.onEdit),
          ('Delete', Icons.delete_outline, widget.onDelete),
        ],
      ),
      actions: [
        _RowIconButton(
          icon: Icons.subdirectory_arrow_right,
          tooltip: 'Add sub-entry to ${entry.name}',
          onPressed: widget.onAddSub,
        ),
      ],
      amount: entry.total,
      amountStyle: Fonts.figure(
        13,
        weight: entry.hasSubs ? FontWeight.w600 : FontWeight.w400,
      ),
      // An entry with sub-entries shows their sum, which isn't typed in.
      onAmount: entry.hasSubs ? null : widget.onAmount,
    );
  }

  /// The entry row, draggable onto another column.
  Widget _movableEntryRow(BuildContext context) {
    final row = _entryRow(context);
    final data = (entryId: widget.entry.id, from: widget.column);
    final feedback = _DragFeedback(
      name: widget.entry.name,
      amount: widget.entry.total,
      accent: Palette.of(widget.column),
    );
    final whileDragging = Opacity(opacity: 0.35, child: row);

    // On touch screens an immediate drag would fight the page scroll, so
    // moving to another column needs a long press there.
    if (_isTouch(Theme.of(context).platform)) {
      return LongPressDraggable<EntryDrag>(
        data: data,
        maxSimultaneousDrags: _editingRow ? 0 : null,
        feedback: feedback,
        childWhenDragging: whileDragging,
        child: row,
      );
    }
    return Draggable<EntryDrag>(
      data: data,
      maxSimultaneousDrags: _editingRow ? 0 : null,
      feedback: feedback,
      childWhenDragging: whileDragging,
      child: row,
    );
  }

  Widget _subRow(BuildContext context, SubEntry sub, int index) {
    return _LedgerRow(
      key: ValueKey(sub.id),
      amountWidth: widget.amountWidth,
      accent: Palette.of(widget.column),
      isSub: true,
      gripIndex: index,
      leading: const [],
      name: sub.name,
      nameStyle: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(fontSize: 13, color: Palette.muted),
      onRename: (name) => widget.onRenameSub(sub, name),
      menu: _RowMenu(
        label: sub.name,
        items: [
          ('Edit', Icons.edit_outlined, () => widget.onEditSub(sub)),
          ('Delete', Icons.delete_outline, () => widget.onDeleteSub(sub)),
        ],
      ),
      amount: sub.amount,
      amountStyle: Fonts.figure(13, color: Palette.muted),
      onAmount: (amount) => widget.onSubAmount(sub, amount),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _movableEntryRow(context),
        if (entry.hasSubs && widget.expanded)
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            proxyDecorator: _liftedRow,
            itemCount: entry.subs.length,
            onReorder: widget.onReorderSubs,
            itemBuilder: (context, i) => _subRow(context, entry.subs[i], i),
          ),
      ],
    );
  }
}

bool _isTouch(TargetPlatform platform) => switch (platform) {
  TargetPlatform.android ||
  TargetPlatform.iOS ||
  TargetPlatform.fuchsia => true,
  TargetPlatform.linux ||
  TargetPlatform.macOS ||
  TargetPlatform.windows => false,
};

/// The thin vertical gridline between a row's name and amount cells.
class _CellDivider extends StatelessWidget {
  const _CellDivider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, color: Palette.rule);
}

/// An amount, right-aligned in its cell and shrunk if it doesn't fit.
class _AmountText extends StatelessWidget {
  const _AmountText(this.text, this.style);

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _cellPadding),
      child: Align(
        alignment: Alignment.centerRight,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(text, style: style),
        ),
      ),
    );
  }
}

/// The grip that starts a reorder of the row at [index] in the nearest
/// reorderable list. Only the grip reorders, so taps and column moves on
/// the rest of the row keep working.
class _DragHandle extends StatelessWidget {
  const _DragHandle({required this.index, required this.visible});

  final int index;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return ReorderableDragStartListener(
      index: index,
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: Tooltip(
          message: 'Drag to reorder',
          child: SizedBox(
            width: 18,
            height: rowHeight,
            child: AnimatedOpacity(
              opacity: visible ? 1 : 0,
              duration: const Duration(milliseconds: 120),
              child: const Icon(
                Icons.drag_handle_rounded,
                size: 16,
                color: Palette.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron({required this.expanded, required this.onPressed});

  final bool expanded;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: expanded ? 'Hide sub-entries' : 'Show sub-entries',
      child: InkResponse(
        onTap: onPressed,
        radius: 12,
        child: SizedBox(
          width: 18,
          height: rowHeight,
          child: AnimatedRotation(
            turns: expanded ? 0 : -0.25,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: const Icon(Icons.expand_more, size: 18),
          ),
        ),
      ),
    );
  }
}

/// The card that follows the pointer while an entry moves between columns.
class _DragFeedback extends StatelessWidget {
  const _DragFeedback({
    required this.name,
    required this.amount,
    required this.accent,
  });

  final String name;
  final int amount;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Palette.sheet,
      elevation: 6,
      shadowColor: Palette.ink.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: accent, width: 1.5),
      ),
      child: Container(
        width: 220,
        height: rowHeight + 4,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontSize: 13),
              ),
            ),
            const SizedBox(width: 12),
            Text(naira(amount), style: Fonts.figure(13)),
          ],
        ),
      ),
    );
  }
}

/// Lifts the row being reordered onto a white card.
Widget _liftedRow(Widget child, int index, Animation<double> animation) {
  return AnimatedBuilder(
    animation: animation,
    builder: (context, child) => Material(
      color: Palette.sheet,
      elevation: 4 * Curves.easeOut.transform(animation.value),
      shadowColor: Palette.ink.withValues(alpha: 0.3),
      child: child,
    ),
    child: child,
  );
}

/// The gridline every row draws along its bottom edge.
const _rowBorder = Border(bottom: BorderSide(color: Palette.rule));

/// A blank row that keeps the grid going below a column's last entry.
class _EmptyRow extends StatelessWidget {
  const _EmptyRow({required this.amountWidth});

  final double amountWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: rowHeight,
      decoration: const BoxDecoration(border: _rowBorder),
      child: Row(
        children: [
          const Spacer(),
          const _CellDivider(),
          SizedBox(width: amountWidth),
        ],
      ),
    );
  }
}

/// The row under a column's entries: click it and type a name to add an
/// entry. Enter adds it and leaves the row ready for the next one.
class _AddRow extends StatefulWidget {
  const _AddRow({
    super.key,
    required this.column,
    required this.amountWidth,
    required this.onAdd,
  });

  final LedgerColumn column;
  final double amountWidth;
  final ValueChanged<String> onAdd;

  @override
  State<_AddRow> createState() => _AddRowState();
}

class _AddRowState extends State<_AddRow> {
  bool _editing = false;

  /// Bumped after each added entry so the field starts empty again.
  int _round = 0;

  @override
  Widget build(BuildContext context) {
    final accent = Palette.of(widget.column);
    final Widget cell = _editing
        ? _InlineField<String>(
            key: ValueKey(_round),
            initial: '',
            hint: 'New entry',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontSize: 13),
            accent: accent,
            parse: (text) => text.trim(),
            onCommit: (name, {required fromEnter}) {
              if (name.isNotEmpty) widget.onAdd(name);
              setState(() {
                _editing = fromEnter && name.isNotEmpty;
                _round++;
              });
            },
            onCancel: () => setState(() => _editing = false),
          )
        : InkWell(
            onTap: () => setState(() => _editing = true),
            mouseCursor: SystemMouseCursors.text,
            child: Padding(
              padding: const EdgeInsets.only(left: _cellPadding),
              child: Row(
                children: [
                  Icon(Icons.add, size: 16, color: accent),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Add entry',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: accent,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );

    return Container(
      height: rowHeight,
      decoration: const BoxDecoration(border: _rowBorder),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: cell),
          const _CellDivider(),
          SizedBox(width: widget.amountWidth),
        ],
      ),
    );
  }
}

/// One row of the sheet: a name cell and an amount cell.
///
/// Clicking the name or the amount edits it in place: Enter or clicking
/// away saves, Esc cancels.
///
/// With a mouse, the grip and the row's buttons ([actions] and [menu])
/// appear while the row is hovered or focused, so names get the full width
/// the rest of the time. On touch screens they are always shown.
class _LedgerRow extends StatefulWidget {
  const _LedgerRow({
    super.key,
    required this.amountWidth,
    required this.accent,
    required this.gripIndex,
    required this.leading,
    required this.name,
    required this.nameStyle,
    required this.onRename,
    required this.amount,
    required this.amountStyle,
    required this.onAmount,
    this.isSub = false,
    this.onEditingChanged,
    this.menu,
    this.actions = const [],
  });

  final double amountWidth;
  final Color accent;

  /// Position in the nearest reorderable list, for the grip.
  final int gripIndex;

  /// Shown between the grip and the name, e.g. the chevron.
  final List<Widget> leading;
  final String name;
  final TextStyle? nameStyle;
  final ValueChanged<String> onRename;
  final int amount;
  final TextStyle amountStyle;

  /// Saves a typed amount. Null when the amount can't be typed in.
  final ValueChanged<int>? onAmount;

  /// Sub-entries sit on a tinted row with their name indented.
  final bool isSub;

  /// Told when the name or amount starts or stops being edited.
  final ValueChanged<bool>? onEditingChanged;
  final Widget? menu;

  /// Buttons shown just before [menu].
  final List<Widget> actions;

  @override
  State<_LedgerRow> createState() => _LedgerRowState();
}

enum _Cell { name, amount }

class _LedgerRowState extends State<_LedgerRow> {
  bool _hovered = false;
  bool _focused = false;
  _Cell? _editing;

  void _startEditing(_Cell cell) {
    setState(() => _editing = cell);
    widget.onEditingChanged?.call(true);
  }

  void _stopEditing() {
    if (!mounted) return;
    setState(() => _editing = null);
    widget.onEditingChanged?.call(false);
  }

  Widget _nameCell() {
    if (_editing == _Cell.name) {
      return _InlineField<String>(
        initial: widget.name,
        style: widget.nameStyle,
        accent: widget.accent,
        hint: 'Name',
        parse: (text) => text.trim().isEmpty ? null : text.trim(),
        onCommit: (name, {required fromEnter}) {
          if (name != widget.name) widget.onRename(name);
          _stopEditing();
        },
        onCancel: _stopEditing,
      );
    }
    Widget text = Text(
      widget.name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: widget.nameStyle,
    );
    // Hovering shows a name that doesn't fit. On touch screens a tooltip
    // would claim the long press that moves the row, so it's left off.
    if (!_isTouch(Theme.of(context).platform)) {
      text = Tooltip(
        message: widget.name,
        waitDuration: const Duration(milliseconds: 800),
        child: text,
      );
    }
    return InkWell(
      onTap: () => _startEditing(_Cell.name),
      mouseCursor: SystemMouseCursors.text,
      child: Align(alignment: Alignment.centerLeft, child: text),
    );
  }

  Widget _amountCell() {
    if (_editing == _Cell.amount) {
      return _InlineField<int>(
        initial: nairaInput(widget.amount),
        style: widget.amountStyle,
        accent: widget.accent,
        hint: 'Amount',
        textAlign: TextAlign.end,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,₦ ]')),
        ],
        parse: parseNaira,
        onCommit: (amount, {required fromEnter}) {
          if (amount != widget.amount) widget.onAmount!(amount);
          _stopEditing();
        },
        onCancel: _stopEditing,
      );
    }
    final figure = _AmountText(naira(widget.amount), widget.amountStyle);
    if (widget.onAmount == null) {
      return Tooltip(message: 'Total of its sub-entries', child: figure);
    }
    return InkWell(
      onTap: () => _startEditing(_Cell.amount),
      mouseCursor: SystemMouseCursors.text,
      child: figure,
    );
  }

  @override
  Widget build(BuildContext context) {
    final rowColor = widget.isSub ? const Color(0xFFFAFAFB) : Palette.sheet;
    final buttons = [...widget.actions, ?widget.menu];
    final alwaysShow = _isTouch(Theme.of(context).platform);
    final active = alwaysShow || _hovered || _focused;
    final showButtons = _editing != _Cell.name && active;

    final nameRow = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DragHandle(index: widget.gripIndex, visible: active),
        if (widget.isSub) const SizedBox(width: _subIndent),
        ...widget.leading,
        if (widget.leading.isEmpty) const SizedBox(width: 2),
        Expanded(child: _nameCell()),
        if (alwaysShow && _editing != _Cell.name) ...buttons,
      ],
    );

    Widget nameArea = nameRow;
    if (!alwaysShow && buttons.isNotEmpty) {
      nameArea = Stack(
        children: [
          Positioned.fill(child: nameRow),
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: showButtons ? 1 : 0,
              duration: const Duration(milliseconds: 120),
              child: IgnorePointer(
                ignoring: !showButtons,
                child: Container(
                  padding: const EdgeInsets.only(left: 14),
                  // Fades the name out under the buttons.
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [rowColor.withValues(alpha: 0), rowColor],
                      stops: const [0, 0.35],
                    ),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: buttons),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: (focused) => setState(() => _focused = focused),
        child: Container(
          height: rowHeight,
          decoration: BoxDecoration(color: rowColor, border: _rowBorder),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: nameArea),
              const _CellDivider(),
              SizedBox(width: widget.amountWidth, child: _amountCell()),
            ],
          ),
        ),
      ),
    );
  }
}

/// A cell being typed into, outlined like a selected spreadsheet cell.
/// [parse] turns the text into a value, or returns null when it isn't
/// valid; invalid text can't be saved with Enter and is dropped when focus
/// leaves.
class _InlineField<T> extends StatefulWidget {
  const _InlineField({
    super.key,
    required this.initial,
    required this.hint,
    required this.style,
    required this.accent,
    required this.parse,
    required this.onCommit,
    required this.onCancel,
    this.textAlign = TextAlign.start,
    this.keyboardType,
    this.inputFormatters,
  });

  final String initial;
  final String hint;
  final TextStyle? style;
  final Color accent;
  final T? Function(String text) parse;

  /// Saves the value. [fromEnter] is true when Enter was pressed, false
  /// when focus moved away.
  final void Function(T value, {required bool fromEnter}) onCommit;
  final VoidCallback onCancel;
  final TextAlign textAlign;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<_InlineField<T>> createState() => _InlineFieldState<T>();
}

class _InlineFieldState<T> extends State<_InlineField<T>> {
  late final _controller = TextEditingController(text: widget.initial)
    ..selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.initial.length,
    );
  final _focus = FocusNode();
  bool _invalid = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      // Clicking away saves valid text and drops invalid text.
      if (!_focus.hasFocus) _finish(fromEnter: false);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _cancel() {
    if (_finished) return;
    _finished = true;
    widget.onCancel();
  }

  void _finish({required bool fromEnter}) {
    if (_finished) return;
    final value = widget.parse(_controller.text);
    if (value == null) {
      if (fromEnter) {
        // Keep the cell open so the mistake can be fixed.
        setState(() => _invalid = true);
        _focus.requestFocus();
      } else {
        _cancel();
      }
      return;
    }
    _finished = true;
    widget.onCommit(value, fromEnter: fromEnter);
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): _cancel},
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: _invalid ? Palette.redRule : widget.accent,
            width: 2,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: _cellPadding - 2),
        alignment: Alignment.center,
        child: TextField(
          controller: _controller,
          focusNode: _focus,
          autofocus: true,
          style: widget.style,
          textAlign: widget.textAlign,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          textInputAction: TextInputAction.done,
          onChanged: (_) {
            if (_invalid) setState(() => _invalid = false);
          },
          onSubmitted: (_) => _finish(fromEnter: true),
          decoration: _borderless(
            hintText: widget.hint,
            hintStyle: widget.style?.copyWith(color: Palette.grid),
          ),
        ),
      ),
    );
  }
}

/// A compact icon button sized to fit a sheet row.
class _RowIconButton extends StatelessWidget {
  const _RowIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: 16, color: Palette.muted),
      style: IconButton.styleFrom(
        minimumSize: const Size(24, rowHeight),
        maximumSize: const Size(24, rowHeight),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

typedef _MenuItem = (String, IconData, VoidCallback);

class _RowMenu extends StatelessWidget {
  const _RowMenu({required this.label, required this.items});

  final String label;
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      constraints: const BoxConstraints(minWidth: 160),
      style: IconButton.styleFrom(
        minimumSize: const Size(24, rowHeight),
        maximumSize: const Size(24, rowHeight),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      tooltip: 'Actions for $label',
      icon: const Icon(Icons.more_horiz, size: 18, color: Palette.muted),
      padding: EdgeInsets.zero,
      onSelected: (i) => items[i].$3(),
      itemBuilder: (context) => [
        for (var i = 0; i < items.length; i++)
          PopupMenuItem(
            value: i,
            height: 40,
            child: Row(
              children: [
                Icon(
                  items[i].$2,
                  size: 18,
                  color: items[i].$1 == 'Delete'
                      ? Palette.redRule
                      : Palette.muted,
                ),
                const SizedBox(width: 12),
                Text(
                  items[i].$1,
                  style: items[i].$1 == 'Delete'
                      ? const TextStyle(color: Palette.redRule)
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A text field decoration with no box at all. The app theme gives text
/// fields an outlined, filled box, which the collapsed decoration alone
/// doesn't switch off.
InputDecoration _borderless({String? hintText, TextStyle? hintStyle}) =>
    InputDecoration(
      isCollapsed: true,
      filled: false,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      contentPadding: EdgeInsets.zero,
      hintText: hintText,
      hintStyle: hintStyle,
    );
