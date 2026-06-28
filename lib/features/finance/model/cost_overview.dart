class CostOverview {
  final int daysBack;
  final DateTime? refreshedAt;
  final double todayCost;
  final double weekCost;
  final double monthCost;
  final int todayCalls;
  final int weekCalls;
  final int monthCalls;
  final int totalCalls;
  final int totalFailures;
  final int totalRefusals;
  final int inputTokens;
  final int outputTokens;
  final int cacheReadTokens;
  final double cacheSavings;
  final List<DailySpend> dailySpend;
  final List<ModelBreakdown> byModel;
  final List<ToolBreakdown> byTool;

  const CostOverview({
    required this.daysBack,
    required this.refreshedAt,
    required this.todayCost,
    required this.weekCost,
    required this.monthCost,
    required this.todayCalls,
    required this.weekCalls,
    required this.monthCalls,
    required this.totalCalls,
    required this.totalFailures,
    required this.totalRefusals,
    required this.inputTokens,
    required this.outputTokens,
    required this.cacheReadTokens,
    required this.cacheSavings,
    required this.dailySpend,
    required this.byModel,
    required this.byTool,
  });

  factory CostOverview.fromMap(Map<String, dynamic> m) {
    double d(dynamic v) => v is num ? v.toDouble() : 0.0;
    int i(dynamic v) => v is num ? v.toInt() : 0;

    final totals = (m['totals'] as Map?) ?? const {};
    final callCounts = (m['callCounts'] as Map?) ?? const {};
    final tokens = (m['tokens'] as Map?) ?? const {};
    final daily = (m['dailySpend'] as List?) ?? const [];
    final byModel = (m['byModel'] as List?) ?? const [];
    final byTool = (m['byTool'] as List?) ?? const [];

    return CostOverview(
      daysBack: i(m['daysBack']),
      refreshedAt: m['refreshedAt'] is String
          ? DateTime.tryParse(m['refreshedAt'] as String)
          : null,
      todayCost: d(totals['today']),
      weekCost: d(totals['week']),
      monthCost: d(totals['month']),
      todayCalls: i(callCounts['today']),
      weekCalls: i(callCounts['week']),
      monthCalls: i(callCounts['month']),
      totalCalls: i(m['totalCalls']),
      totalFailures: i(m['totalFailures']),
      totalRefusals: i(m['totalRefusals']),
      inputTokens: i(tokens['input']),
      outputTokens: i(tokens['output']),
      cacheReadTokens: i(tokens['cacheRead']),
      cacheSavings: d(m['cacheSavings']),
      dailySpend: daily
          .map((e) => DailySpend.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      byModel: byModel
          .map((e) => ModelBreakdown.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      byTool: byTool
          .map((e) => ToolBreakdown.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class DailySpend {
  final String date; // YYYY-MM-DD
  final double cost;
  final int count;
  const DailySpend(
      {required this.date, required this.cost, required this.count});

  factory DailySpend.fromMap(Map<String, dynamic> m) => DailySpend(
    date: (m['date'] ?? '').toString(),
    cost: m['cost'] is num ? (m['cost'] as num).toDouble() : 0.0,
    count: m['count'] is num ? (m['count'] as num).toInt() : 0,
  );
}

class ModelBreakdown {
  final String model;
  final double cost;
  final int count;
  const ModelBreakdown(
      {required this.model, required this.cost, required this.count});

  factory ModelBreakdown.fromMap(Map<String, dynamic> m) => ModelBreakdown(
    model: (m['model'] ?? 'unknown').toString(),
    cost: m['cost'] is num ? (m['cost'] as num).toDouble() : 0.0,
    count: m['count'] is num ? (m['count'] as num).toInt() : 0,
  );
}

class ToolBreakdown {
  final String tool;
  final double cost;
  final int count;
  const ToolBreakdown(
      {required this.tool, required this.cost, required this.count});

  factory ToolBreakdown.fromMap(Map<String, dynamic> m) => ToolBreakdown(
    tool: (m['tool'] ?? 'unknown').toString(),
    cost: m['cost'] is num ? (m['cost'] as num).toDouble() : 0.0,
    count: m['count'] is num ? (m['count'] as num).toInt() : 0,
  );
}