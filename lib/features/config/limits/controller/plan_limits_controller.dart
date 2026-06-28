import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/services/admin_functions_service.dart';
import '../model/plan_limits_config.dart';

class PlanLimitsState {
  final PlanLimitsConfig? original;
  final PlanLimitsConfig? edited;
  final bool loading;
  final bool saving;
  final String? error;

  const PlanLimitsState({
    required this.original,
    required this.edited,
    required this.loading,
    required this.saving,
    required this.error,
  });

  const PlanLimitsState.initial()
      : original = null,
        edited = null,
        loading = true,
        saving = false,
        error = null;

  bool get isDirty {
    if (original == null || edited == null) return false;
    return original!.diffCountTo(edited!) > 0;
  }

  int get changeCount {
    if (original == null || edited == null) return 0;
    return original!.diffCountTo(edited!);
  }

  PlanLimitsState copyWith({
    PlanLimitsConfig? original,
    PlanLimitsConfig? edited,
    bool? loading,
    bool? saving,
    String? error,
    bool clearError = false,
  }) {
    return PlanLimitsState(
      original: original ?? this.original,
      edited: edited ?? this.edited,
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PlanLimitsController extends Notifier<PlanLimitsState> {
  @override
  PlanLimitsState build() {
    Future.microtask(load);
    return const PlanLimitsState.initial();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final snap = await FirebaseFirestore.instance
          .doc('config/limits')
          .get();
      final config = PlanLimitsConfig.fromMap(
        snap.data() ?? <String, dynamic>{},
      );
      state = state.copyWith(
        original: config,
        edited: config.copyWith(),
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void updateField(String plan, String field, int value) {
    if (state.edited == null) return;
    final newPlans =
    PlanLimitsConfig.deepCopyPlans(state.edited!.plans);
    newPlans[plan]![field] = value;
    state = state.copyWith(
      edited: state.edited!.copyWith(plans: newPlans),
    );
  }

  void updateTrialDays(int value) {
    if (state.edited == null) return;
    state = state.copyWith(
      edited: state.edited!.copyWith(trialDays: value),
    );
  }

  void updateProMonthlyPrice(num value) {
    if (state.edited == null) return;
    state = state.copyWith(
      edited: state.edited!.copyWith(proMonthlyPrice: value),
    );
  }

  void discard() {
    if (state.original == null) return;
    state = state.copyWith(
      edited: state.original!.copyWith(),
      clearError: true,
    );
  }

  Future<void> save() async {
    if (state.edited == null || !state.isDirty) return;
    state = state.copyWith(saving: true, clearError: true);
    try {
      await AdminFunctionsService.updateConfig(
        docId: 'limits',
        newData: state.edited!.toMap(),
      );
      // Reload to pick up server timestamp + confirm
      await load();
      state = state.copyWith(saving: false);
    } catch (e) {
      state = state.copyWith(saving: false, error: e.toString());
      rethrow;
    }
  }
}

final planLimitsProvider =
NotifierProvider<PlanLimitsController, PlanLimitsState>(
  PlanLimitsController.new,
);