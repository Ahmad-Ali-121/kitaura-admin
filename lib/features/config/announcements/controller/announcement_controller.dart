import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/services/admin_functions_service.dart';
import '../model/announcement_config.dart';

class AnnouncementState {
  final AnnouncementConfig? original;
  final AnnouncementConfig? edited;
  final bool loading;
  final bool saving;
  final String? error;

  const AnnouncementState({
    required this.original,
    required this.edited,
    required this.loading,
    required this.saving,
    required this.error,
  });

  const AnnouncementState.initial()
      : original = null,
        edited = null,
        loading = true,
        saving = false,
        error = null;

  bool get isDirty =>
      original != null && edited != null && edited!.differsFrom(original!);

  AnnouncementState copyWith({
    AnnouncementConfig? original,
    AnnouncementConfig? edited,
    bool? loading,
    bool? saving,
    String? error,
    bool clearError = false,
  }) {
    return AnnouncementState(
      original: original ?? this.original,
      edited: edited ?? this.edited,
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AnnouncementController extends Notifier<AnnouncementState> {
  @override
  AnnouncementState build() {
    Future.microtask(load);
    return const AnnouncementState.initial();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final snap = await FirebaseFirestore.instance
          .doc('config/announcement')
          .get();
      final cfg = snap.exists
          ? AnnouncementConfig.fromMap(snap.data() ?? const {})
          : AnnouncementConfig.empty;
      state = state.copyWith(
        original: cfg,
        edited: cfg,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void update(AnnouncementConfig newEdited) {
    state = state.copyWith(edited: newEdited);
  }

  void discard() {
    if (state.original == null) return;
    state = state.copyWith(edited: state.original, clearError: true);
  }

  Future<void> save() async {
    if (state.edited == null || !state.isDirty) return;
    state = state.copyWith(saving: true, clearError: true);
    try {
      final e = state.edited!;
      await AdminFunctionsService.updateAnnouncement(
        active: e.active,
        title: e.title,
        body: e.body,
        severity: e.severity,
        linkUrl: e.linkUrl,
        linkLabel: e.linkLabel,
      );
      await load();
      state = state.copyWith(saving: false);
    } catch (e) {
      state = state.copyWith(saving: false, error: e.toString());
      rethrow;
    }
  }
}

final announcementProvider =
NotifierProvider<AnnouncementController, AnnouncementState>(
  AnnouncementController.new,
);