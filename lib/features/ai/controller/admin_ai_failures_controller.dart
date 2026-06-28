import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/services/admin_functions_service.dart';
import '../model/ai_activity_summary.dart';

class AiFailuresState {
  final List<AiActivitySummary> items;
  final bool loading;
  final bool loadingMore;
  final String? cursor;
  final bool hasMore;
  final String? error;

  // Filters
  final String dateRange; // '24h' | '7d' | '30d' | 'all'
  final String toolFilter; // 'all' or specific
  final String userSearch;

  const AiFailuresState({
    required this.items,
    required this.loading,
    required this.loadingMore,
    required this.cursor,
    required this.hasMore,
    required this.error,
    required this.dateRange,
    required this.toolFilter,
    required this.userSearch,
  });

  const AiFailuresState.initial()
      : items = const [],
        loading = true,
        loadingMore = false,
        cursor = null,
        hasMore = false,
        error = null,
        dateRange = '24h',
        toolFilter = 'all',
        userSearch = '';

  AiFailuresState copyWith({
    List<AiActivitySummary>? items,
    bool? loading,
    bool? loadingMore,
    String? cursor,
    bool? hasMore,
    String? error,
    String? dateRange,
    String? toolFilter,
    String? userSearch,
    bool clearError = false,
    bool clearCursor = false,
  }) {
    return AiFailuresState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      cursor: clearCursor ? null : (cursor ?? this.cursor),
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
      dateRange: dateRange ?? this.dateRange,
      toolFilter: toolFilter ?? this.toolFilter,
      userSearch: userSearch ?? this.userSearch,
    );
  }

  List<AiActivitySummary> get filteredItems {
    return items.where((it) {
      if (toolFilter != 'all' && it.tool != toolFilter) return false;
      if (userSearch.isNotEmpty) {
        final q = userSearch.toLowerCase();
        final email = (it.userEmail ?? '').toLowerCase();
        final uid = (it.userId ?? '').toLowerCase();
        if (!email.contains(q) && !uid.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  /// Group filtered failures by their error message. Top groups first.
  /// Returns up to 10 entries.
  List<MapEntry<String, int>> get errorGroups {
    final map = <String, int>{};
    for (final it in filteredItems) {
      var key = (it.errorMessage ?? '(no error message)').trim();
      if (key.isEmpty) key = '(empty error message)';
      if (key.length > 100) key = '${key.substring(0, 97)}…';
      map[key] = (map[key] ?? 0) + 1;
    }
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(10).toList();
  }
}

class AiFailuresController extends Notifier<AiFailuresState> {
  @override
  AiFailuresState build() {
    Future.microtask(refresh);
    return const AiFailuresState.initial();
  }

  String? _startDateForRange(String range) {
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
        statusFilter: 'error',
      );
      final items = (res['items'] as List? ?? [])
          .map((e) =>
          AiActivitySummary.fromMap(Map<String, dynamic>.from(e)))
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
        statusFilter: 'error',
      );
      final newItems = (res['items'] as List? ?? [])
          .map((e) =>
          AiActivitySummary.fromMap(Map<String, dynamic>.from(e)))
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

  void setDateRange(String range) {
    if (range == state.dateRange) return;
    state = state.copyWith(dateRange: range);
    refresh();
  }

  void setToolFilter(String tool) {
    state = state.copyWith(toolFilter: tool);
  }

  void setUserSearch(String q) {
    state = state.copyWith(userSearch: q);
  }
}

final aiFailuresProvider =
NotifierProvider<AiFailuresController, AiFailuresState>(
  AiFailuresController.new,
);