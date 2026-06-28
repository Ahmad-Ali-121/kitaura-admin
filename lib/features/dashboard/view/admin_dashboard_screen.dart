import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../controller/admin_dashboard_controller.dart';
import '../model/admin_kpi_model.dart';
import 'kpi_card_widget.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpisAsync = ref.watch(adminDashboardProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            onRefresh: () => ref.invalidate(adminDashboardProvider),
            generatedAt: kpisAsync.valueOrNull?.generatedAt,
            loading: kpisAsync.isLoading,
          ),
          const SizedBox(height: 20),
          kpisAsync.when(
            loading: () => const _Loading(),
            error: (err, _) => _ErrorBlock(error: err.toString()),
            data: (kpis) => _DashboardBody(kpis: kpis),
          ),
        ],
      ),
    );
  }
}

// ─── HEADER ───────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onRefresh;
  final DateTime? generatedAt;
  final bool loading;

  const _Header({
    required this.onRefresh,
    required this.generatedAt,
    required this.loading,
  });

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
                'Overview',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.prussianBlue,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'KitAura platform — live numbers',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.slateGrey,
                ),
              ),
            ],
          ),
        ),
        if (generatedAt != null) ...[
          Text(
            'Updated ${DateFormat.Hm().format(generatedAt!.toLocal())}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.slateGrey,
            ),
          ),
          const SizedBox(width: 12),
        ],
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

// ─── BODY ─────────────────────────────────────────────────────────────────

class _DashboardBody extends StatelessWidget {
  final AdminKpis kpis;
  const _DashboardBody({required this.kpis});

  @override
  Widget build(BuildContext context) {
    final usd = NumberFormat.simpleCurrency(decimalDigits: 2);
    final pct = NumberFormat.percentPattern();
    final compact = NumberFormat.compact();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary KPIs
        const _SectionLabel(label: 'KEY METRICS'),
        const SizedBox(height: 10),
        _KpiGrid(
          cards: [
            KpiCard(
              label: 'TOTAL USERS',
              value: compact.format(kpis.totalUsers),
              icon: Icons.people_outline,
              iconColor: AppColors.darkRaspberry,
            ),
            KpiCard(
              label: 'ACTIVE TODAY',
              value: compact.format(kpis.activeToday),
              icon: Icons.bolt_outlined,
              iconColor: AppColors.magentaBloom,
              subline: '${_pctOf(kpis.activeToday, kpis.totalUsers)} of users',
            ),
            KpiCard(
              label: 'AI SPEND (MTD)',
              value: usd.format(kpis.mtdSpend),
              icon: Icons.attach_money,
              iconColor: AppColors.dustyMauve,
              emphasis: true,
            ),
            KpiCard(
              label: 'ACTIVE TRIALS',
              value: compact.format(kpis.activeTrials),
              icon: Icons.timer_outlined,
              iconColor: AppColors.dustyRose,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Secondary KPIs
        const _SectionLabel(label: 'ACTIVITY (LAST 24H)'),
        const SizedBox(height: 10),
        _KpiGrid(
          cards: [
            KpiCard(
              label: 'SIGNUPS / WEEK',
              value: compact.format(kpis.signupsThisWeek),
              icon: Icons.person_add_outlined,
              iconColor: AppColors.darkRaspberry,
            ),
            KpiCard(
              label: 'AI FAILURES (24H)',
              value: compact.format(kpis.failures24h),
              icon: Icons.error_outline,
              iconColor: kpis.failures24h > 0
                  ? AppColors.dangerRed
                  : AppColors.slateGrey,
              emphasis: kpis.failures24h > 0,
            ),
            KpiCard(
              label: 'AI REFUSALS (24H)',
              value: compact.format(kpis.refusals24h),
              icon: Icons.block,
              iconColor: AppColors.dustyMauve,
            ),
            KpiCard(
              label: 'CACHE HIT RATE',
              value: pct.format(kpis.cacheHitRate),
              icon: Icons.cached,
              iconColor: AppColors.magentaBloom,
              subline: 'Anthropic prompt cache',
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Top spenders
        const _SectionLabel(label: 'TOP SPENDERS — THIS MONTH'),
        const SizedBox(height: 10),
        _TopSpendersTable(spenders: kpis.topSpenders),
      ],
    );
  }

  String _pctOf(int part, int total) {
    if (total == 0) return '—';
    final pct = (part / total * 100).toStringAsFixed(1);
    return '$pct%';
  }
}

// ─── GRID ─────────────────────────────────────────────────────────────────

class _KpiGrid extends StatelessWidget {
  final List<Widget> cards;
  const _KpiGrid({required this.cards});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 1100
            ? 4
            : constraints.maxWidth > 700
            ? 2
            : 1;
        const gap = 14.0;
        final tileWidth =
            (constraints.maxWidth - (gap * (cols - 1))) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: cards
              .map((c) => SizedBox(width: tileWidth, child: c))
              .toList(),
        );
      },
    );
  }
}

// ─── TOP SPENDERS TABLE ───────────────────────────────────────────────────

class _TopSpendersTable extends StatelessWidget {
  final List<TopSpender> spenders;
  const _TopSpendersTable({required this.spenders});

  @override
  Widget build(BuildContext context) {
    final usd = NumberFormat.simpleCurrency(decimalDigits: 4);

    if (spenders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.almondSilk),
        ),
        child: const Text(
          'No spend recorded yet this month.',
          style: TextStyle(color: AppColors.slateGrey, fontSize: 13),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.almondSilk),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.petalFrost,
              borderRadius:
              BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    '#',
                    style: _headerStyle,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Text('USER', style: _headerStyle),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'SPEND',
                    style: _headerStyle,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          // Rows
          for (var i = 0; i < spenders.length; i++) ...[
            if (i > 0)
              const Divider(
                  color: AppColors.almondSilk, height: 0, thickness: 0.4),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        color: AppColors.slateGrey,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          spenders[i].email ?? '(no email)',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.prussianBlue,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          spenders[i].uid,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.slateGrey,
                            fontFamily: 'OpenSans',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      usd.format(spenders[i].spend),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.prussianBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

const _headerStyle = TextStyle(
  fontFamily: 'Poppins',
  fontSize: 10,
  fontWeight: FontWeight.w700,
  letterSpacing: 1,
  color: AppColors.slateGrey,
);

// ─── SECTION LABEL ────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: AppColors.slateGrey,
      ),
    );
  }
}

// ─── LOADING / ERROR ──────────────────────────────────────────────────────

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 80),
      child: Column(
        children: [
          CircularProgressIndicator(color: AppColors.darkRaspberry),
          SizedBox(height: 12),
          Text(
            'Crunching the numbers…',
            style: TextStyle(color: AppColors.slateGrey, fontSize: 13),
          ),
        ],
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.dangerRed.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AppColors.dangerRed.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.error_outline,
                  color: AppColors.dangerRed, size: 20),
              SizedBox(width: 8),
              Text(
                'Failed to load dashboard',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: AppColors.dangerRed,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            error,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.prussianBlue,
              fontFamily: 'OpenSans',
            ),
          ),
        ],
      ),
    );
  }
}