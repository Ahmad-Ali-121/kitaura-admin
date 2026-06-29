// lib/features/finance/controller/admin_cost_by_feature_controller.dart
//
// Step 21 — Cost by Feature controller.
//
// Single 30-day fetch. No filters, no pagination — there are 8 fixed
// tool buckets, and the time window is locked to 30 days to mirror
// Cost Overview.

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── MODELS ──────────────────────────────────────────────────────────────

class CostFeatureRow {
  final String tool;
  final String label;
  final double totalCost;
  final int callCount;
  final int failureCount;
  final int refusalCount;
  final double sharePct;

  const CostFeatureRow({
    required this.tool,
    required this.label,
    required this.totalCost,
    required this.callCount,
    required this.failureCount,
    required this.refusalCount,
    required this.sharePct,
  });

  factory CostFeatureRow.fromMap(Map<String, dynamic> m) {
    double d(dynamic v) => v is num ? v.toDouble() : 0.0;
    int i(dynamic v) => v is num ? v.toInt() : 0;
    return CostFeatureRow(
      tool: (m['tool'] ?? '').toString(),
      label: (m['label'] ?? m['tool'] ?? '').toString(),
      totalCost: d(m['totalCost']),
      callCount: i(m['callCount']),
      failureCount: i(m['failureCount']),
      refusalCount: i(m['refusalCount']),
      sharePct: d(m['sharePct']),
    );
  }
}

class CostFeatureDay {
  final DateTime date;
  final Map<String, double> byTool;

  const CostFeatureDay({required this.date, required this.byTool});

  factory CostFeatureDay.fromMap(Map<String, dynamic> m) {
    final raw = Map<String, dynamic>.from(m['byTool'] ?? {});
    final byTool = <String, double>{};
    raw.forEach((k, v) {
      byTool[k] = v is num ? v.toDouble() : 0.0;
    });
    final dateStr = (m['date'] ?? '').toString();
    final date = DateTime.tryParse(dateStr) ?? DateTime.now();
    return CostFeatureDay(date: date, byTool: byTool);
  }

  double get total {
    var t = 0.0;
    for (final v in byTool.values) {
      t += v;
    }
    return t;
  }
}

// ─── STATE ───────────────────────────────────────────────────────────────

class CostByFeatureState {
  final List<CostFeatureRow> features;
  final List<CostFeatureDay> daily;
  final double grandTotal;
  final int grandCalls;
  final DateTime? windowStart;
  final DateTime? windowEnd;
  final bool loading;
  final String? error;

  const CostByFeatureState({
    required this.features,
    required this.daily,
    required this.grandTotal,
    required this.grandCalls,
    required this.windowStart,
    required this.windowEnd,
    required this.loading,
    required this.error,
  });

  const CostByFeatureState.initial()
      : features = const [],
        daily = const [],
        grandTotal = 0,
        grandCalls = 0,
        windowStart = null,
        windowEnd = null,
        loading = true,
        error = null;

  CostByFeatureState copyWith({
    List<CostFeatureRow>? features,
    List<CostFeatureDay>? daily,
    double? grandTotal,
    int? grandCalls,
    DateTime? windowStart,
    DateTime? windowEnd,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return CostByFeatureState(
      features: features ?? this.features,
      daily: daily ?? this.daily,
      grandTotal: grandTotal ?? this.grandTotal,
      grandCalls: grandCalls ?? this.grandCalls,
      windowStart: windowStart ?? this.windowStart,
      windowEnd: windowEnd ?? this.windowEnd,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─── CONTROLLER ──────────────────────────────────────────────────────────

class CostByFeatureController extends Notifier<CostByFeatureState> {
  @override
  CostByFeatureState build() {
    Future.microtask(refresh);
    return const CostByFeatureState.initial();
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final fn = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable(
        'adminGetCostByFeature',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 120)),
      );
      final res = await fn.call();
      final data = Map<String, dynamic>.from(res.data as Map);

      final features = (data['features'] as List? ?? [])
          .map((e) => CostFeatureRow.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      final daily = (data['daily'] as List? ?? [])
          .map((e) => CostFeatureDay.fromMap(Map<String, dynamic>.from(e)))
          .toList();

      state = state.copyWith(
        features: features,
        daily: daily,
        grandTotal: (data['grandTotal'] as num?)?.toDouble() ?? 0.0,
        grandCalls: (data['grandCalls'] as num?)?.toInt() ?? 0,
        windowStart: data['windowStart'] is String
            ? DateTime.tryParse(data['windowStart'])
            : null,
        windowEnd: data['windowEnd'] is String
            ? DateTime.tryParse(data['windowEnd'])
            : null,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}

final costByFeatureProvider =
NotifierProvider<CostByFeatureController, CostByFeatureState>(
  CostByFeatureController.new,
);