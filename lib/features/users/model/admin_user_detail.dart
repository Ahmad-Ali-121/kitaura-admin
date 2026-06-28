/// User Detail model. Keeps Firestore docs as raw maps for flexibility
/// (schema may evolve) but exposes typed getters for headline fields.
class AdminUserDetail {
  final String uid;
  final String currentMonth;
  final Map<String, dynamic> auth;
  final Map<String, dynamic>? profile;
  final Map<String, dynamic>? subscription;
  final Map<String, dynamic>? summary;
  final Map<String, dynamic>? monthly;

  const AdminUserDetail({
    required this.uid,
    required this.currentMonth,
    required this.auth,
    required this.profile,
    required this.subscription,
    required this.summary,
    required this.monthly,
  });

  factory AdminUserDetail.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic>? asMap(dynamic v) =>
        v is Map ? Map<String, dynamic>.from(v) : null;

    return AdminUserDetail(
      uid: (map['uid'] as String?) ?? '',
      currentMonth: (map['currentMonth'] as String?) ?? '',
      auth: asMap(map['auth']) ?? const {},
      profile: asMap(map['profile']),
      subscription: asMap(map['subscription']),
      summary: asMap(map['summary']),
      monthly: asMap(map['monthly']),
    );
  }

  // ─── Convenience getters ─────────────────────────────────────────────

  String? get email => auth['email'] as String?;
  String? get displayName =>
      (profile?['displayName'] as String?) ??
          (auth['displayName'] as String?);
  String? get photoUrl =>
      (profile?['photoUrl'] as String?) ??
          (auth['photoURL'] as String?);
  String? get phone => profile?['phone'] as String?;
  String? get location => profile?['location'] as String?;
  String? get bio => profile?['bio'] as String?;

  List<String> get providerIds {
    final raw = auth['providerIds'];
    if (raw is List) return raw.whereType<String>().toList();
    return const [];
  }

  bool get emailVerified => auth['emailVerified'] == true;
  bool get disabled => auth['disabled'] == true;
  bool get isAdminUser {
    final claims = auth['customClaims'];
    return claims is Map && claims['admin'] == true;
  }

  DateTime? get authCreatedAt => _parseDate(auth['creationTime']);
  DateTime? get authLastSignInAt => _parseDate(auth['lastSignInTime']);
  DateTime? get profileCreatedAt =>
      _parseDate(profile?['createdAt']);

  // Subscription
  String get plan => (subscription?['plan'] as String?) ?? 'free';
  bool get trialActive => subscription?['trialActive'] == true;
  bool get trialUsed => subscription?['trialUsed'] == true;
  DateTime? get cycleStart => _parseDate(subscription?['cycleStartDate']);
  DateTime? get cycleEnd => _parseDate(subscription?['cycleEndDate']);
  DateTime? get trialEnd => _parseDate(subscription?['trialEndDate']);

  int counter(String key) =>
      (subscription?[key] as num?)?.toInt() ?? 0;

  // Lifetime
  int summaryInt(String key) => (summary?[key] as num?)?.toInt() ?? 0;
  double summaryNum(String key) =>
      (summary?[key] as num?)?.toDouble() ?? 0.0;
  DateTime? get lastLoginAt => _parseDate(summary?['lastLoginAt']);
  DateTime? get lastActiveAt => _parseDate(summary?['lastActiveAt']);

  // Month
  double get mtdSpend =>
      (monthly?['totalCost'] as num?)?.toDouble() ?? 0.0;
  int monthInt(String key) => (monthly?[key] as num?)?.toInt() ?? 0;

  static DateTime? _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}