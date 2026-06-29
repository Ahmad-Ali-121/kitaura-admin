// lib/features/documents/controller/admin_document_inspector_controller.dart
//
// Step 23 — Document Inspector controller.
//
// FutureProvider.family keyed by (uid, type, docId) returning the full
// Firestore doc data hydrated with owner email.

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class DocRef {
  final String uid;
  final String type;
  final String docId;
  const DocRef({
    required this.uid,
    required this.type,
    required this.docId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          (other is DocRef &&
              uid == other.uid &&
              type == other.type &&
              docId == other.docId);

  @override
  int get hashCode => Object.hash(uid, type, docId);
}

class AdminDocument {
  final String docId;
  final String type;
  final String uid;
  final String? ownerEmail;
  final Map<String, dynamic> data;

  const AdminDocument({
    required this.docId,
    required this.type,
    required this.uid,
    required this.ownerEmail,
    required this.data,
  });

  factory AdminDocument.fromMap(Map<String, dynamic> m) {
    return AdminDocument(
      docId: (m['docId'] ?? '').toString(),
      type: (m['type'] ?? '').toString(),
      uid: (m['uid'] ?? '').toString(),
      ownerEmail: m['ownerEmail'] as String?,
      data: Map<String, dynamic>.from(m['data'] ?? {}),
    );
  }

  List<Map<String, dynamic>> get items {
    final raw = data['items'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }
}

final adminDocumentInspectorProvider =
FutureProvider.autoDispose.family<AdminDocument, DocRef>((ref, refKey) async {
  final fn = FirebaseFunctions.instanceFor(region: 'us-central1')
      .httpsCallable(
    'adminGetDocument',
    options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
  );
  final res = await fn.call({
    'uid': refKey.uid,
    'type': refKey.type,
    'docId': refKey.docId,
  });
  return AdminDocument.fromMap(Map<String, dynamic>.from(res.data as Map));
});