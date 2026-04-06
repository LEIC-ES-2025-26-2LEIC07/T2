import 'package:flutter_test/flutter_test.dart';
import 'package:clinic_go/ui/favorites/view_models/favorites_view_model.dart';

void main() {
  group('FavoritesViewModel', () {
    late FavoritesViewModel vm;

    setUp(() {
      vm = FavoritesViewModel();
    });

    test('initial searchQuery is empty', () {
      expect(vm.searchQuery, '');
    });

    test('updateSearchQuery updates the query', () {
      vm.updateSearchQuery('cardio');
      expect(vm.searchQuery, 'cardio');
    });

    test('updateSearchQuery with empty string clears the query', () {
      vm.updateSearchQuery('yoga');
      vm.updateSearchQuery('');
      expect(vm.searchQuery, '');
    });

    test('updateSearchQuery notifies listeners', () {
      var notified = false;
      vm.addListener(() => notified = true);

      vm.updateSearchQuery('pilates');
      expect(notified, isTrue);
    });

    test('consecutive updates reflect the last value', () {
      vm.updateSearchQuery('first');
      vm.updateSearchQuery('second');
      vm.updateSearchQuery('third');
      expect(vm.searchQuery, 'third');
    });

    test('query is case-sensitive', () {
      vm.updateSearchQuery('Yoga');
      expect(vm.searchQuery, 'Yoga');
      expect(vm.searchQuery, isNot('yoga'));
    });
  });
}
