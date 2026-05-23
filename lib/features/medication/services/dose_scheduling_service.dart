import '../models/medication.dart';
import '../models/medication_reminder.dart';
import '../models/scheduled_dose.dart';

class DoseSchedulingService {
  const DoseSchedulingService();

  /// Calculates all doses for the given [medication] and its [reminders]
  /// that fall within the next [duration] (defaults to 24 hours).
  List<ScheduledDose> calculateUpcomingDoses(
    Medication medication,
    List<MedicationReminder> reminders, {
    Duration duration = const Duration(hours: 24),
    DateTime? from,
  }) {
    final now = from ?? DateTime.now();
    final end = now.add(duration);
    final doses = <ScheduledDose>[];

    final intervalDays = _parseIntervalDays(medication.frequency);

    for (final reminder in reminders) {
      if (!reminder.isActive) continue;

      // reminderTime is 'HH:mm:ss'
      final timeParts = reminder.reminderTime.split(':');
      if (timeParts.length < 2) continue;

      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      // Check each day within the window
      for (
        var date = DateTime(now.year, now.month, now.day);
        date.isBefore(end);
        date = date.add(const Duration(days: 1))
      ) {
        bool isDoseDay;
        if (intervalDays != null) {
          final ref = medication.startDate ?? medication.createdAt;
          final refDay = DateTime(ref.year, ref.month, ref.day);
          final diff = date.difference(refDay).inDays;
          isDoseDay = diff >= 0 && diff % intervalDays == 0;
        } else {
          final dayName = _getDayName(date.weekday);
          isDoseDay = reminder.daysOfWeek.contains(dayName);
        }
        if (!isDoseDay) continue;

        final scheduledTime = DateTime(
          date.year,
          date.month,
          date.day,
          hour,
          minute,
        );

        // Only include if it's within the [now, end] window
        if (scheduledTime.isAfter(now) && scheduledTime.isBefore(end)) {
          doses.add(
            ScheduledDose(
              id: _generateStableId(reminder.id!, scheduledTime),
              medicationId: medication.id,
              medicationName: medication.name,
              dosage: medication.dosageDisplay ?? '',
              scheduledTime: scheduledTime,
            ),
          );
        }
      }
    }

    // Sort by time
    doses.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    return doses;
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'monday';
      case DateTime.tuesday:
        return 'tuesday';
      case DateTime.wednesday:
        return 'wednesday';
      case DateTime.thursday:
        return 'thursday';
      case DateTime.friday:
        return 'friday';
      case DateTime.saturday:
        return 'saturday';
      case DateTime.sunday:
        return 'sunday';
      default:
        return '';
    }
  }

  int? _parseIntervalDays(String? frequency) {
    if (frequency == null) return null;
    if (frequency.startsWith('interval:')) {
      return int.tryParse(frequency.substring('interval:'.length));
    }
    return null;
  }

  String _generateStableId(String reminderId, DateTime time) {
    // Stable ID based on reminder and exact time to avoid duplicates
    final timestamp = time.millisecondsSinceEpoch ~/ 1000;
    return '${reminderId}_$timestamp';
  }
}
