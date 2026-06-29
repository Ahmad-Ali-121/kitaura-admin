// lib/features/abuse/controller/admin_abuse_controller.dart
//
// Step 22 — Abuse Monitor controller.
//
// Single-shot load of flagged users from adminGetAbuseMonitor.

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── MODELS ──────────────────────────────────────────────────────────────

enum AbuseSignal { refusals, burst, costOutlier }

extension AbuseSignalX on AbuseSignal {
  static AbuseSignal? fromString(String raw) {
    switch (raw) {
      case 'refusals':
        return AbuseSignal.refusals;
      case 'burst':
        return AbuseSignal.burst;
      case 'costOutlier':
        return AbuseSignal.costOutlier;
      default:
        return null;
    }
  }

  String get label {
    switch (this) {
      case AbuseSignal.refusals:
        return 'Refusals';
      case AbuseSignal.burst:
        return 'Hourly burst';
      case AbuseSignal.costOutlier:
        return 'High spend';
    }
  }
}

class FlaggedUser {
  final String uid;
  final String? email;
  final String plan;
  final int refusalCount;
  final int hourlyCount;
  final DateTime? hourlyResetAt;
  final int monthlyCount;
  final double totalCost;
  final List<AbuseSignal> signals;
  final int severity;

  const FlaggedUser({
    required this.uid,
    required this.email,
    required this.plan,
    required this.refusalCount,
    required this.hourlyCount,
    required this.hourlyResetAt,
    required this.monthlyCount,
    required this.totalCost,
    required this.signals,
    required this.severity,
  });

  factory FlaggedUser.fromMap(Map<String, dynamic> m) {
    double d(dynamic v) => v is num ? v.toDouble() : 0.0;
    int i(dynamic v) => v is num ? v.toInt() : 0;
    final rawSignals = (m['signals'] as List? ?? []);
    final signals = rawSignals
        .map((s) => AbuseSignalX.fromString(s.toString()))
        .whereType<AbuseSignal>()
        .toList();
    return FlaggedUser(
      uid: (m['uid'] ?? '').toString(),
      email: m['email'] as String?,
      plan: (m['plan'] ?? 'free').toString(),
      refusalCount: i(m['refusalCount']),
      hourlyCount: i(m['hourlyCount']),
      hourlyResetAt: m['hourlyResetAt'] is String
          ? DateTime.tryParse(m['hourlyResetAt'])
          : null,
      monthlyCount: i(m['monthlyCount']),
      totalCost: d(m['totalCost']),
      signals: signals,
      severity: i(m['severity']),
    );
  }
}

class AbuseThresholds {
  final int refusalThreshold;
  final int burstThreshold;
  final double outlierThreshold;
  final double outlierPercentile;

  const AbuseThresholds({
    required this.refusalThreshold,
    required this.burstThreshold,
    required this.outlierThreshold,
    required this.outlierPercentile,
  });

  factory AbuseThresholds.fromMap(Map<String, dynamic> m) {
    double d(dynamic v) => v is num ? v.toDouble() : 0.0;
    int i(dynamic v) => v is num ? v.toInt() : 0;
    return AbuseThresholds(
      refusalThreshold: i(m['refusalThreshold']),
      burstThreshold: i(m['burstThreshold']),
      outlierThreshold: d(m['outlierThreshold']),
      outlierPercentile: d(m['outlierPercentile']),
    );
  }
}

class AbuseSummary {
  final int refusalUsers;
  final int burstUsers;
  final int costOutlierUsers;
  final int multiSignalUsers;
  const AbuseSummary({
    required this.refusalUsers,
    required this.burstUsers,
    required this.costOutlierUsers,
    required this.multiSignalUsers,
  });
  factory AbuseSummary.fromMap(Map<String, dynamic> m) {
    int i(dynamic v) => v is num ? v.toInt() : 0;
    return AbuseSummary(
      refusalUsers: i(m['refusalUsers']),
      burstUsers: i(m['burstUsers']),
      costOutlierUsers: i(m['costOutlierUsers']),
      multiSignalUsers: i(m['multiSignalUsers']),
    );
  }
}

// ─── STATE ───────────────────────────────────────────────────────────────

class AbuseMonitorState {
  final List<FlaggedUser> flagged;
  final AbuseSummary summary;
  final AbuseThresholds? thresholds;
  final DateTime? windowStart;
  final DateTime? windowEnd;
  final bool loading;
  final String? error;

  const AbuseMonitorState({
    required this.flagged,
    required this.summary,
    required this.thresholds,
    required this.windowStart,
    required this.windowEnd,
    required this.loading,
    required this.error,
  });

  const AbuseMonitorState.initial()
      : flagged = const [],
        summary = const AbuseSummary(
          refusalUsers: 0,
          burstUsers: 0,
          costOutlierUsers: 0,
          multiSignalUsers: 0,
        ),
        thresholds = null,
        windowStart = null,
        windowEnd = null,
        loading = true,
        error = null;

  AbuseMonitorState copyWith({
    List<FlaggedUser>? flagged,
    AbuseSummary? summary,
    AbuseThresholds? thresholds,
    DateTime? windowStart,
    DateTime? windowEnd,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return AbuseMonitorState(
      flagged: flagged ?? this.flagged,
      summary: summary ?? this.summary,
      thresholds: thresholds ?? this.thresholds,
      windowStart: windowStart ?? this.windowStart,
      windowEnd: windowEnd ?? this.windowEnd,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─── CONTROLLER ──────────────────────────────────────────────────────────

class AbuseMonitorController extends Notifier<AbuseMonitorState> {
  @override
  AbuseMonitorState build() {
    Future.microtask(refresh);
    return const AbuseMonitorState.initial();
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final fn = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable(
        'adminGetAbuseMonitor',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 120)),
      );
      final res = await fn.call();
      final data = Map<String, dynamic>.from(res.data as Map);

      final flagged = (data['flagged'] as List? ?? [])
          .map((e) => FlaggedUser.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      final summary =
      AbuseSummary.fromMap(Map<String, dynamic>.from(data['summary'] ?? {}));
      final thresholds = data['thresholds'] != null
          ? AbuseThresholds.fromMap(
          Map<String, dynamic>.from(data['thresholds']))
          : null;

      state = state.copyWith(
        flagged: flagged,
        summary: summary,
        thresholds: thresholds,
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

final abuseMonitorProvider =
NotifierProvider<AbuseMonitorController, AbuseMonitorState>(
  AbuseMonitorController.new,
);