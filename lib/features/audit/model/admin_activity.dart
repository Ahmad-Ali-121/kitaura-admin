import 'package:cloud_firestore/cloud_firestore.dart';

class TargetRef {
  final String type; // 'user' | 'config' | 'system'
  final String? id;
  final String label;

  const TargetRef({
    required this.type,
    required this.id,
    required this.label,
  });

  factory TargetRef.fromMap(Map<String, dynamic> map) => TargetRef(
    type: (map['type'] as String?) ?? 'system',
    id: map['id'] as String?,
    label: (map['label'] as String?) ?? '(unknown)',
  );
}

class AdminActivity {
  final String id;
  final String adminUid;
  final String? adminEmail;
  final String action;
  final TargetRef target;
  final Map<String, dynamic> before;
  final Map<String, dynamic> after;
  final DateTime? createdAt;

  const AdminActivity({
    required this.id,
    required this.adminUid,
    required this.adminEmail,
    required this.action,
    required this.target,
    required this.before,
    required this.after,
    required this.createdAt,
  });

  factory AdminActivity.fromDoc(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    Map<String, dynamic> asMap(dynamic v) =>
        v is Map ? Map<String, dynamic>.from(v) : const {};
    return AdminActivity(
      id: doc.id,
      adminUid: (data['adminUid'] as String?) ?? '',
      adminEmail: data['adminEmail'] as String?,
      action: (data['action'] as String?) ?? 'unknown',
      target: TargetRef.fromMap(asMap(data['target'])),
      before: asMap(data['before']),
      after: asMap(data['after']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Human-readable inline diff between `before` and `after`.
  /// Example: "plan: free → pro · trialActive: true → false"
  String get diffSummary {
    final keys = {...before.keys, ...after.keys}.toList()..sort();
    final diffs = <String>[];
    for (final key in keys) {
      final b = before[key];
      final a = after[key];
      if (_stringify(b) != _stringify(a)) {
        diffs.add('$key: ${_stringify(b)} → ${_stringify(a)}');
      }
    }
    return diffs.isEmpty ? '(no field changes)' : diffs.join(' · ');
  }

  static String _stringify(dynamic v) {
    if (v == null) return '∅';
    if (v is String) return v;
    if (v is bool || v is num) return v.toString();
    return v.toString();
  }
}