// lib/features/finance/controller/admin_cost_by_user_controller.dart
//
// Step 20 — Cost by User controller.
//
// Holds page + sort state, hits adminGetCostByUser, exposes a list of
// CostByUserRow. Pagination from day 1 (25/page default).

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── MODEL ───────────────────────────────────────────────────────────────

class CostByUserRow {
  final String uid;
  final String? email;
  final String? plan;
  final double totalCost;
  final int callCount;
  final int failureCount;
  final int refusalCount;
  final double refusalRate; // 0.0–1.0
  final DateTime? lastActiveAt;

  const CostByUserRow({
    required this.uid,
    required this.email,
    required this.plan,
    required this.totalCost,
    required this.callCount,
    required this.failureCount,
    required this.refusalCount,
    required this.refusalRate,
    required this.lastActiveAt,
  });

  factory CostByUserRow.fromMap(Map<String, dynamic> m) {
    double d(dynamic v) => v is num ? v.toDouble() : 0.0;
    int i(dynamic v) => v is num ? v.toInt() : 0;
    return CostByUserRow(
      uid: (m['uid'] ?? '').toString(),
      email: m['email'] as String?,
      plan: m['plan'] as String?,
      totalCost: d(m['totalCost']),
      callCount: i(m['callCount']),
      failureCount: i(m['failureCount']),
      refusalCount: i(m['refusalCount']),
      refusalRate: d(m['refusalRate']),
      lastActiveAt: m['lastActiveAt'] is String
          ? DateTime.tryParse(m['lastActiveAt'])
          : null,
    );
  }
}

enum CostByUserSort { spend, refusalRate, callCount }

extension CostByUserSortX on CostByUserSort {
  String get apiKey {
    switch (this) {
      case CostByUserSort.spend:
        return 'spend';
      case CostByUserSort.refusalRate:
        return 'refusalRate';
      case CostByUserSort.callCount:
        return 'callCount';
    }
  }

  String get label {
    switch (this) {
      case CostByUserSort.spend:
        return 'Highest spend';
      case CostByUserSort.refusalRate:
        return 'Highest refusal rate';
      case CostByUserSort.callCount:
        return 'Most calls';
    }
  }
}

// ─── STATE ───────────────────────────────────────────────────────────────

class CostByUserState {
  final List<CostByUserRow> users;
  final int totalUsers;
  final int page;
  final int pageSize;
  final int totalPages;
  final CostByUserSort sortBy;
  final DateTime? windowStart;
  final DateTime? windowEnd;
  final bool loading;
  final String? error;

  const CostByUserState({
    required this.users,
    required this.totalUsers,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.sortBy,
    required this.windowStart,
    required this.windowEnd,
    required this.loading,
    required this.error,
  });

  const CostByUserState.initial()
      : users = const [],
        totalUsers = 0,
        page = 1,
        pageSize = 25,
        totalPages = 1,
        sortBy = CostByUserSort.spend,
        windowStart = null,
        windowEnd = null,
        loading = true,
        error = null;

  CostByUserState copyWith({
    List<CostByUserRow>? users,
    int? totalUsers,
    int? page,
    int? pageSize,
    int? totalPages,
    CostByUserSort? sortBy,
    DateTime? windowStart,
    DateTime? windowEnd,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return CostByUserState(
      users: users ?? this.users,
      totalUsers: totalUsers ?? this.totalUsers,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalPages: totalPages ?? this.totalPages,
      sortBy: sortBy ?? this.sortBy,
      windowStart: windowStart ?? this.windowStart,
      windowEnd: windowEnd ?? this.windowEnd,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─── CONTROLLER ──────────────────────────────────────────────────────────

class CostByUserController extends Notifier<CostByUserState> {
  @override
  CostByUserState build() {
    Future.microtask(() => _load(page: 1));
    return const CostByUserState.initial();
  }

  Future<void> refresh() => _load(page: state.page);
  Future<void> goToPage(int page) => _load(page: page);
  Future<void> setSort(CostByUserSort sort) {
    if (sort == state.sortBy) return Future.value();
    return _load(page: 1, sortBy: sort);
  }

  Future<void> _load({required int page, CostByUserSort? sortBy}) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final fn = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable(
        'adminGetCostByUser',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
      );
      final res = await fn.call({
        'page': page,
        'pageSize': state.pageSize,
        'sortBy': (sortBy ?? state.sortBy).apiKey,
      });
      final data = Map<String, dynamic>.from(res.data as Map);
      final users = (data['users'] as List? ?? [])
          .map((e) => CostByUserRow.fromMap(Map<String, dynamic>.from(e)))
          .toList();

      state = state.copyWith(
        users: users,
        totalUsers: (data['totalUsers'] as num?)?.toInt() ?? 0,
        page: (data['page'] as num?)?.toInt() ?? page,
        pageSize: (data['pageSize'] as num?)?.toInt() ?? state.pageSize,
        totalPages: (data['totalPages'] as num?)?.toInt() ?? 1,
        sortBy: sortBy ?? state.sortBy,
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

final costByUserProvider =
NotifierProvider<CostByUserController, CostByUserState>(
  CostByUserController.new,
);