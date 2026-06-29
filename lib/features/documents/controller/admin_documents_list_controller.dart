// lib/features/documents/controller/admin_documents_list_controller.dart
//
// Step 23 — Documents List controller.
//
// Cursor-paginated list of one document type at a time. Default cv,
// admin can flip the type filter. Mirrors the AI Activity / Failures /
// Refusals "Load N more" pattern.

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── MODEL ───────────────────────────────────────────────────────────────

class AdminDocumentSummary {
  final String docId;
  final String type; // cv | coverLetter | proposal
  final String? uid;
  final String? ownerEmail;
  final String title;
  final String? templateId;
  final String status;
  final bool isArchived;
  final int exportCount;
  final int itemCount;
  final DateTime? lastExportedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AdminDocumentSummary({
    required this.docId,
    required this.type,
    required this.uid,
    required this.ownerEmail,
    required this.title,
    required this.templateId,
    required this.status,
    required this.isArchived,
    required this.exportCount,
    required this.itemCount,
    required this.lastExportedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminDocumentSummary.fromMap(Map<String, dynamic> m) {
    int i(dynamic v) => v is num ? v.toInt() : 0;
    DateTime? p(dynamic v) =>
        v is String ? DateTime.tryParse(v) : null;
    return AdminDocumentSummary(
      docId: (m['docId'] ?? '').toString(),
      type: (m['type'] ?? '').toString(),
      uid: m['uid'] as String?,
      ownerEmail: m['ownerEmail'] as String?,
      title: (m['title'] ?? '(untitled)').toString(),
      templateId: m['templateId'] as String?,
      status: (m['status'] ?? 'draft').toString(),
      isArchived: m['isArchived'] == true,
      exportCount: i(m['exportCount']),
      itemCount: i(m['itemCount']),
      lastExportedAt: p(m['lastExportedAt']),
      createdAt: p(m['createdAt']),
      updatedAt: p(m['updatedAt']),
    );
  }
}

// ─── STATE ───────────────────────────────────────────────────────────────

class AdminDocumentsListState {
  final List<AdminDocumentSummary> items;
  final String typeFilter; // cv | coverLetter | proposal
  final bool loading;
  final bool loadingMore;
  final String? cursor;
  final bool hasMore;
  final String? error;

  const AdminDocumentsListState({
    required this.items,
    required this.typeFilter,
    required this.loading,
    required this.loadingMore,
    required this.cursor,
    required this.hasMore,
    required this.error,
  });

  const AdminDocumentsListState.initial()
      : items = const [],
        typeFilter = 'cv',
        loading = true,
        loadingMore = false,
        cursor = null,
        hasMore = false,
        error = null;

  AdminDocumentsListState copyWith({
    List<AdminDocumentSummary>? items,
    String? typeFilter,
    bool? loading,
    bool? loadingMore,
    String? cursor,
    bool? hasMore,
    String? error,
    bool clearError = false,
    bool clearCursor = false,
  }) {
    return AdminDocumentsListState(
      items: items ?? this.items,
      typeFilter: typeFilter ?? this.typeFilter,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      cursor: clearCursor ? null : (cursor ?? this.cursor),
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─── CONTROLLER ──────────────────────────────────────────────────────────

class AdminDocumentsListController
    extends Notifier<AdminDocumentsListState> {
  @override
  AdminDocumentsListState build() {
    Future.microtask(refresh);
    return const AdminDocumentsListState.initial();
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
      final res = await _call(cursor: null);
      final items = (res['documents'] as List? ?? [])
          .map((e) => AdminDocumentSummary.fromMap(
          Map<String, dynamic>.from(e)))
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
    if (state.loadingMore || !state.hasMore || state.cursor == null) {
      return;
    }
    state = state.copyWith(loadingMore: true, clearError: true);
    try {
      final res = await _call(cursor: state.cursor);
      final more = (res['documents'] as List? ?? [])
          .map((e) => AdminDocumentSummary.fromMap(
          Map<String, dynamic>.from(e)))
          .toList();
      state = state.copyWith(
        items: [...state.items, ...more],
        cursor: res['nextCursor'] as String?,
        hasMore: res['hasMore'] == true,
        loadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(loadingMore: false, error: e.toString());
    }
  }

  void setType(String type) {
    if (type == state.typeFilter) return;
    state = state.copyWith(typeFilter: type);
    refresh();
  }

  Future<Map<String, dynamic>> _call({String? cursor}) async {
    final fn = FirebaseFunctions.instanceFor(region: 'us-central1')
        .httpsCallable(
      'adminListDocuments',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
    );
    final res = await fn.call({
      'type': state.typeFilter,
      'limit': 25,
      if (cursor != null) 'cursor': cursor,
    });
    return Map<String, dynamic>.from(res.data as Map);
  }
}

final adminDocumentsListProvider = NotifierProvider<
    AdminDocumentsListController, AdminDocumentsListState>(
  AdminDocumentsListController.new,
);