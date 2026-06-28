class AiActivitySummary {
  final String id;
  final String? userId;
  final String? userEmail;
  final String? tool;
  final String? type;
  final String? status;
  final String? sectionType;
  final String? documentId;
  final String? documentTitle;
  final String? templateId;
  final String? model;
  final double totalCost;
  final int inputTokens;
  final int outputTokens;
  final int cacheReadTokens;
  final int cacheCreationTokens;
  final String? errorMessage;
  final String? refusalReason;
  final List<String>? editorAiOps;
  final String? rewriteMode;
  final int durationMs;
  final DateTime? createdAt;

  const AiActivitySummary({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.tool,
    required this.type,
    required this.status,
    required this.sectionType,
    required this.documentId,
    required this.documentTitle,
    required this.templateId,
    required this.model,
    required this.totalCost,
    required this.inputTokens,
    required this.outputTokens,
    required this.cacheReadTokens,
    required this.cacheCreationTokens,
    required this.errorMessage,
    required this.refusalReason,
    required this.editorAiOps,
    required this.rewriteMode,
    required this.durationMs,
    required this.createdAt,
  });

  factory AiActivitySummary.fromMap(Map<String, dynamic> m) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    double parseDouble(dynamic v) {
      if (v is num) return v.toDouble();
      return 0.0;
    }

    int parseInt(dynamic v) {
      if (v is num) return v.toInt();
      return 0;
    }

    List<String>? parseOps(dynamic v) {
      if (v is List) return v.map((e) => e.toString()).toList();
      return null;
    }

    return AiActivitySummary(
      id: (m['id'] ?? '').toString(),
      userId: m['userId'] as String?,
      userEmail: m['userEmail'] as String?,
      tool: m['tool'] as String?,
      type: m['type'] as String?,
      status: m['status'] as String?,
      sectionType: m['sectionType'] as String?,
      documentId: m['documentId'] as String?,
      documentTitle: m['documentTitle'] as String?,
      templateId: m['templateId'] as String?,
      model: m['model'] as String?,
      totalCost: parseDouble(m['totalCost']),
      inputTokens: parseInt(m['inputTokens']),
      outputTokens: parseInt(m['outputTokens']),
      cacheReadTokens: parseInt(m['cacheReadTokens']),
      cacheCreationTokens: parseInt(m['cacheCreationTokens']),
      errorMessage: m['errorMessage'] as String?,
      refusalReason: m['refusalReason'] as String?,
      editorAiOps: parseOps(m['editorAiOps']),
      rewriteMode: m['rewriteMode'] as String?,
      durationMs: parseInt(m['durationMs']),
      createdAt: parseDate(m['createdAt']),
    );
  }
}