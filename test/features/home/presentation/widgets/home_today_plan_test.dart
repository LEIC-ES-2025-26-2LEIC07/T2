import 'package:clinic_go/features/home/presentation/view_models/home_view_model.dart';
import 'package:clinic_go/features/home/presentation/widgets/home_today_plan.dart';
import 'package:clinic_go/features/medication/models/scheduled_dose.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../helpers/pump_app.dart';

ScheduledDose _dose(String name, DateTime time) => ScheduledDose(
  id: name,
  medicationId: 'm',
  medicationName: name,
  dosage: '100mg',
  scheduledTime: time,
);

TodayDoseEntry _entry(
  ScheduledDose dose, {
  required bool isPending,
  bool isOverdue = false,
}) => TodayDoseEntry(dose: dose, isPending: isPending, isOverdue: isOverdue);

void main() {
  group('HomeEmptyPlanCard', () {
    testWidgets('renders empty plan message', (tester) async {
      await tester.pumpApp(const HomeEmptyPlanCard());
      expect(find.text('Sem doses agendadas para hoje.'), findsOneWidget);
    });
  });

  group('HomeTodayPlanCard', () {
    testWidgets('renders all entries by medication name', (tester) async {
      final now = DateTime(2026, 5, 22, 10, 0);
      final entries = [
        _entry(
          _dose('Aspirin', now.add(const Duration(hours: 1))),
          isPending: true,
        ),
        _entry(
          _dose('Ibuprofen', now.add(const Duration(hours: 2))),
          isPending: false,
        ),
      ];
      await tester.pumpApp(HomeTodayPlanCard(entries: entries, now: now));
      expect(find.text('Aspirin 100mg'), findsOneWidget);
      expect(find.text('Ibuprofen 100mg'), findsOneWidget);
    });
  });

  group('HomeTodayPlanRow – status badges', () {
    testWidgets('done (isPending=false) → badge shows FEITO', (tester) async {
      final now = DateTime(2026, 5, 22, 10, 0);
      final entry = _entry(
        _dose('Aspirin', now.add(const Duration(hours: 1))),
        isPending: false,
      );
      await tester.pumpApp(HomeTodayPlanRow(entry: entry, now: now));
      expect(find.text('FEITO'), findsOneWidget);
    });

    testWidgets(
      'overdue (isPending=true, isOverdue=true) → badge shows EM ATRASO',
      (tester) async {
        final now = DateTime(2026, 5, 22, 10, 0);
        final entry = _entry(
          _dose('Aspirin', now.subtract(const Duration(minutes: 30))),
          isPending: true,
          isOverdue: true,
        );
        await tester.pumpApp(HomeTodayPlanRow(entry: entry, now: now));
        expect(find.text('EM ATRASO'), findsOneWidget);
      },
    );

    testWidgets('upcoming < 60 min → badge shows EM Xm', (tester) async {
      final now = DateTime(2026, 5, 22, 10, 0);
      final entry = _entry(
        _dose('Aspirin', DateTime(2026, 5, 22, 10, 30)),
        isPending: true,
      );
      await tester.pumpApp(HomeTodayPlanRow(entry: entry, now: now));
      expect(find.text('EM 30m'), findsOneWidget);
    });

    testWidgets('upcoming 1–19h → badge shows EM Xh', (tester) async {
      final now = DateTime(2026, 5, 22, 10, 0);
      final entry = _entry(
        _dose('Aspirin', DateTime(2026, 5, 22, 13, 0)),
        isPending: true,
      );
      await tester.pumpApp(HomeTodayPlanRow(entry: entry, now: now));
      expect(find.text('EM 3h'), findsOneWidget);
    });

    testWidgets('upcoming ≥ 20h → badge shows ESTA NOITE', (tester) async {
      final now = DateTime(2026, 5, 22, 10, 0);
      final entry = _entry(
        _dose('Aspirin', DateTime(2026, 5, 23, 8, 0)),
        isPending: true,
      );
      await tester.pumpApp(HomeTodayPlanRow(entry: entry, now: now));
      expect(find.text('ESTA NOITE'), findsOneWidget);
    });
  });
}
