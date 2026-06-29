// lib/features/finance/view/cost_by_feature_screen.dart
//
// Step 21 — Cost by Feature at /admin/finance/by-feature.
//
// 30-day stacked bar chart (one segment per tool) + breakdown table
// ranked by spend.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../controller/admin_cost_by_feature_controller.dart';

// ─── TOOL → COLOR MAP ────────────────────────────────────────────────────
// Stable color assignment so chart segments and table swatches align.

const Map<String, Color> _toolColors = {
  'cv': AppColors.darkRaspberry,
  'coverLetter': AppColors.magentaBloom,
  'proposal': AppColors.dustyMauve,
  'linkedin': AppColors.prussianBlue,
  'clientExtract': AppColors.dustyRose,
  'clientChat': AppColors.almondSilk,
  'editorAI': AppColors.slateGrey,
  'spellcheck': AppColors.petalFrost,
};

Color _colorFor(String tool) =>
    _toolColors[tool] ?? AppColors.slateGrey;

// Stable bar-segment order — same in every day so colors line up vertically.
const List<String> _toolOrder = [
  'cv',
  'coverLetter',
  'proposal',
  'linkedin',
  'clientExtract',
  'clientChat',
  'editorAI',
  'spellcheck',
];

class CostByFeatureScreen extends ConsumerWidget {
  const CostByFeatureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(costByFeatureProvider);
    final ctrl = ref.read(costByFeatureProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            loading: state.loading,
            windowStart: state.windowStart,
            windowEnd: state.windowEnd,
            grandTotal: state.grandTotal,
            grandCalls: state.grandCalls,
            onRefresh: ctrl.refresh,
          ),
          const SizedBox(height: 16),
          if (state.error != null) ...[
            _ErrorBlock(error: state.error!),
            const SizedBox(height: 14),
          ],
          if (state.loading && state.features.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.darkRaspberry,
                ),
              ),
            )
          else if (state.features.isEmpty)
            const _Empty()
          else ...[
              _ChartCard(daily: state.daily),
              const SizedBox(height: 16),
              _BreakdownTable(features: state.features),
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
  final double grandTotal;
  final int grandCalls;
  final VoidCallback onRefresh;
  const _Header({
    required this.loading,
    required this.windowStart,
    required this.windowEnd,
    required this.grandTotal,
    required this.grandCalls,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d');
    final usd = NumberFormat.simpleCurrency(decimalDigits: 4);
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
                'Cost by Feature',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.prussianBlue,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Spend split across AI features · $windowLabel',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.slateGrey,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _Pill(
                    label: 'TOTAL SPEND',
                    value: usd.format(grandTotal),
                    valueColor: AppColors.darkRaspberry,
                  ),
                  const SizedBox(width: 10),
                  _Pill(
                    label: 'CALLS',
                    value: NumberFormat.decimalPattern().format(grandCalls),
                    valueColor: AppColors.prussianBlue,
                  ),
                ],
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

class _Pill extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  const _Pill({
    required this.label,
    required this.value,
    required this.valueColor,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.almondSilk),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.slateGrey,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CHART CARD ──────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final List<CostFeatureDay> daily;
  const _ChartCard({required this.daily});

  @override
  Widget build(BuildContext context) {
    final maxY = _computeMaxY(daily);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.almondSilk),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DAILY SPEND BY FEATURE',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.slateGrey,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 280,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceBetween,
                maxY: maxY,
                groupsSpace: 4,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.prussianBlue,
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    getTooltipItem: (group, _, __, ___) {
                      final day = daily[group.x.toInt()];
                      return _buildTooltip(day);
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 0 ? maxY / 4 : 1,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppColors.almondSilk,
                    strokeWidth: 0.4,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      interval: maxY > 0 ? maxY / 4 : 1,
                      getTitlesWidget: (value, _) {
                        if (value == 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            '\$${value.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.slateGrey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, _) {
                        final i = value.toInt();
                        if (i < 0 || i >= daily.length) {
                          return const SizedBox.shrink();
                        }
                        // Show date every ~5 days to avoid clutter
                        if (i % 5 != 0 && i != daily.length - 1) {
                          return const SizedBox.shrink();
                        }
                        final d = daily[i].date;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            DateFormat('MMM d').format(d.toLocal()),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.slateGrey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: _buildBarGroups(daily),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _Legend(),
        ],
      ),
    );
  }

  double _computeMaxY(List<CostFeatureDay> daily) {
    var maxTotal = 0.0;
    for (final d in daily) {
      if (d.total > maxTotal) maxTotal = d.total;
    }
    if (maxTotal <= 0) return 1;
    // Round up to a clean ceiling.
    final magnitude = (maxTotal * 1.15);
    return magnitude;
  }

  List<BarChartGroupData> _buildBarGroups(List<CostFeatureDay> daily) {
    return List.generate(daily.length, (i) {
      final day = daily[i];
      double cumulative = 0;
      final stackItems = <BarChartRodStackItem>[];
      for (final tool in _toolOrder) {
        final value = day.byTool[tool] ?? 0.0;
        if (value <= 0) continue;
        stackItems.add(
          BarChartRodStackItem(
            cumulative,
            cumulative + value,
            _colorFor(tool),
          ),
        );
        cumulative += value;
      }
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: cumulative,
            width: 8,
            color: AppColors.almondSilk,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(2),
              topRight: Radius.circular(2),
            ),
            rodStackItems: stackItems,
          ),
        ],
      );
    });
  }

  BarTooltipItem _buildTooltip(CostFeatureDay day) {
    final usd = NumberFormat.simpleCurrency(decimalDigits: 4);
    final lines = <TextSpan>[
      TextSpan(
        text: '${DateFormat('MMM d, yyyy').format(day.date.toLocal())}\n',
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          color: Colors.white,
          fontSize: 11,
        ),
      ),
      TextSpan(
        text: 'Total: ${usd.format(day.total)}\n\n',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    ];
    final sorted = day.byTool.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in sorted) {
      if (entry.value <= 0) continue;
      lines.add(TextSpan(
        text: '${_shortLabel(entry.key)}: ${usd.format(entry.value)}\n',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
        ),
      ));
    }
    return BarTooltipItem(
      '',
      const TextStyle(color: Colors.white),
      children: lines,
    );
  }
}

String _shortLabel(String tool) {
  switch (tool) {
    case 'cv':
      return 'CV';
    case 'coverLetter':
      return 'Cover Letter';
    case 'proposal':
      return 'Proposal';
    case 'linkedin':
      return 'LinkedIn';
    case 'clientExtract':
      return 'Client Extract';
    case 'clientChat':
      return 'Client Chat';
    case 'editorAI':
      return 'AI Assistant';
    case 'spellcheck':
      return 'Proofread';
    default:
      return tool;
  }
}

// ─── LEGEND ──────────────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: _toolOrder
          .map((t) => _LegendChip(color: _colorFor(t), label: _shortLabel(t)))
          .toList(),
    );
  }
}

class _LegendChip extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendChip({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.prussianBlue,
          ),
        ),
      ],
    );
  }
}

// ─── BREAKDOWN TABLE ─────────────────────────────────────────────────────

class _BreakdownTable extends StatelessWidget {
  final List<CostFeatureRow> features;
  const _BreakdownTable({required this.features});

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
          const _TableHeader(),
          for (var i = 0; i < features.length; i++) ...[
            const Divider(
              color: AppColors.almondSilk,
              height: 0,
              thickness: 0.3,
            ),
            _FeatureRow(row: features[i]),
          ],
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();
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
          SizedBox(width: 16),
          Expanded(flex: 5, child: _HCell('FEATURE')),
          Expanded(flex: 2, child: _HCell('SPEND', align: TextAlign.right)),
          Expanded(flex: 2, child: _HCell('SHARE', align: TextAlign.right)),
          Expanded(flex: 2, child: _HCell('CALLS', align: TextAlign.right)),
          Expanded(flex: 2, child: _HCell('FAILED', align: TextAlign.right)),
          Expanded(
            flex: 2,
            child: _HCell('REFUSED', align: TextAlign.right),
          ),
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

class _FeatureRow extends StatelessWidget {
  final CostFeatureRow row;
  const _FeatureRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final usd = NumberFormat.simpleCurrency(decimalDigits: 4);
    final color = _colorFor(row.tool);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Text(
              row.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.prussianBlue,
              ),
            ),
          ),
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
              '${row.sharePct.toStringAsFixed(1)}%',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.dustyMauve,
                fontWeight: FontWeight.w600,
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
            child: Text(
              '${row.refusalCount}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                color: row.refusalCount > 0
                    ? AppColors.magentaBloom
                    : AppColors.slateGrey,
              ),
            ),
          ),
        ],
      ),
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