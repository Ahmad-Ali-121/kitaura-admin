import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/services/admin_functions_service.dart';
import '../model/pro_templates_config.dart';

class ProTemplatesState {
  final ProTemplatesConfig? original;
  final ProTemplatesConfig? edited;
  final bool loading;
  final bool saving;
  final String? error;

  const ProTemplatesState({
    required this.original,
    required this.edited,
    required this.loading,
    required this.saving,
    required this.error,
  });

  const ProTemplatesState.initial()
      : original = null,
        edited = null,
        loading = true,
        saving = false,
        error = null;

  bool get isDirty {
    if (original == null || edited == null) return false;
    final a = original!.proTemplates.toSet();
    final b = edited!.proTemplates.toSet();
    return a.length != b.length || !a.containsAll(b);
  }

  int get addedCount {
    if (original == null || edited == null) return 0;
    final a = original!.proTemplates.toSet();
    return edited!.proTemplates.where((id) => !a.contains(id)).length;
  }

  int get removedCount {
    if (original == null || edited == null) return 0;
    final b = edited!.proTemplates.toSet();
    return original!.proTemplates.where((id) => !b.contains(id)).length;
  }

  ProTemplatesState copyWith({
    ProTemplatesConfig? original,
    ProTemplatesConfig? edited,
    bool? loading,
    bool? saving,
    String? error,
    bool clearError = false,
  }) {
    return ProTemplatesState(
      original: original ?? this.original,
      edited: edited ?? this.edited,
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ProTemplatesController extends Notifier<ProTemplatesState> {
  @override
  ProTemplatesState build() {
    Future.microtask(load);
    return const ProTemplatesState.initial();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final snap = await FirebaseFirestore.instance
          .doc('config/proTemplates')
          .get();
      final cfg = ProTemplatesConfig.fromMap(snap.data() ?? const {});
      state = state.copyWith(
        original: cfg,
        edited: cfg.copyWith(),
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  /// Returns null on success, error message on failure.
  String? addTemplate(String id) {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return 'Template ID cannot be empty.';
    if (state.edited == null) return 'Not loaded yet.';
    if (state.edited!.proTemplates.contains(trimmed)) {
      return 'Already in the list.';
    }
    final newList = [...state.edited!.proTemplates, trimmed]..sort();
    state =
        state.copyWith(edited: state.edited!.copyWith(proTemplates: newList));
    return null;
  }

  void removeTemplate(String id) {
    if (state.edited == null) return;
    final newList =
    state.edited!.proTemplates.where((t) => t != id).toList();
    state =
        state.copyWith(edited: state.edited!.copyWith(proTemplates: newList));
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
        docId: 'proTemplates',
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

final proTemplatesProvider =
NotifierProvider<ProTemplatesController, ProTemplatesState>(
  ProTemplatesController.new,
);