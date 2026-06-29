// lib/features/ai/view/ai_refusals_screen.dart
//
// Step 19 — AI Refusals viewer at /admin/ai/refusals.
//
// Mirrors AiFailuresScreen layout. Differences:
//   • Title and copy reframed for refusals
//   • Magenta Bloom accents (refusals are AI declines, not API errors)
//   • Table shows refusalReason instead of errorMessage
//   • Grouping panel groups by refusalReason

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../controller/admin_ai_refusals_controller.dart';
import '../model/ai_activity_summary.dart';

class AiRefusalsScreen extends ConsumerStatefulWidget {
  const AiRefusalsScreen({super.key});

  @override
  ConsumerState<AiRefusalsScreen> createState() => _AiRefusalsScreenState();
}

class _AiRefusalsScreenState extends ConsumerState<AiRefusalsScreen> {
  final _searchCtrl = TextEditingController();
  final Set<String> _expanded = {};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiRefusalsProvider);
    final ctrl = ref.read(aiRefusalsProvider.notifier);
    final rows = state.filteredItems;
    final groups = state.refusalGroups;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(loading: state.loading, onRefresh: ctrl.refresh),
          const SizedBox(height: 16),
          _Filters(
            state: state,
            searchCtrl: _searchCtrl,
            onDate: ctrl.setDateRange,
            onTool: ctrl.setToolFilter,
            onSearch: ctrl.setUserSearch,
          ),
          const SizedBox(height: 16),
          if (state.error != null) ...[
            _ErrorBlock(error: state.error!),
            const SizedBox(height: 14),
          ],
          if (state.loading && state.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.darkRaspberry,
                ),
              ),
            )
          else ...[
            _StatsRow(
              totalRefusals: rows.length,
              uniqueUsers: rows.map((r) => r.userId).toSet().length,
              uniqueGroups: groups.length,
            ),
            const SizedBox(height: 16),
            if (groups.isNotEmpty) ...[
              _GroupingCard(groups: groups, total: rows.length),
              const SizedBox(height: 16),
            ],
            if (rows.isEmpty)
              _Empty(filtered: state.items.isNotEmpty)
            else
              _Table(
                rows: rows,
                expanded: _expanded,
                onToggleExpand: (id) => setState(() {
                  if (!_expanded.add(id)) _expanded.remove(id);
                }),
              ),
            const SizedBox(height: 16),
            if (state.hasMore)
              Center(
                child: OutlinedButton.icon(
                  onPressed: state.loadingMore ? null : ctrl.loadMore,
                  icon: state.loadingMore
                      ? const SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.darkRaspberry,
                    ),
                  )
                      : const Icon(Icons.expand_more, size: 16),
                  label: Text(
                    state.loadingMore ? 'Loading…' : 'Load 50 more',
                  ),
                ),
              ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── HEADER ───────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final bool loading;
  final VoidCallback onRefresh;
  const _Header({required this.loading, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Refusals',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.prussianBlue,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'AI calls where Claude returned a refusal envelope. '
                    'Each refusal counts toward the user\'s 5-per-cycle soft block.',
                style: TextStyle(fontSize: 13, color: AppColors.slateGrey),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: loading ? null : onRefresh,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Refresh'),
        ),
      ],
    );
  }
}

// ─── STATS ROW ────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int totalRefusals;
  final int uniqueUsers;
  final int uniqueGroups;
  const _StatsRow({
    required this.totalRefusals,
    required this.uniqueUsers,
    required this.uniqueGroups,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Refusals',
            value: totalRefusals.toString(),
            color: AppColors.magentaBloom,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Distinct users',
            value: uniqueUsers.toString(),
            color: AppColors.dustyMauve,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Distinct reasons',
            value: uniqueGroups.toString(),
            color: AppColors.darkRaspberry,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.almondSilk),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.slateGrey,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── GROUPING CARD ────────────────────────────────────────────────────────

class _GroupingCard extends StatelessWidget {
  final List<MapEntry<String, int>> groups;
  final int total;
  const _GroupingCard({required this.groups, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.almondSilk),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.block,
                  size: 16, color: AppColors.magentaBloom),
              SizedBox(width: 6),
              Text(
                'TOP REFUSAL REASONS',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slateGrey,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < groups.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _GroupRow(
              message: groups[i].key,
              count: groups[i].value,
              total: total,
            ),
          ],
        ],
      ),
    );
  }
}

class _GroupRow extends StatelessWidget {
  final String message;
  final int count;
  final int total;
  const _GroupRow({
    required this.message,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : (count / total);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SelectableText(
                message,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'OpenSans',
                  color: AppColors.prussianBlue,
                ),
              ),
            ),
            const SizedBox(width: 14),
            SizedBox(
              width: 80,
              child: Text(
                '$count  · ${(pct * 100).toStringAsFixed(0)}%',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.magentaBloom,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: pct.clamp(0.0, 1.0),
            backgroundColor: AppColors.lavenderBlush,
            color: AppColors.magentaBloom.withValues(alpha: 0.7),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}

// ─── FILTERS ──────────────────────────────────────────────────────────────

class _Filters extends StatelessWidget {
  final AiRefusalsState state;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onDate;
  final ValueChanged<String> onTool;
  final ValueChanged<String> onSearch;

  const _Filters({
    required this.state,
    required this.searchCtrl,
    required this.onDate,
    required this.onTool,
    required this.onSearch,
  });

  static const _dateOptions = [
    ('24h', 'Last 24 hours'),
    ('7d', 'Last 7 days'),
    ('30d', 'Last 30 days'),
    ('all', 'All time'),
  ];

  static const _toolOptions = [
    ('all', 'All tools'),
    ('cv', 'CV'),
    ('coverLetter', 'Cover Letter'),
    ('proposal', 'Proposal'),
    ('linkedin', 'LinkedIn'),
    ('clientExtract', 'Client Extract'),
    ('clientChat', 'Client Chat'),
    ('editorAI', 'AI Assistant'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.almondSilk),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _Dropdown<String>(
            label: 'Date',
            value: state.dateRange,
            items: _dateOptions,
            onChanged: onDate,
            width: 180,
          ),
          _Dropdown<String>(
            label: 'Tool',
            value: state.toolFilter,
            items: _toolOptions,
            onChanged: onTool,
            width: 180,
          ),
          SizedBox(
            width: 240,
            child: TextField(
              controller: searchCtrl,
              onChanged: onSearch,
              decoration: const InputDecoration(
                isDense: true,
                prefixIcon: Icon(Icons.search, size: 18),
                hintText: 'Email or UID',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<(T, String)> items;
  final ValueChanged<T> onChanged;
  final double width;

  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: InputDecorator(
        decoration: InputDecoration(
          isDense: true,
          labelText: label,
          labelStyle: const TextStyle(
            fontSize: 12,
            color: AppColors.slateGrey,
          ),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
            items: items
                .map((it) => DropdownMenuItem<T>(
              value: it.$1,
              child: Text(it.$2,
                  style: const TextStyle(fontSize: 13)),
            ))
                .toList(),
          ),
        ),
      ),
    );
  }
}

// ─── TABLE ────────────────────────────────────────────────────────────────

class _Table extends StatelessWidget {
  final List<AiActivitySummary> rows;
  final Set<String> expanded;
  final ValueChanged<String> onToggleExpand;

  const _Table({
    required this.rows,
    required this.expanded,
    required this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.almondSilk),
      ),
      child: Column(
        children: [
          const _HeaderRow(),
          for (var i = 0; i < rows.length; i++) ...[
            const Divider(
              color: AppColors.almondSilk,
              height: 0,
              thickness: 0.3,
            ),
            _DataRow(
              row: rows[i],
              expanded: expanded.contains(rows[i].id),
              onTap: () => onToggleExpand(rows[i].id),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.lavenderBlush,
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: const Row(
        children: [
          _HeaderCell('TIME', flex: 2),
          _HeaderCell('USER', flex: 3),
          _HeaderCell('TOOL / TYPE', flex: 3),
          _HeaderCell('REFUSAL REASON', flex: 5),
          _HeaderCell('TOKENS', flex: 2, align: TextAlign.right),
          SizedBox(width: 24),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final int flex;
  final TextAlign align;
  const _HeaderCell(this.text,
      {this.flex = 1, this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.slateGrey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final AiActivitySummary row;
  final bool expanded;
  final VoidCallback onTap;

  const _DataRow({
    required this.row,
    required this.expanded,
    required this.onTap,
  });

  String get _reason {
    final r = (row.refusalReason ?? row.errorMessage ?? '').trim();
    return r.isEmpty ? '(no reason given)' : r;
  }

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('MMM d, HH:mm:ss');
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    row.createdAt == null
                        ? '—'
                        : timeFmt.format(row.createdAt!.toLocal()),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.prussianBlue,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.userEmail ?? '(no email)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.prussianBlue,
                        ),
                      ),
                      Text(
                        row.userId ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.slateGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.tool ?? '—',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.prussianBlue,
                        ),
                      ),
                      Text(
                        row.type ?? '—',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.slateGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Text(
                    _reason,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.magentaBloom,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${row.inputTokens}/${row.outputTokens}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.slateGrey,
                    ),
                  ),
                ),
                SizedBox(
                  width: 24,
                  child: Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: AppColors.slateGrey,
                  ),
                ),
              ],
            ),
          ),
          if (expanded) _ExpandedDetail(row: row, reason: _reason),
        ],
      ),
    );
  }
}

class _ExpandedDetail extends StatelessWidget {
  final AiActivitySummary row;
  final String reason;
  const _ExpandedDetail({required this.row, required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.lavenderBlush,
        border: Border(
          top: BorderSide(color: AppColors.almondSilk, width: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 24,
            runSpacing: 10,
            children: [
              _Field(label: 'Activity ID', value: row.id),
              _Field(label: 'Model', value: row.model ?? '—'),
              _Field(label: 'Section', value: row.sectionType ?? '—'),
              _Field(
                label: 'Document',
                value: row.documentTitle ?? (row.documentId ?? '—'),
              ),
              _Field(label: 'Template', value: row.templateId ?? '—'),
              _Field(
                label: 'Duration',
                value:
                row.durationMs > 0 ? '${row.durationMs} ms' : '—',
              ),
              if (row.rewriteMode != null)
                _Field(label: 'Refine mode', value: row.rewriteMode!),
              if (row.editorAiOps != null && row.editorAiOps!.isNotEmpty)
                _Field(
                  label: 'Editor ops',
                  value: row.editorAiOps!.join(', '),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.magentaBloom.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: AppColors.magentaBloom.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FULL REFUSAL REASON',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.magentaBloom,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  reason,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'OpenSans',
                    color: AppColors.prussianBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String value;
  const _Field({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.slateGrey,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 2),
          SelectableText(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.prussianBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final bool filtered;
  const _Empty({required this.filtered});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(60),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.almondSilk),
      ),
      child: Center(
        child: Text(
          filtered
              ? 'No refusals match your filters.'
              : '🎉 No AI refusals in the selected date range.',
          style: const TextStyle(
            color: AppColors.slateGrey,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  final String error;
  const _ErrorBlock({required this.error});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.dangerRed.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: AppColors.dangerRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: AppColors.dangerRed, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              error,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.prussianBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}