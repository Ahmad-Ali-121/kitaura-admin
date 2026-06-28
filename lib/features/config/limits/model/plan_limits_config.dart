/// Mirrors config/limits in Firestore.
class PlanLimitsConfig {
  /// 'free' | 'trial' | 'pro' → { field → int }
  final Map<String, Map<String, int>> plans;
  final int trialDays;
  final num proMonthlyPrice;

  const PlanLimitsConfig({
    required this.plans,
    required this.trialDays,
    required this.proMonthlyPrice,
  });

  static const planNames = <String>['free', 'trial', 'pro'];

  /// Field key → display label for the form.
  static const fieldLabels = <String, String>{
    'aiFillPerMonth': 'AI Compose / month',
    'aiRewritePerMonth': 'AI Refine / month',
    'aiEditPerMonth': 'AI Assistant / month',
    'aiEditHourlyBurst': 'AI Assistant hourly burst',
    'aiDesignPerMonth': 'AI Design / month',
    'exportsPerMonth': 'Exports / month',
    'maxDocs': 'Max documents',
    'historyVisibleActions': 'History visible',
    'spellcheckLimit': 'Spellcheck / month',
  };

  static List<String> get fieldKeys => fieldLabels.keys.toList();

  factory PlanLimitsConfig.fromMap(Map<String, dynamic> map) {
    Map<String, int> readPlan(dynamic raw) {
      final m = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
      return {
        for (final k in fieldKeys) k: (m[k] as num?)?.toInt() ?? -1,
      };
    }

    return PlanLimitsConfig(
      plans: {
        for (final p in planNames) p: readPlan(map[p]),
      },
      trialDays: (map['trialDays'] as num?)?.toInt() ?? 7,
      proMonthlyPrice: (map['proMonthlyPrice'] as num?) ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    for (final p in planNames) p: Map<String, int>.from(plans[p]!),
    'trialDays': trialDays,
    'proMonthlyPrice': proMonthlyPrice,
  };

  PlanLimitsConfig copyWith({
    Map<String, Map<String, int>>? plans,
    int? trialDays,
    num? proMonthlyPrice,
  }) {
    return PlanLimitsConfig(
      plans: plans ?? deepCopyPlans(this.plans),
      trialDays: trialDays ?? this.trialDays,
      proMonthlyPrice: proMonthlyPrice ?? this.proMonthlyPrice,
    );
  }

  /// Number of fields that differ between this and `other`.
  int diffCountTo(PlanLimitsConfig other) {
    var n = 0;
    for (final p in planNames) {
      for (final f in fieldKeys) {
        if (plans[p]![f] != other.plans[p]![f]) n++;
      }
    }
    if (trialDays != other.trialDays) n++;
    if (proMonthlyPrice != other.proMonthlyPrice) n++;
    return n;
  }

  static Map<String, Map<String, int>> deepCopyPlans(
      Map<String, Map<String, int>> src,
      ) =>
      {
        for (final entry in src.entries)
          entry.key: Map<String, int>.from(entry.value),
      };
}