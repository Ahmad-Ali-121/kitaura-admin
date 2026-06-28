import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/services/admin_functions_service.dart';
import '../model/feature_flags_config.dart';

class FeatureFlagsState {
  final FeatureFlagsConfig? original;
  final FeatureFlagsConfig? edited;
  final bool loading;
  final bool saving;
  final String? error;

  const FeatureFlagsState({
    required this.original,
    required this.edited,
    required this.loading,
    required this.saving,
    required this.error,
  });

  const FeatureFlagsState.initial()
      : original = null,
        edited = null,
        loading = true,
        saving = false,
        error = null;

  bool get isDirty =>
      original != null &&
          edited != null &&
          original!.diffCountTo(edited!) > 0;

  int get changeCount => (original == null || edited == null)
      ? 0
      : original!.diffCountTo(edited!);

  FeatureFlagsState copyWith({
    FeatureFlagsConfig? original,
    FeatureFlagsConfig? edited,
    bool? loading,
    bool? saving,
    String? error,
    bool clearError = false,
  }) {
    return FeatureFlagsState(
      original: original ?? this.original,
      edited: edited ?? this.edited,
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class FeatureFlagsController extends Notifier<FeatureFlagsState> {
  @override
  FeatureFlagsState build() {
    Future.microtask(load);
    return const FeatureFlagsState.initial();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final snap = await FirebaseFirestore.instance
          .doc('config/featureFlags')
          .get();
      final cfg = FeatureFlagsConfig.fromMap(snap.data() ?? const {});
      state = state.copyWith(
        original: cfg,
        edited: cfg.copyWith(),
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void toggle(String key, bool value) {
    if (state.edited == null) return;
    final newFlags = Map<String, bool>.from(state.edited!.flags);
    newFlags[key] = value;
    state = state.copyWith(edited: state.edited!.copyWith(flags: newFlags));
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
        docId: 'featureFlags',
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

final featureFlagsProvider =
NotifierProvider<FeatureFlagsController, FeatureFlagsState>(
  FeatureFlagsController.new,
);