class EmergencyAlert {
  const EmergencyAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.severity = 'critical',
    this.acknowledgedAt,
    this.metadata = const {},
  });

  final String id;
  final String title;
  final String message;
  final String severity;
  final DateTime createdAt;
  final DateTime? acknowledgedAt;
  final Map<String, dynamic> metadata;

  bool get isAcknowledged => acknowledgedAt != null;

  EmergencyAlert copyWith({DateTime? acknowledgedAt}) => EmergencyAlert(
    id: id,
    title: title,
    message: message,
    severity: severity,
    createdAt: createdAt,
    acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
    metadata: metadata,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'severity': severity,
    'created_at': createdAt.toIso8601String(),
    'acknowledged_at': acknowledgedAt?.toIso8601String(),
    'metadata': metadata,
  };

  factory EmergencyAlert.fromJson(Map<String, dynamic> json) {
    final title = _string(json, 'title').trim();
    final message = _firstString(json, const [
      'message',
      'body',
      'description',
    ]).trim();

    return EmergencyAlert(
      id: _string(json, 'id'),
      title: title.isEmpty ? 'Emergency alert' : title,
      message: message.isEmpty
          ? 'A critical health alert needs your attention.'
          : message,
      severity: _string(json, 'severity').isEmpty
          ? 'critical'
          : _string(json, 'severity'),
      createdAt: _date(json['created_at']) ?? DateTime.now(),
      acknowledgedAt: _date(json['acknowledged_at']),
      metadata: json['metadata'] is Map<String, dynamic>
          ? json['metadata'] as Map<String, dynamic>
          : const {},
    );
  }

  static String _string(Map<String, dynamic> json, String key) {
    final value = json[key];
    return value == null ? '' : value.toString();
  }

  static String _firstString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = _string(json, key);
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  static DateTime? _date(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
