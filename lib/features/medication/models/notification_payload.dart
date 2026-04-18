import 'dart:convert';

class NotificationPayload {
  const NotificationPayload({
    required this.route,
    required this.status,
    required this.doseId,
  });

  final String route;
  final String status;
  final String doseId;

  String encode() =>
      jsonEncode({'route': route, 'status': status, 'doseId': doseId});

  factory NotificationPayload.decode(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    return NotificationPayload(
      route: json['route'] as String,
      status: json['status'] as String,
      doseId: json['doseId'] as String,
    );
  }
}
