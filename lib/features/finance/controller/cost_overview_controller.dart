import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/services/admin_functions_service.dart';
import '../model/cost_overview.dart';

class CostOverviewState {
  final CostOverview? data;
  final bool loading;
  final String? error;

  const CostOverviewState({
    required this.data,
    required this.loading,
    required this.error,
  });

  const CostOverviewState.initial()
      : data = null,
        loading = true,
        error = null;

  CostOverviewState copyWith({
    CostOverview? data,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return CostOverviewState(
      data: data ?? this.data,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class CostOverviewController extends Notifier<CostOverviewState> {
  @override
  CostOverviewState build() {
    Future.microtask(refresh);
    return const CostOverviewState.initial();
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final raw = await AdminFunctionsService.getCostOverview(daysBack: 30);
      final data = CostOverview.fromMap(raw);
      state = state.copyWith(data: data, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}

final costOverviewProvider =
NotifierProvider<CostOverviewController, CostOverviewState>(
  CostOverviewController.new,
);