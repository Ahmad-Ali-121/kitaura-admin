class UserDocumentSummary {
  final String id;
  final String title;
  final String? templateId;
  final String? thumbnailUrl;
  final String status;
  final bool isArchived;
  final int exportCount;
  final DateTime? lastExportedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? selectedProfileName;
  final String? targetCompany;
  final String? targetRole;
  final String? clientName;

  const UserDocumentSummary({
    required this.id,
    required this.title,
    required this.templateId,
    required this.thumbnailUrl,
    required this.status,
    required this.isArchived,
    required this.exportCount,
    required this.lastExportedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.selectedProfileName,
    required this.targetCompany,
    required this.targetRole,
    required this.clientName,
  });

  factory UserDocumentSummary.fromMap(Map<String, dynamic> m) {
    DateTime? d(dynamic v) =>
        v is String ? DateTime.tryParse(v) : null;
    int i(dynamic v) => v is num ? v.toInt() : 0;

    return UserDocumentSummary(
      id: (m['id'] ?? '').toString(),
      title: (m['title'] ?? '(untitled)').toString(),
      templateId: m['templateId'] as String?,
      thumbnailUrl: m['thumbnailUrl'] as String?,
      status: (m['status'] ?? 'draft').toString(),
      isArchived: m['isArchived'] == true,
      exportCount: i(m['exportCount']),
      lastExportedAt: d(m['lastExportedAt']),
      createdAt: d(m['createdAt']),
      updatedAt: d(m['updatedAt']),
      selectedProfileName: m['selectedProfileName'] as String?,
      targetCompany: m['targetCompany'] as String?,
      targetRole: m['targetRole'] as String?,
      clientName: m['clientName'] as String?,
    );
  }
}

class UserDocumentsBundle {
  final List<UserDocumentSummary> cvs;
  final List<UserDocumentSummary> coverLetters;
  final List<UserDocumentSummary> proposals;
  final int totalCount;

  const UserDocumentsBundle({
    required this.cvs,
    required this.coverLetters,
    required this.proposals,
    required this.totalCount,
  });

  factory UserDocumentsBundle.fromMap(Map<String, dynamic> m) {
    List<UserDocumentSummary> parseList(dynamic v) {
      if (v is List) {
        return v
            .map((e) =>
            UserDocumentSummary.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      }
      return const [];
    }

    final counts = (m['counts'] as Map?) ?? const {};
    return UserDocumentsBundle(
      cvs: parseList(m['cvs']),
      coverLetters: parseList(m['coverLetters']),
      proposals: parseList(m['proposals']),
      totalCount: counts['total'] is num
          ? (counts['total'] as num).toInt()
          : 0,
    );
  }
}