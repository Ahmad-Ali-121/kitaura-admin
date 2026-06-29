// lib/features/finance/view/cost_by_user_screen.dart
//
// Step 20 — Cost by User at /admin/finance/by-user.
//
// Triage screen: top spenders, refusal-rate offenders, volume users.
// 25 rows per page. Click any row to drill into User Detail.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../controller/admin_cost_by_user_controller.dart';

class CostByUserScreen extends ConsumerWidget {
  const CostByUserScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(costByUserProvider);
    final ctrl = ref.read(costByUserProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            loading: state.loading,
            windowStart: state.windowStart,
            windowEnd: state.windowEnd,
            onRefresh: ctrl.refresh,
          ),
          const SizedBox(height: 16),
          _Toolbar(
            sortBy: state.sortBy,
            onSort: ctrl.setSort,
            totalUsers: state.totalUsers,
          ),
          const SizedBox(height: 16),
          if (state.error != null) ...[
            _ErrorBlock(error: state.error!),
            const SizedBox(height: 14),
          ],
          if (state.loading && state.users.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.darkRaspberry,
                ),
              ),
            )
          else if (state.users.isEmpty)
            const _Empty()
          else ...[
              _Table(
                rows: state.users,
                startRank: (state.page - 1) * state.pageSize + 1,
                onRowTap: (uid) => context.go('/admin/users/$uid'),
              ),
              const SizedBox(height: 16),
              _Pager(
                page: state.page,
                totalPages: state.totalPages,
                loading: state.loading,
                onPrev: state.page > 1 ? () => ctrl.goToPage(state.page - 1) : null,
                onNext: state.page < state.totalPages
                    ? () => ctrl.goToPage(state.page + 1)
                    : null,
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
  final DateTime? windowStart;
  final DateTime? windowEnd;
  final VoidCallback onRefresh;
  const _Header({
    required this.loading,
    required this.windowStart,
    required this.windowEnd,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d');
    final windowLabel = (windowStart != null && windowEnd != null)
        ? '${fmt.format(windowStart!.toLocal())} – ${fmt.format(windowEnd!.toLocal())}'
        : 'last 30 days';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cost by User',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.prussianBlue,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'AI spend per user · $windowLabel',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.slateGrey,
                ),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: loading ? null : onRefresh,
          icon: loading
              ? const SizedBox(
            height: 14,
            width: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.slateGrey,
            ),
          )
              : const Icon(Icons.refresh, size: 16),
          label: const Text('Refresh'),
        ),
      ],
    );
  }
}

// ─── TOOLBAR ──────────────────────────────────────────────────────────────

class _Toolbar extends StatelessWidget {
  final CostByUserSort sortBy;
  final ValueChanged<CostByUserSort> onSort;
  final int totalUsers;
  const _Toolbar({
    required this.sortBy,
    required this.onSort,
    required this.totalUsers,
  });

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
          SizedBox(
            width: 240,
            child: InputDecorator(
              decoration: const InputDecoration(
                isDense: true,
                labelText: 'Sort by',
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: AppColors.slateGrey,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<CostByUserSort>(
                  value: sortBy,
                  isExpanded: true,
                  onChanged: (v) {
                    if (v != null) onSort(v);
                  },
                  items: CostByUserSort.values
                      .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(
                      s.label,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ))
                      .toList(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.petalFrost,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$totalUsers users with activity',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.darkRaspberry,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── TABLE ────────────────────────────────────────────────────────────────

class _Table extends StatelessWidget {
  final List<CostByUserRow> rows;
  final int startRank;
  final ValueChanged<String> onRowTap;
  const _Table({
    required this.rows,
    required this.startRank,
    required this.onRowTap,
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
              rank: startRank + i,
              onTap: () => onRowTap(rows[i].uid),
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
          SizedBox(width: 36, child: _HCell('#')),
          Expanded(flex: 4, child: _HCell('USER')),
          SizedBox(width: 70, child: _HCell('PLAN')),
          Expanded(flex: 2, child: _HCell('SPEND', align: TextAlign.right)),
          Expanded(flex: 2, child: _HCell('CALLS', align: TextAlign.right)),
          Expanded(flex: 2, child: _HCell('FAILED', align: TextAlign.right)),
          Expanded(
            flex: 2,
            child: _HCell('REFUSALS', align: TextAlign.right),
          ),
          SizedBox(width: 24),
        ],
      ),
    );
  }
}

class _HCell extends StatelessWidget {
  final String text;
  final TextAlign align;
  const _HCell(this.text, {this.align = TextAlign.left});
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppColors.slateGrey,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final CostByUserRow row;
  final int rank;
  final VoidCallback onTap;
  const _DataRow({
    required this.row,
    required this.rank,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final usd = NumberFormat.simpleCurrency(decimalDigits: 4);
    final refusalPct = (row.refusalRate * 100).toStringAsFixed(0);
    final hasRefusals = row.refusalCount > 0;
    final highRefusalRate = row.refusalRate >= 0.2 && row.callCount >= 5;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 36,
              child: Text(
                '$rank',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slateGrey,
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.email ?? '(no email)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.prussianBlue,
                    ),
                  ),
                  Text(
                    row.uid,
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
            SizedBox(width: 70, child: _PlanChip(plan: row.plan)),
            Expanded(
              flex: 2,
              child: Text(
                usd.format(row.totalCost),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkRaspberry,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${row.callCount}',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.prussianBlue,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${row.failureCount}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12,
                  color: row.failureCount > 0
                      ? AppColors.dangerRed
                      : AppColors.slateGrey,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (hasRefusals)
                    Text(
                      '$refusalPct%',
                      style: TextStyle(
                        fontSize: 11,
                        color: highRefusalRate
                            ? AppColors.magentaBloom
                            : AppColors.slateGrey,
                      ),
                    ),
                  if (hasRefusals) const SizedBox(width: 6),
                  Text(
                    '${row.refusalCount}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: highRefusalRate
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: hasRefusals
                          ? AppColors.magentaBloom
                          : AppColors.slateGrey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: 24,
              child: Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.slateGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanChip extends StatelessWidget {
  final String? plan;
  const _PlanChip({required this.plan});

  @override
  Widget build(BuildContext context) {
    final p = (plan ?? 'free').toLowerCase();
    late Color bg;
    late Color fg;
    if (p == 'pro') {
      bg = AppColors.darkRaspberry;
      fg = AppColors.white;
    } else if (p == 'trial') {
      bg = AppColors.magentaBloom;
      fg = AppColors.white;
    } else {
      bg = AppColors.petalFrost;
      fg = AppColors.darkRaspberry;
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          p.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: fg,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}

// ─── PAGER ────────────────────────────────────────────────────────────────

class _Pager extends StatelessWidget {
  final int page;
  final int totalPages;
  final bool loading;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _Pager({
    required this.page,
    required this.totalPages,
    required this.loading,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: loading ? null : onPrev,
          icon: const Icon(Icons.chevron_left, size: 16),
          label: const Text('Previous'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Page $page of $totalPages',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.slateGrey,
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: loading ? null : onNext,
          icon: const Icon(Icons.chevron_right, size: 16),
          label: const Text('Next'),
        ),
      ],
    );
  }
}

// ─── STATES ───────────────────────────────────────────────────────────────

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(60),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.almondSilk),
      ),
      child: const Center(
        child: Text(
          'No AI activity in the last 30 days.',
          style: TextStyle(color: AppColors.slateGrey, fontSize: 14),
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