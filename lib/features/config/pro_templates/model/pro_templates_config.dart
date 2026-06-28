/// Mirrors config/proTemplates in Firestore.
/// Just a flat list of template IDs that require Pro to export.
class ProTemplatesConfig {
  final List<String> proTemplates;

  const ProTemplatesConfig({required this.proTemplates});

  factory ProTemplatesConfig.fromMap(Map<String, dynamic> map) {
    final raw = map['proTemplates'];
    if (raw is List) {
      return ProTemplatesConfig(
        proTemplates: raw.whereType<String>().toList(),
      );
    }
    return const ProTemplatesConfig(proTemplates: []);
  }

  Map<String, dynamic> toMap() => {
    'proTemplates': List<String>.from(proTemplates),
  };

  ProTemplatesConfig copyWith({List<String>? proTemplates}) {
    return ProTemplatesConfig(
      proTemplates: proTemplates ?? List<String>.from(this.proTemplates),
    );
  }

  /// Categorize a template ID by naming convention.
  /// 'cl_*' → cover letter, 'prop_*' → proposal, else → CV.
  static String categoryOf(String id) {
    if (id.startsWith('cl_')) return 'Cover Letter';
    if (id.startsWith('prop_')) return 'Proposal';
    return 'CV';
  }
}