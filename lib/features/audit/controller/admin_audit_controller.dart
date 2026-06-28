import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/admin_activity.dart';

class AdminAuditState {
  final List<AdminActivity> items;
  final QueryDocumentSnapshot? lastDoc;
  final bool loading;
  final bool hasMore;
  final String? error;
  final String actionFilter; // 'all' or specific action name
  final String timeRange;    // '24h' | '7d' | '30d' | 'all'

  const AdminAuditState({
    required this.items,
    required this.lastDoc,
    required this.loading,
    required this.hasMore,
    required this.error,
    required this.actionFilter,
    required this.timeRange,
  });

  const AdminAuditState.initial()
      : items = const [],
        lastDoc = null,
        loading = true,
        hasMore = false,
        error = null,
        actionFilter = 'all',
        timeRange = '7d';

  AdminAuditState copyWith({
    List<AdminActivity>? items,
    QueryDocumentSnapshot? lastDoc,
    bool? loading,
    bool? hasMore,
    String? error,
    String? actionFilter,
    String? timeRange,
    bool clearError = false,
    bool clearCursor = false,
  }) {
    return AdminAuditState(
      items: items ?? this.items,
      lastDoc: clearCursor ? null : (lastDoc ?? this.lastDoc),
      loading: loading ?? this.loading,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
      actionFilter: actionFilter ?? this.actionFilter,
      timeRange: timeRange ?? this.timeRange,
    );
  }
}

class AdminAuditController extends Notifier<AdminAuditState> {
  static const _pageSize = 50;

  @override
  AdminAuditState build() {
    Future.microtask(() => load(reset: true));
    return const AdminAuditState.initial();
  }

  Future<void> load({bool reset = false}) async {
    if (state.loading && !reset) return;
    if (!reset && !state.hasMore) return;

    state = state.copyWith(loading: true, clearError: true);

    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('adminActivity')
          .orderBy('createdAt', descending: true);

      if (state.actionFilter != 'all') {
        query = query.where('action', isEqualTo: state.actionFilter);
      }

      final cutoff = _cutoffFor(state.timeRange);
      if (cutoff != null) {
        query = query.where(
          'createdAt',
          isGreaterThan: Timestamp.fromDate(cutoff),
        );
      }

      query = query.limit(_pageSize);

      if (!reset && state.lastDoc != null) {
        query = query.startAfterDocument(state.lastDoc!);
      }

      final snap = await query.get();
      final newItems = snap.docs.map(AdminActivity.fromDoc).toList();

      state = state.copyWith(
        items: reset ? newItems : [...state.items, ...newItems],
        lastDoc: snap.docs.isNotEmpty ? snap.docs.last : state.lastDoc,
        hasMore: snap.docs.length == _pageSize,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void setActionFilter(String value) {
    state = state.copyWith(
      actionFilter: value,
      items: const [],
      clearCursor: true,
    );
    load(reset: true);
  }

  void setTimeRange(String value) {
    state = state.copyWith(
      timeRange: value,
      items: const [],
      clearCursor: true,
    );
    load(reset: true);
  }

  DateTime? _cutoffFor(String range) {
    final now = DateTime.now();
    switch (range) {
      case '24h':
        return now.subtract(const Duration(hours: 24));
      case '7d':
        return now.subtract(const Duration(days: 7));
      case '30d':
        return now.subtract(const Duration(days: 30));
      case 'all':
      default:
        return null;
    }
  }
}

final adminAuditProvider =
NotifierProvider<AdminAuditController, AdminAuditState>(
  AdminAuditController.new,
);

/// Known action names — used by the filter dropdown.
const adminActionTypes = <String>[
  'all',
  'setAdminClaim',
  'revokeAdminClaim',
  'adminSetPlan',
  'adminResetCounters',
  'adminResetHourlyBurst',
  'adminResetRefusalCount',
  'adminExtendTrial',
  'adminUpdateConfig',
  'adminUpdateAnnouncement',
];