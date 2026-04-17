import 'package:clinic_go/ui/symptoms/data/symptom_repository.dart';
import 'package:clinic_go/ui/symptoms/models/symptom_log.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final symptomHistoryProvider = FutureProvider.autoDispose<List<SymptomLog>>((
  ref,
) async {
  return ref.watch(symptomRepositoryProvider).fetchSymptomLogs();
});
