import 'dart:async';

import 'package:test/test.dart';
import 'package:bike_rental_lab3/bike_rental_lab3.dart';

BikeRental makeRental(int number) {
  return BikeRental(
    id: 'RENT-${number.toString().padLeft(3, '0')}',
    station: 'Центр',
    bikeType: BikeType.city,
    duration: 60,
    price: 120,
    date: DateTime(2026, 11, 9),
  );
}

void main() {
  late AsyncRepository<BikeRental> repository;

  setUp(() {
    repository = AsyncRepository<BikeRental>(
      delay: const Duration(milliseconds: 1),
    );
  });

  group('Асинхронне сховище', () {
    test('Збереження та завантаження', () async {
      final rental = makeRental(1);

      await repository.save(rental);
      final result = await repository.load(rental.id);

      expect(result, equals(rental));
    });

    test('Пошук відсутнього об’єкта', () async {
      final result = await repository.load('RENT-999');
      expect(result, isNull);
    });

    test('Видалення об’єкта', () async {
      final rental = makeRental(2);

      await repository.save(rental);
      final deleted = await repository.delete(rental.id);

      expect(deleted, isTrue);
      expect(await repository.load(rental.id), isNull);
    });

    test('Повторне видалення повертає false', () async {
      final deleted = await repository.delete('RENT-999');
      expect(deleted, isFalse);
    });
  });

  group('Потоки даних', () {
    test('Зберігається порядок подій', () async {
      final events = [
        const RentalEvent('RENT-001', 'Створено'),
        const RentalEvent('RENT-001', 'Активна'),
        const RentalEvent('RENT-001', 'Завершена'),
      ];

      final stream = generateRentalEvents(
        events,
        interval: Duration.zero,
      ).map((event) => event.status);

      await expectLater(
        stream,
        emitsInOrder(['Створено', 'Активна', 'Завершена', emitsDone]),
      );
    });

    test('watchAll видає всі збережені об’єкти', () async {
      await repository.save(makeRental(1));
      await repository.save(makeRental(2));

      await expectLater(
        repository.watchAll().map((rental) => rental.id),
        emitsInOrder(['RENT-001', 'RENT-002', emitsDone]),
      );
    });

    test('Помилка асинхронної операції', () async {
      await expectLater(
        delayedOperation(2, delay: Duration.zero, shouldFail: true),
        throwsA(isA<StateError>()),
      );
    });

    test('Помилка всередині потоку', () async {
      Stream<int> failingStream() async* {
        yield 1;
        throw StateError('Помилка тестового потоку');
      }

      await expectLater(
        failingStream(),
        emitsInOrder([1, emitsError(isA<StateError>())]),
      );
    });
  });

  group('Паралельне виконання', () {
    test('Future.wait повертає всі результати', () async {
      final result = await Future.wait([
        delayedOperation(1, delay: Duration.zero),
        delayedOperation(2, delay: Duration.zero),
        delayedOperation(3, delay: Duration.zero),
      ]);

      expect(result, [10, 20, 30]);
    });

    test('ParallelWaitError зберігає інформацію про помилку', () async {
      try {
        await [
          delayedOperation(1, delay: Duration.zero),
          delayedOperation(2, delay: Duration.zero, shouldFail: true),
          delayedOperation(3, delay: Duration.zero),
        ].wait;

        fail('Очікувалася помилка ParallelWaitError');
      } on ParallelWaitError catch (error) {
        expect(error.errors.where((e) => e != null).length, 1);
        expect(error.values[0], 10);
        expect(error.values[1], isNull);
        expect(error.values[2], 30);
      }
    });

    test('Ізолят повертає правильний результат', () async {
      final direct = countPrimes(1000);
      final isolated = await countPrimesInIsolate(1000);

      expect(isolated, direct);
      expect(isolated, 168);
    });

    test('Глобальний стан ізольований', () async {
      globalCounter = 0;

      final isolated = await modifyGlobalInIsolate();

      expect(isolated, 100);
      expect(globalCounter, 0);
    });
  });
}
