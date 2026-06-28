import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/services/admin_functions_service.dart';
import '../model/ai_activity_summary.dart';

/// 24h, 7d, 30d, all
typedef DateRangeKey = String;

class AiActivityState {
  final List<AiActivitySummary> items;
  final bool loading;
  final bool loadingMore;
  final String? cursor;
  final bool hasMore;
  final String? error;

  // Filters
  final DateRangeKey dateRange;
  final String toolFilter; // 'all' or specific
  final String statusFilter; // 'all' | 'success' | 'error' | 'refused' | 'cancelled'
  final String userSearch; // matches uid or email substring

  const AiActivityState({
    required this.items,
    required this.loading,
    required this.loadingMore,
    required this.cursor,
    required this.hasMore,
    required this.error,
    required this.dateRange,
    required this.toolFilter,
    required this.statusFilter,
    required this.userSearch,
  });

  const AiActivityState.initial()
      : items = const [],
        loading = true,
        loadingMore = false,
        cursor = null,
        hasMore = false,
        error = null,
        dateRange = '24h',
        toolFilter = 'all',
        statusFilter = 'all',
        userSearch = '';

  AiActivityState copyWith({
    List<AiActivitySummary>? items,
    bool? loading,
    bool? loadingMore,
    String? cursor,
    bool? hasMore,
    String? error,
    DateRangeKey? dateRange,
    String? toolFilter,
    String? statusFilter,
    String? userSearch,
    bool clearError = false,
    bool clearCursor = false,
  }) {
    return AiActivityState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      cursor: clearCursor ? null : (cursor ?? this.cursor),
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
      dateRange: dateRange ?? this.dateRange,
      toolFilter: toolFilter ?? this.toolFilter,
      statusFilter: statusFilter ?? this.statusFilter,
      userSearch: userSearch ?? this.userSearch,
    );
  }

  /// Apply client-side filters (tool/status/user search) on top of items.
  List<AiActivitySummary> get filteredItems {
    return items.where((it) {
      if (toolFilter != 'all' && it.tool != toolFilter) return false;
      if (statusFilter != 'all' && it.status != statusFilter) return false;
      if (userSearch.isNotEmpty) {
        final q = userSearch.toLowerCase();
        final email = (it.userEmail ?? '').toLowerCase();
        final uid = (it.userId ?? '').toLowerCase();
        if (!email.contains(q) && !uid.contains(q)) return false;
      }
      return true;
    }).toList();
  }
}

class AiActivityController extends Notifier<AiActivityState> {
  @override
  AiActivityState build() {
    Future.microtask(refresh);
    return const AiActivityState.initial();
  }

  String? _startDateForRange(DateRangeKey range) {
    final now = DateTime.now().toUtc();
    switch (range) {
      case '24h':
        return now.subtract(const Duration(hours: 24)).toIso8601String();
      case '7d':
        return now.subtract(const Duration(days: 7)).toIso8601String();
      case '30d':
        return now.subtract(const Duration(days: 30)).toIso8601String();
      case 'all':
      default:
        return null;
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(
      loading: true,
      clearError: true,
      clearCursor: true,
      items: [],
      hasMore: false,
    );
    try {
      final res = await AdminFunctionsService.listAiActivity(
        limit: 50,
        startDate: _startDateForRange(state.dateRange),
      );
      final items = (res['items'] as List? ?? [])
          .map((e) => AiActivitySummary.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      state = state.copyWith(
        items: items,
        cursor: res['nextCursor'] as String?,
        hasMore: res['hasMore'] == true,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore || state.cursor == null) return;
    state = state.copyWith(loadingMore: true, clearError: true);
    try {
      final res = await AdminFunctionsService.listAiActivity(
        limit: 50,
        cursor: state.cursor,
        startDate: _startDateForRange(state.dateRange),
      );
      final newItems = (res['items'] as List? ?? [])
          .map((e) => AiActivitySummary.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      state = state.copyWith(
        items: [...state.items, ...newItems],
        cursor: res['nextCursor'] as String?,
        hasMore: res['hasMore'] == true,
        loadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(loadingMore: false, error: e.toString());
    }
  }

  void setDateRange(DateRangeKey range) {
    if (range == state.dateRange) return;
    state = state.copyWith(dateRange: range);
    refresh();
  }

  void setToolFilter(String tool) {
    state = state.copyWith(toolFilter: tool);
  }

  void setStatusFilter(String status) {
    state = state.copyWith(statusFilter: status);
  }

  void setUserSearch(String q) {
    state = state.copyWith(userSearch: q);
  }
}

final aiActivityProvider =
NotifierProvider<AiActivityController, AiActivityState>(
  AiActivityController.new,
);