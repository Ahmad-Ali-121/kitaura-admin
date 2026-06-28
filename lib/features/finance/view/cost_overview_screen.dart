import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../controller/cost_overview_controller.dart';
import '../model/cost_overview.dart';

class CostOverviewScreen extends ConsumerWidget {
  const CostOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(costOverviewProvider);
    final ctrl = ref.read(costOverviewProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            refreshedAt: state.data?.refreshedAt,
            loading: state.loading,
            onRefresh: ctrl.refresh,
          ),
          const SizedBox(height: 20),
          if (state.error != null) ...[
            _ErrorBlock(error: state.error!),
            const SizedBox(height: 14),
          ],
          if (state.loading && state.data == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.darkRaspberry,
                ),
              ),
            )
          else if (state.data != null) ...[
            _KpiRow(data: state.data!),
            const SizedBox(height: 20),
            _ChartCard(daily: state.data!.dailySpend),
            const SizedBox(height: 20),
            _BreakdownsRow(data: state.data!),
            const SizedBox(height: 20),
            _CacheCard(data: state.data!),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── HEADER ───────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final DateTime? refreshedAt;
  final bool loading;
  final VoidCallback onRefresh;
  const _Header({
    required this.refreshedAt,
    required this.loading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cost Overview',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.prussianBlue,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                refreshedAt == null
                    ? 'Anthropic spend across all users — last 30 days.'
                    : 'Last 30 days · refreshed ${DateFormat('MMM d, HH:mm').format(refreshedAt!.toLocal())}',
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
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Refresh'),
        ),
      ],
    );
  }
}

// ─── KPI ROW ──────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  final CostOverview data;
  const _KpiRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, c) {
      final cols = c.maxWidth > 900 ? 4 : (c.maxWidth > 500 ? 2 : 1);
      const gap = 12.0;
      final w = (c.maxWidth - gap * (cols - 1)) / cols;
      final cards = [
        _KpiCard(
          label: 'Spend today',
          value: '\$${data.todayCost.toStringAsFixed(2)}',
          sub: '${data.todayCalls} calls',
          color: AppColors.darkRaspberry,
          icon: Icons.today,
        ),
        _KpiCard(
          label: 'Spend last 7d',
          value: '\$${data.weekCost.toStringAsFixed(2)}',
          sub: '${data.weekCalls} calls',
          color: AppColors.magentaBloom,
          icon: Icons.calendar_view_week,
        ),
        _KpiCard(
          label: 'Spend last 30d',
          value: '\$${data.monthCost.toStringAsFixed(2)}',
          sub: '${data.monthCalls} calls',
          color: AppColors.dustyMauve,
          icon: Icons.calendar_month,
        ),
        _KpiCard(
          label: 'Failure rate',
          value:
          '${data.totalCalls == 0 ? "0" : (data.totalFailures * 100 / data.totalCalls).toStringAsFixed(1)}%',
          sub:
          '${data.totalFailures} fail · ${data.totalRefusals} refused',
          color: AppColors.dangerRed,
          icon: Icons.error_outline,
        ),
      ];
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: cards.map((card) {
          return SizedBox(width: w, child: card);
        }).toList(),
      );
    });
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;
  final IconData icon;
  const _KpiCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    required this.icon,
  });

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label.toUpperCase(),
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
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.slateGrey,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CHART CARD ───────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final List<DailySpend> daily;
  const _ChartCard({required this.daily});

  @override
  Widget build(BuildContext context) {
    if (daily.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.almondSilk),
        ),
        child: const Center(
          child: Text(
            'No data to plot.',
            style: TextStyle(color: AppColors.slateGrey),
          ),
        ),
      );
    }

    final maxY = daily.fold<double>(0, (m, d) => d.cost > m ? d.cost : m);
    final chartMaxY = maxY < 0.01 ? 0.10 : maxY * 1.15;
    final spots = <FlSpot>[
      for (var i = 0; i < daily.length; i++)
        FlSpot(i.toDouble(), daily[i].cost)
    ];

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
              Icon(Icons.show_chart,
                  size: 16, color: AppColors.darkRaspberry),
              SizedBox(width: 6),
              Text(
                'DAILY SPEND · LAST 30 DAYS',
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
          const SizedBox(height: 14),
          SizedBox(
            height: 240,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: chartMaxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: chartMaxY / 4,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppColors.almondSilk,
                    strokeWidth: 0.4,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: (daily.length / 6).floorToDouble().clamp(1, 10),
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= daily.length) {
                          return const SizedBox.shrink();
                        }
                        final parts = daily[idx].date.split('-');
                        if (parts.length != 3) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${parts[1]}/${parts[2]}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.slateGrey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      interval: chartMaxY / 4,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '\$${value.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.slateGrey,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.prussianBlue,
                    getTooltipItems: (touched) {
                      return touched.map((t) {
                        final idx = t.x.toInt();
                        final d = (idx >= 0 && idx < daily.length)
                            ? daily[idx]
                            : null;
                        final label = d == null
                            ? ''
                            : '${d.date}\n\$${d.cost.toStringAsFixed(4)} · ${d.count} calls';
                        return LineTooltipItem(
                          label,
                          const TextStyle(
                            color: AppColors.white,
                            fontSize: 11,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.2,
                    color: AppColors.darkRaspberry,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.darkRaspberry.withValues(alpha: 0.18),
                          AppColors.darkRaspberry.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── BREAKDOWNS ───────────────────────────────────────────────────────────

class _BreakdownsRow extends StatelessWidget {
  final CostOverview data;
  const _BreakdownsRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, c) {
      final cols = c.maxWidth > 700 ? 2 : 1;
      const gap = 16.0;
      final w = (c.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          SizedBox(
            width: w,
            child: _BreakdownCard(
              title: 'BY MODEL',
              icon: Icons.precision_manufacturing_outlined,
              rows: data.byModel
                  .map((m) => (label: m.model, cost: m.cost, count: m.count))
                  .toList(),
              total: data.byModel.fold<double>(0, (a, b) => a + b.cost),
            ),
          ),
          SizedBox(
            width: w,
            child: _BreakdownCard(
              title: 'BY TOOL',
              icon: Icons.build_outlined,
              rows: data.byTool
                  .map((t) => (label: t.tool, cost: t.cost, count: t.count))
                  .toList(),
              total: data.byTool.fold<double>(0, (a, b) => a + b.cost),
            ),
          ),
        ],
      );
    });
  }
}

class _BreakdownCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<({String label, double cost, int count})> rows;
  final double total;

  const _BreakdownCard({
    required this.title,
    required this.icon,
    required this.rows,
    required this.total,
  });

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
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.darkRaspberry),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
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
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No data.',
                style: TextStyle(
                  color: AppColors.slateGrey,
                  fontSize: 12,
                ),
              ),
            )
          else
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _BreakdownRow(row: rows[i], total: total),
            ],
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final ({String label, double cost, int count}) row;
  final double total;
  const _BreakdownRow({required this.row, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : (row.cost / total);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                row.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'OpenSans',
                  fontWeight: FontWeight.w600,
                  color: AppColors.prussianBlue,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '\$${row.cost.toStringAsFixed(2)}  ·  ${row.count}',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.darkRaspberry,
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
            color: AppColors.darkRaspberry.withValues(alpha: 0.7),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}

// ─── CACHE SAVINGS ────────────────────────────────────────────────────────

class _CacheCard extends StatelessWidget {
  final CostOverview data;
  const _CacheCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.petalFrost.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.dustyMauve),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.dustyMauve.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.savings_outlined,
              color: AppColors.dustyMauve,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PROMPT CACHE SAVINGS',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slateGrey,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '\$${data.cacheSavings.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dustyMauve,
                        ),
                      ),
                      const TextSpan(
                        text: '  saved  ',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.slateGrey,
                        ),
                      ),
                      TextSpan(
                        text:
                        '· ${_formatTokens(data.cacheReadTokens)} cache reads · ${_formatTokens(data.inputTokens)} input · ${_formatTokens(data.outputTokens)} output',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.slateGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTokens(int n) {
    if (n >= 1_000_000) return '${(n / 1_000_000).toStringAsFixed(2)}M';
    if (n >= 1_000) return '${(n / 1_000).toStringAsFixed(1)}K';
    return n.toString();
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