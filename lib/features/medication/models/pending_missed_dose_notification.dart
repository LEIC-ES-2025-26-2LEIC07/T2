import 'scheduled_dose.dart';

class PendingMissedDoseNotification {
  const PendingMissedDoseNotification({
    required this.dose,
    required this.notificationId,
    required this.scheduledTime,
  });

  final ScheduledDose dose;
  final int notificationId;
  final DateTime scheduledTime;

  Map<String, dynamic> toJson() => {
    'dose': dose.toJson(),
    'notificationId': notificationId,
    'scheduledTime': scheduledTime.toIso8601String(),
  };

  factory PendingMissedDoseNotification.fromJson(Map<String, dynamic> json) =>
      PendingMissedDoseNotification(
        dose: ScheduledDose.fromJson(
          Map<String, dynamic>.from(json['dose'] as Map),
        ),
        notificationId: json['notificationId'] as int,
        scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      );
}
