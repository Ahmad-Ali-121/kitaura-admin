/// Mirrors config/pricing in Firestore.
class PricingConfig {
  /// model name → { inputPerMTok, outputPerMTok, cacheReadMultiplier }
  final Map<String, Map<String, double>> models;

  const PricingConfig({required this.models});

  static const rateFields = <String>[
    'inputPerMTok',
    'outputPerMTok',
    'cacheReadMultiplier',
  ];

  static const rateLabels = <String, String>{
    'inputPerMTok': 'Input (\$ per MTok)',
    'outputPerMTok': 'Output (\$ per MTok)',
    'cacheReadMultiplier': 'Cache read multiplier',
  };

  static const rateHints = <String, String>{
    'inputPerMTok': 'e.g. 3.00 for Sonnet',
    'outputPerMTok': 'e.g. 15.00 for Sonnet',
    'cacheReadMultiplier': '0.1 = 10% of input cost on cache hit',
  };

  factory PricingConfig.fromMap(Map<String, dynamic> map) {
    final modelsRaw = map['models'];
    final modelsMap = <String, Map<String, double>>{};
    if (modelsRaw is Map) {
      for (final entry in modelsRaw.entries) {
        final modelKey = entry.key.toString();
        final rates = entry.value;
        if (rates is Map) {
          modelsMap[modelKey] = {
            for (final f in rateFields)
              f: (rates[f] as num?)?.toDouble() ?? 0.0,
          };
        }
      }
    }
    return PricingConfig(models: modelsMap);
  }

  Map<String, dynamic> toMap() => {
    'models': {
      for (final entry in models.entries)
        entry.key: Map<String, double>.from(entry.value),
    },
  };

  PricingConfig copyWith({Map<String, Map<String, double>>? models}) {
    return PricingConfig(models: models ?? _deepCopy(this.models));
  }

  int diffCountTo(PricingConfig other) {
    var n = 0;
    final allModels = {...models.keys, ...other.models.keys};
    for (final m in allModels) {
      final a = models[m];
      final b = other.models[m];
      if (a == null || b == null) {
        n += rateFields.length;
        continue;
      }
      for (final f in rateFields) {
        if (a[f] != b[f]) n++;
      }
    }
    return n;
  }

  static Map<String, Map<String, double>> _deepCopy(
      Map<String, Map<String, double>> src,
      ) =>
      {
        for (final e in src.entries) e.key: Map<String, double>.from(e.value),
      };
}