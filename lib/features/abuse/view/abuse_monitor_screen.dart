// lib/features/abuse/view/abuse_monitor_screen.dart
//
// Step 22 — Abuse Monitor at /admin/abuse.
//
// Triage screen combining three signals: refusals, hourly burst hitters,
// 30-day cost outliers. Click a row to drill into User Detail and take
// action (reset refusal, reset hourly burst, revoke Pro, etc).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../controller/admin_abuse_controller.dart';

class AbuseMonitorScreen extends ConsumerWidget {
  const AbuseMonitorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(abuseMonitorProvider);
    final ctrl = ref.read(abuseMonitorProvider.notifier);

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
          if (state.error != null) ...[
            _ErrorBlock(error: state.error!),
            const SizedBox(height: 14),
          ],
          if (state.loading && state.flagged.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.darkRaspberry,
                ),
              ),
            )
          else ...[
            _SummaryRow(summary: state.summary),
            if (state.thresholds != null) ...[
              const SizedBox(height: 12),
              _ThresholdsCard(thresholds: state.thresholds!),
            ],
            const SizedBox(height: 16),
            if (state.flagged.isEmpty)
              const _Empty()
            else
              _FlaggedTable(
                rows: state.flagged,
                onRowTap: (uid) => context.go('/admin/users/$uid'),
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
                'Abuse Monitor',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.prussianBlue,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Users flagged by refusals, hourly burst, or cost · $windowLabel',
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

// ─── SUMMARY ROW ─────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final AbuseSummary summary;
  const _SummaryRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth > 800 ? 4 : 2;
        const gap = 12.0;
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        final items = [
          _SummaryCard(
            label: 'High refusals',
            value: '${summary.refusalUsers}',
            color: AppColors.magentaBloom,
            icon: Icons.block,
          ),
          _SummaryCard(
            label: 'Hourly burst',
            value: '${summary.burstUsers}',
            color: AppColors.dustyRose,
            icon: Icons.bolt,
          ),
          _SummaryCard(
            label: 'Cost outliers',
            value: '${summary.costOutlierUsers}',
            color: AppColors.darkRaspberry,
            icon: Icons.attach_money,
          ),
          _SummaryCard(
            label: 'Multi-signal',
            value: '${summary.multiSignalUsers}',
            color: AppColors.prussianBlue,
            icon: Icons.warning_amber_outlined,
          ),
        ];
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children:
          items.map((card) => SizedBox(width: w, child: card)).toList(),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
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
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slateGrey,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
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

// ─── THRESHOLDS CARD ─────────────────────────────────────────────────────

class _ThresholdsCard extends StatelessWidget {
  final AbuseThresholds thresholds;
  const _ThresholdsCard({required this.thresholds});

  @override
  Widget build(BuildContext context) {
    final usd = NumberFormat.simpleCurrency(decimalDigits: 4);
    final pctile =
    (thresholds.outlierPercentile * 100).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.lavenderBlush,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.almondSilk),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            size: 14,
            color: AppColors.slateGrey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Thresholds: ${thresholds.refusalThreshold}+ refusals  ·  '
                  '${thresholds.burstThreshold}+ of 20 hourly burst  ·  '
                  'Top ${100 - int.parse(pctile)}% spend (≥ ${usd.format(thresholds.outlierThreshold)})',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.slateGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── TABLE ───────────────────────────────────────────────────────────────

class _FlaggedTable extends StatelessWidget {
  final List<FlaggedUser> rows;
  final ValueChanged<String> onRowTap;
  const _FlaggedTable({required this.rows, required this.onRowTap});

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
            _DataRow(row: rows[i], onTap: () => onRowTap(rows[i].uid)),
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
        color: AppColors.petalFrost,
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: const Row(
        children: [
          Expanded(flex: 4, child: _HCell('USER')),
          SizedBox(width: 70, child: _HCell('PLAN')),
          Expanded(flex: 4, child: _HCell('SIGNALS')),
          Expanded(flex: 2, child: _HCell('REFUSALS', align: TextAlign.right)),
          Expanded(flex: 2, child: _HCell('BURST', align: TextAlign.right)),
          Expanded(flex: 2, child: _HCell('30D SPEND', align: TextAlign.right)),
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
  final FlaggedUser row;
  final VoidCallback onTap;
  const _DataRow({required this.row, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final usd = NumberFormat.simpleCurrency(decimalDigits: 4);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
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
            Expanded(flex: 4, child: _SignalChips(signals: row.signals)),
            Expanded(
              flex: 2,
              child: Text(
                row.refusalCount > 0 ? '${row.refusalCount}' : '—',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: row.refusalCount > 0
                      ? AppColors.magentaBloom
                      : AppColors.slateGrey,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                row.hourlyCount > 0 ? '${row.hourlyCount}/20' : '—',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: row.hourlyCount > 0
                      ? AppColors.dustyRose
                      : AppColors.slateGrey,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                usd.format(row.totalCost),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: row.signals.contains(AbuseSignal.costOutlier)
                      ? AppColors.darkRaspberry
                      : AppColors.slateGrey,
                ),
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
  final String plan;
  const _PlanChip({required this.plan});
  @override
  Widget build(BuildContext context) {
    final p = plan.toLowerCase();
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

class _SignalChips extends StatelessWidget {
  final List<AbuseSignal> signals;
  const _SignalChips({required this.signals});

  Color _bg(AbuseSignal s) {
    switch (s) {
      case AbuseSignal.refusals:
        return AppColors.magentaBloom;
      case AbuseSignal.burst:
        return AppColors.dustyRose;
      case AbuseSignal.costOutlier:
        return AppColors.darkRaspberry;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: signals
          .map((s) => Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _bg(s),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          s.label.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
            letterSpacing: 0.6,
          ),
        ),
      ))
          .toList(),
    );
  }
}

// ─── STATES ──────────────────────────────────────────────────────────────

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shield_outlined,
              size: 32,
              color: AppColors.slateGrey,
            ),
            SizedBox(height: 8),
            Text(
              '🎉 No flagged users right now.',
              style: TextStyle(
                color: AppColors.slateGrey,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'No one has crossed the refusal, burst, or cost thresholds.',
              style: TextStyle(
                color: AppColors.slateGrey,
                fontSize: 12,
              ),
            ),
          ],
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