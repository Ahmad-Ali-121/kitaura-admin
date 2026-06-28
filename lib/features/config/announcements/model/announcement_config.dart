/// Mirrors config/announcement in Firestore.
class AnnouncementConfig {
  final bool active;
  final String title;
  final String body;
  final String severity; // 'info' | 'warn' | 'critical'
  final String? linkUrl;
  final String? linkLabel;

  const AnnouncementConfig({
    required this.active,
    required this.title,
    required this.body,
    required this.severity,
    required this.linkUrl,
    required this.linkLabel,
  });

  static const validSeverities = <String>['info', 'warn', 'critical'];

  factory AnnouncementConfig.fromMap(Map<String, dynamic> map) {
    String? nullableStr(dynamic v) {
      if (v == null) return null;
      final s = v.toString();
      return s.isEmpty ? null : s;
    }

    return AnnouncementConfig(
      active: map['active'] == true,
      title: (map['title'] as String?) ?? '',
      body: (map['body'] as String?) ?? '',
      severity: (map['severity'] as String?) ?? 'info',
      linkUrl: nullableStr(map['linkUrl']),
      linkLabel: nullableStr(map['linkLabel']),
    );
  }

  AnnouncementConfig copyWith({
    bool? active,
    String? title,
    String? body,
    String? severity,
    String? linkUrl,
    String? linkLabel,
    bool clearLinkUrl = false,
    bool clearLinkLabel = false,
  }) {
    return AnnouncementConfig(
      active: active ?? this.active,
      title: title ?? this.title,
      body: body ?? this.body,
      severity: severity ?? this.severity,
      linkUrl: clearLinkUrl ? null : (linkUrl ?? this.linkUrl),
      linkLabel: clearLinkLabel ? null : (linkLabel ?? this.linkLabel),
    );
  }

  bool differsFrom(AnnouncementConfig other) {
    return active != other.active ||
        title != other.title ||
        body != other.body ||
        severity != other.severity ||
        linkUrl != other.linkUrl ||
        linkLabel != other.linkLabel;
  }

  static const empty = AnnouncementConfig(
    active: false,
    title: '',
    body: '',
    severity: 'info',
    linkUrl: null,
    linkLabel: null,
  );
}