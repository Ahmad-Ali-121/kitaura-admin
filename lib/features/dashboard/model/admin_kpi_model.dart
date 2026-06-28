/// All KPI numbers returned by `adminGetDashboardKpis` Cloud Function.
class AdminKpis {
  final int totalUsers;
  final int activeToday;
  final int signupsThisWeek;
  final int activeTrials;
  final double mtdSpend;
  final int failures24h;
  final int refusals24h;
  final double cacheHitRate; // 0.0–1.0
  final List<TopSpender> topSpenders;
  final DateTime generatedAt;

  const AdminKpis({
    required this.totalUsers,
    required this.activeToday,
    required this.signupsThisWeek,
    required this.activeTrials,
    required this.mtdSpend,
    required this.failures24h,
    required this.refusals24h,
    required this.cacheHitRate,
    required this.topSpenders,
    required this.generatedAt,
  });

  factory AdminKpis.fromMap(Map<String, dynamic> map) {
    final spendersRaw = (map['topSpenders'] as List?) ?? const [];
    return AdminKpis(
      totalUsers: (map['totalUsers'] as num?)?.toInt() ?? 0,
      activeToday: (map['activeToday'] as num?)?.toInt() ?? 0,
      signupsThisWeek: (map['signupsThisWeek'] as num?)?.toInt() ?? 0,
      activeTrials: (map['activeTrials'] as num?)?.toInt() ?? 0,
      mtdSpend: (map['mtdSpend'] as num?)?.toDouble() ?? 0.0,
      failures24h: (map['failures24h'] as num?)?.toInt() ?? 0,
      refusals24h: (map['refusals24h'] as num?)?.toInt() ?? 0,
      cacheHitRate: (map['cacheHitRate'] as num?)?.toDouble() ?? 0.0,
      topSpenders: spendersRaw
          .whereType<Map>()
          .map((e) => TopSpender.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      generatedAt: map['generatedAt'] is String
          ? DateTime.parse(map['generatedAt'] as String)
          : DateTime.now(),
    );
  }
}

class TopSpender {
  final String uid;
  final String? email;
  final double spend;

  const TopSpender({
    required this.uid,
    required this.email,
    required this.spend,
  });

  factory TopSpender.fromMap(Map<String, dynamic> map) => TopSpender(
    uid: (map['uid'] as String?) ?? '',
    email: map['email'] as String?,
    spend: (map['spend'] as num?)?.toDouble() ?? 0.0,
  );
}