import 'package:flutter/material.dart';

import '../data/backup.dart';
import '../data/file_io.dart';
import '../data/ledger_repository.dart';
import '../format.dart';
import '../models/ledger.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'table_screen.dart';

/// Lists every table, newest first.
class TablesScreen extends StatefulWidget {
  const TablesScreen({
    super.key,
    required this.repo,
    this.moveFrom,
    this.onSignOut,
  });

  final LedgerRepository repo;

  /// Tables saved in this browser that can be moved into [repo].
  final LocalLedgerRepository? moveFrom;
  final VoidCallback? onSignOut;

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  late Stream<List<LedgerTable>> _tables = widget.repo.watchTables();
  late Stream<List<LedgerTable>>? _localTables = widget.moveFrom?.watchTables();
  bool _moving = false;

  @override
  void didUpdateWidget(TablesScreen old) {
    super.didUpdateWidget(old);
    if (old.repo != widget.repo) _tables = widget.repo.watchTables();
    if (old.moveFrom != widget.moveFrom) {
      _localTables = widget.moveFrom?.watchTables();
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _tablesCount(int n) => n == 1 ? '1 table' : '$n tables';

  Future<void> _export() async {
    final tables = await widget.repo.allTables();
    if (tables.isEmpty) {
      _toast('There are no tables to export yet.');
      return;
    }
    await downloadTextFile(backupFileName(), encodeBackup(tables));
    _toast('Exported ${_tablesCount(tables.length)}.');
  }

  Future<void> _import() async {
    final text = await pickTextFile();
    if (text == null || !mounted) return;
    final List<LedgerTable> tables;
    try {
      tables = decodeBackup(text);
    } on FormatException catch (e) {
      _toast('Couldn’t import: ${e.message}');
      return;
    }
    final confirmed = await showConfirmDialog(
      context,
      title: 'Import ${_tablesCount(tables.length)}?',
      message:
          'Tables from this backup are added to your list. '
          'If a table from the file is already here, the file’s copy replaces it.',
      confirmLabel: 'Import',
      destructive: false,
    );
    if (!confirmed) return;
    await widget.repo.importTables(tables);
    _toast('Imported ${_tablesCount(tables.length)}.');
  }

  Future<void> _moveLocalTables() async {
    final local = widget.moveFrom!;
    setState(() => _moving = true);
    try {
      final tables = await local.allTables();
      await widget.repo.importTables(tables);
      await local.clearAfterMove();
      _toast('Moved ${_tablesCount(tables.length)} to your account.');
    } catch (e) {
      _toast(
        'Couldn’t move your tables: $e. They are still saved in this browser.',
      );
    } finally {
      if (mounted) setState(() => _moving = false);
    }
  }

  void _open(LedgerTable table) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TableScreen(repo: widget.repo, tableId: table.id),
      ),
    );
  }

  Future<void> _create() async {
    final name = await showNameDialog(
      context,
      title: 'New table',
      confirmLabel: 'Create table',
      hint: 'e.g. October salary',
    );
    if (name == null) return;
    final table = await widget.repo.createTable(name);
    if (mounted) _open(table);
  }

  Future<void> _rename(LedgerTable table) async {
    final name = await showNameDialog(
      context,
      title: 'Rename table',
      confirmLabel: 'Rename',
      initial: table.name,
    );
    if (name != null) widget.repo.renameTable(table.id, name);
  }

  Future<void> _delete(LedgerTable table) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete “${table.name}”?',
      message:
          'This deletes the table and every entry in it. You can’t undo this.',
      confirmLabel: 'Delete table',
    );
    if (confirmed) widget.repo.deleteTable(table.id);
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 600;

    return Scaffold(
      floatingActionButton: narrow
          ? FloatingActionButton.extended(
              onPressed: _create,
              backgroundColor: Palette.ink,
              foregroundColor: Palette.sheet,
              icon: const Icon(Icons.add),
              label: const Text('New table'),
            )
          : null,
      body: SafeArea(
        child: StreamBuilder<List<LedgerTable>>(
          stream: _tables,
          builder: (context, snap) {
            final tables = snap.data;
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _Centered(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        narrow ? 16 : 24,
                        narrow ? 24 : 48,
                        narrow ? 8 : 24,
                        24,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your tables',
                                  style: Fonts.display(narrow ? 34 : 44),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Each table splits spending into Need, Work, Want, Luxury and Tithe.',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Palette.muted),
                                ),
                              ],
                            ),
                          ),
                          if (!narrow) ...[
                            const SizedBox(width: 16),
                            FilledButton.icon(
                              onPressed: _create,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('New table'),
                            ),
                          ],
                          PopupMenuButton<void>(
                            tooltip: 'More',
                            icon: const Icon(
                              Icons.more_vert,
                              color: Palette.muted,
                            ),
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                onTap: _export,
                                child: const ListTile(
                                  leading: Icon(Icons.download_outlined),
                                  title: Text('Export backup'),
                                ),
                              ),
                              PopupMenuItem(
                                onTap: _import,
                                child: const ListTile(
                                  leading: Icon(Icons.upload_outlined),
                                  title: Text('Import backup'),
                                ),
                              ),
                              if (widget.onSignOut != null)
                                PopupMenuItem(
                                  onTap: widget.onSignOut,
                                  child: const ListTile(
                                    leading: Icon(Icons.logout),
                                    title: Text('Sign out'),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_localTables != null)
                  SliverToBoxAdapter(
                    child: StreamBuilder<List<LedgerTable>>(
                      stream: _localTables,
                      builder: (context, localSnap) {
                        final count = localSnap.data?.length ?? 0;
                        if (count == 0) return const SizedBox.shrink();
                        return _Centered(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              narrow ? 12 : 24,
                              0,
                              narrow ? 12 : 24,
                              16,
                            ),
                            child: _MoveBanner(
                              message:
                                  '${_tablesCount(count)} saved in this browser before you signed in.',
                              busy: _moving,
                              onMove: _moveLocalTables,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                if (snap.hasError)
                  SliverToBoxAdapter(
                    child: _Centered(
                      child: _Message(
                        title: 'Couldn’t load your tables',
                        body: '${snap.error}',
                      ),
                    ),
                  )
                else if (tables == null)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
                else if (tables.isEmpty)
                  SliverToBoxAdapter(
                    child: _Centered(
                      child: _Message(
                        title: 'No tables yet',
                        body:
                            'Create a table, give it a name, and start adding entries to each column.',
                        action: FilledButton.icon(
                          onPressed: _create,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Create your first table'),
                        ),
                      ),
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: _Centered(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          narrow ? 12 : 24,
                          0,
                          narrow ? 12 : 24,
                          96,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Palette.sheet,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Palette.rule),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              for (final t in tables)
                                _TableRow(
                                  key: ValueKey(t.id),
                                  table: t,
                                  onOpen: () => _open(t),
                                  onRename: () => _rename(t),
                                  onDelete: () => _delete(t),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MoveBanner extends StatelessWidget {
  const _MoveBanner({
    required this.message,
    required this.busy,
    required this.onMove,
  });

  final String message;
  final bool busy;
  final VoidCallback onMove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: Palette.sheet,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Palette.ink),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
          FilledButton(
            onPressed: busy ? null : onMove,
            child: Text(busy ? 'Moving…' : 'Move to my account'),
          ),
        ],
      ),
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 880),
      child: child,
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message({required this.title, required this.body, this.action});

  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Fonts.display(26)),
          const SizedBox(height: 8),
          Text(
            body,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Palette.muted),
          ),
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({
    super.key,
    required this.table,
    required this.onOpen,
    required this.onRename,
    required this.onDelete,
  });

  final LedgerTable table;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Palette.rule)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 4, 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(table.name, style: Fonts.display(22)),
                  const SizedBox(height: 4),
                  Text(
                    createdLabel(table.createdAt),
                    style: Fonts.figure(12, color: Palette.muted),
                  ),
                  const SizedBox(height: 10),
                  _SplitBar(table: table),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Text(naira(table.grandTotal), style: Fonts.figure(17)),
            PopupMenuButton<void>(
              tooltip: 'Actions for ${table.name}',
              icon: const Icon(Icons.more_horiz, color: Palette.muted),
              itemBuilder: (_) => [
                PopupMenuItem(onTap: onRename, child: const Text('Rename')),
                PopupMenuItem(
                  onTap: onDelete,
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Palette.redRule),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A thin strip showing how the table's total splits across the columns.
class _SplitBar extends StatelessWidget {
  const _SplitBar({required this.table});
  final LedgerTable table;

  @override
  Widget build(BuildContext context) {
    final total = table.grandTotal;
    final parts = [
      for (final c in LedgerColumn.values)
        if (table.columnTotal(c) > 0) (c, table.columnTotal(c)),
    ];
    final summary = parts.map((p) => '${p.$1.label} ${naira(p.$2)}').join(', ');

    return Semantics(
      label: total == 0 ? 'No amounts yet' : summary,
      excludeSemantics: true,
      child: Tooltip(
        message: total == 0 ? 'No amounts yet' : summary,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: SizedBox(
            height: 4,
            width: 220,
            child: total == 0
                ? Container(color: Palette.rule)
                : Row(
                    children: [
                      for (final (column, amount) in parts)
                        Expanded(
                          flex: (amount * 1000 / total).ceil(),
                          child: Container(color: Palette.of(column)),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
