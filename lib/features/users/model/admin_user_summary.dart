class AdminUserSummary {
  final String uid;
  final String? email;
  final String? displayName;
  final String plan;
  final bool trialActive;
  final DateTime? signupAt;
  final DateTime? lastActiveAt;
  final int docCount;
  final double mtdSpend;

  const AdminUserSummary({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.plan,
    required this.trialActive,
    required this.signupAt,
    required this.lastActiveAt,
    required this.docCount,
    required this.mtdSpend,
  });

  factory AdminUserSummary.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return AdminUserSummary(
      uid: (map['uid'] as String?) ?? '',
      email: map['email'] as String?,
      displayName: map['displayName'] as String?,
      plan: (map['plan'] as String?) ?? 'free',
      trialActive: map['trialActive'] == true,
      signupAt: parseDate(map['signupAt']),
      lastActiveAt: parseDate(map['lastActiveAt']),
      docCount: (map['docCount'] as num?)?.toInt() ?? 0,
      mtdSpend: (map['mtdSpend'] as num?)?.toDouble() ?? 0.0,
    );
  }
}