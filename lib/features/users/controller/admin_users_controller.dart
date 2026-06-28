import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/services/admin_functions_service.dart';
import '../model/admin_user_summary.dart';

class UsersListState {
  final String search;
  final String planFilter; // all | free | trial | pro
  final String sortBy;     // signupDesc | signupAsc | lastActive | spend | docs
  final int page;
  final int pageSize;
  final List<AdminUserSummary> items;
  final int total;
  final bool hasMore;
  final bool loading;
  final String? error;

  const UsersListState({
    required this.search,
    required this.planFilter,
    required this.sortBy,
    required this.page,
    required this.pageSize,
    required this.items,
    required this.total,
    required this.hasMore,
    required this.loading,
    required this.error,
  });

  const UsersListState.initial()
      : search = '',
        planFilter = 'all',
        sortBy = 'signupDesc',
        page = 0,
        pageSize = 50,
        items = const [],
        total = 0,
        hasMore = false,
        loading = true,
        error = null;

  UsersListState copyWith({
    String? search,
    String? planFilter,
    String? sortBy,
    int? page,
    int? pageSize,
    List<AdminUserSummary>? items,
    int? total,
    bool? hasMore,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return UsersListState(
      search: search ?? this.search,
      planFilter: planFilter ?? this.planFilter,
      sortBy: sortBy ?? this.sortBy,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      items: items ?? this.items,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  int get totalPages =>
      total == 0 ? 1 : ((total + pageSize - 1) ~/ pageSize);
}

class UsersListController extends Notifier<UsersListState> {
  Timer? _debounce;

  @override
  UsersListState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(load);
    return const UsersListState.initial();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final raw = await AdminFunctionsService.listUsers(
        page: state.page,
        pageSize: state.pageSize,
        search: state.search,
        planFilter: state.planFilter,
        sortBy: state.sortBy,
      );

      final itemsRaw = (raw['items'] as List?) ?? const [];
      final items = itemsRaw
          .whereType<Map>()
          .map((e) => AdminUserSummary.fromMap(Map<String, dynamic>.from(e)))
          .toList();

      state = state.copyWith(
        items: items,
        total: (raw['total'] as num?)?.toInt() ?? 0,
        hasMore: raw['hasMore'] == true,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void setSearch(String value) {
    state = state.copyWith(search: value, page: 0);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), load);
  }

  void setPlanFilter(String value) {
    state = state.copyWith(planFilter: value, page: 0);
    load();
  }

  void setSortBy(String value) {
    state = state.copyWith(sortBy: value, page: 0);
    load();
  }

  void setPage(int value) {
    if (value < 0) return;
    if (value >= state.totalPages) return;
    state = state.copyWith(page: value);
    load();
  }
}

final usersListProvider =
NotifierProvider<UsersListController, UsersListState>(
  UsersListController.new,
);