// lib/features/users/controller/user_transactions_controller.dart
//
// User Transactions tab data layer.
//
// Admin custom claim grants read access to users/{uid}/transactions via
// Firestore security rules, so this is a straight Firestore read — no
// Cloud Function needed. Subcollection paths are auto-indexed by Firestore
// on createdAt, so no explicit index is required.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── MODEL ───────────────────────────────────────────────────────────────

class AdminTransaction {
  final String id;
  final String type;
  final String? tool;
  final String? documentId;
  final String? documentTitle;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;

  const AdminTransaction({
    required this.id,
    required this.type,
    this.tool,
    this.documentId,
    this.documentTitle,
    this.metadata = const {},
    this.createdAt,
  });

  factory AdminTransaction.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final created = data['createdAt'];
    DateTime? createdAt;
    if (created is Timestamp) {
      createdAt = created.toDate();
    } else if (created is String) {
      createdAt = DateTime.tryParse(created);
    }

    final rawMeta = data['metadata'];
    final metadata = rawMeta is Map
        ? Map<String, dynamic>.from(rawMeta)
        : const <String, dynamic>{};

    return AdminTransaction(
      id: doc.id,
      type: (data['type'] as String?) ?? 'unknown',
      tool: data['tool'] as String?,
      documentId: data['documentId'] as String?,
      documentTitle: data['documentTitle'] as String?,
      metadata: metadata,
      createdAt: createdAt,
    );
  }

  /// High-level grouping for the summary pills + chip color.
  TransactionCategory get category {
    switch (type) {
      case 'export':
        return TransactionCategory.export;
      case 'cvCreated':
      case 'coverLetterCreated':
      case 'proposalCreated':
        return TransactionCategory.docCreated;
      case 'cvDeleted':
      case 'coverLetterDeleted':
      case 'proposalDeleted':
        return TransactionCategory.docDeleted;
      case 'trialActivated':
      case 'planUpgrade':
      case 'planDowngrade':
      case 'planRenewal':
        return TransactionCategory.plan;
      default:
        return TransactionCategory.other;
    }
  }
}

enum TransactionCategory { export, docCreated, docDeleted, plan, other }

// ─── PROVIDER ────────────────────────────────────────────────────────────

/// Last 100 transactions for a user, newest first.
final userTransactionsProvider = FutureProvider.autoDispose
    .family<List<AdminTransaction>, String>((ref, uid) async {
  final snap = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('transactions')
      .orderBy('createdAt', descending: true)
      .limit(100)
      .get();

  return snap.docs.map(AdminTransaction.fromDoc).toList();
});