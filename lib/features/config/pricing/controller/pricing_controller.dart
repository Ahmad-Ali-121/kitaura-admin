import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/services/admin_functions_service.dart';
import '../model/pricing_config.dart';

class PricingState {
  final PricingConfig? original;
  final PricingConfig? edited;
  final bool loading;
  final bool saving;
  final String? error;

  const PricingState({
    required this.original,
    required this.edited,
    required this.loading,
    required this.saving,
    required this.error,
  });

  const PricingState.initial()
      : original = null,
        edited = null,
        loading = true,
        saving = false,
        error = null;

  bool get isDirty =>
      original != null &&
          edited != null &&
          original!.diffCountTo(edited!) > 0;

  int get changeCount =>
      (original == null || edited == null)
          ? 0
          : original!.diffCountTo(edited!);

  PricingState copyWith({
    PricingConfig? original,
    PricingConfig? edited,
    bool? loading,
    bool? saving,
    String? error,
    bool clearError = false,
  }) {
    return PricingState(
      original: original ?? this.original,
      edited: edited ?? this.edited,
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PricingController extends Notifier<PricingState> {
  @override
  PricingState build() {
    Future.microtask(load);
    return const PricingState.initial();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final snap = await FirebaseFirestore.instance
          .doc('config/pricing')
          .get();
      final cfg = PricingConfig.fromMap(snap.data() ?? const {});
      state = state.copyWith(
        original: cfg,
        edited: cfg.copyWith(),
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void updateRate(String model, String field, double value) {
    if (state.edited == null) return;
    final newModels = {
      for (final e in state.edited!.models.entries)
        e.key: Map<String, double>.from(e.value),
    };
    newModels[model]![field] = value;
    state =
        state.copyWith(edited: state.edited!.copyWith(models: newModels));
  }

  void discard() {
    if (state.original == null) return;
    state =
        state.copyWith(edited: state.original!.copyWith(), clearError: true);
  }

  Future<void> save() async {
    if (state.edited == null || !state.isDirty) return;
    state = state.copyWith(saving: true, clearError: true);
    try {
      await AdminFunctionsService.updateConfig(
        docId: 'pricing',
        newData: state.edited!.toMap(),
      );
      await load();
      state = state.copyWith(saving: false);
    } catch (e) {
      state = state.copyWith(saving: false, error: e.toString());
      rethrow;
    }
  }
}

final pricingProvider =
NotifierProvider<PricingController, PricingState>(
  PricingController.new,
);