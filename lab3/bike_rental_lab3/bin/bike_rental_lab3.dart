import 'dart:async';

import 'package:bike_rental_lab3/bike_rental_lab3.dart';

BikeRental createRental(int number) {
  return BikeRental(
    id: 'RENT-${number.toString().padLeft(3, '0')}',
    station: 'Центр',
    bikeType: BikeType.city,
    duration: 60,
    price: 120,
    date: DateTime(2026, 11, 9),
  );
}

void demonstrateUncaughtError() {
  try {
    // Навмисно без await: експеримент із методичних вказівок.
    unawaited(
      Future<void>.delayed(
        const Duration(milliseconds: 100),
        () => throw StateError('Неспіймана асинхронна помилка'),
      ),
    );

    print('Синхронний try/catch завершився');
  } catch (error) {
    print('Помилку спіймано: $error');
  }
}

Future<void> main(List<String> args) async {
  if (args.contains('uncaught')) {
    demonstrateUncaughtError();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return;
  }

  print('ЛАБОРАТОРНА РОБОТА 3');
  print('АСИНХРОННА ТА ПАРАЛЕЛЬНА ОБРОБКА ДАНИХ');

  final repository = AsyncRepository<BikeRental>();
  final rentals = [createRental(1), createRental(2), createRental(3)];

  print('\n1. АСИНХРОННЕ СХОВИЩЕ');

  for (final rental in rentals) {
    await repository.save(rental);
  }

  final loaded = await repository.load('RENT-001');
  print('Завантажено: ${loaded?.id}');
  print('Кількість об’єктів: ${repository.count}');

  final deleted = await repository.delete('RENT-003');
  print('Видалено RENT-003: $deleted');

  // Повертаємо третю оренду для наступних експериментів.
  await repository.save(rentals[2]);

  print('\n2. ЗАБУТИЙ AWAIT');

  final pending = repository.save(createRental(4));
  print('Одразу після виклику: ${repository.count}');

  await pending;
  print('Після await: ${repository.count}');

  print('\n3. ПОСЛІДОВНЕ ТА ОДНОЧАСНЕ ВИКОНАННЯ');

  final sequential = await measureSequential();
  final concurrent = await measureConcurrent();

  print('Послідовно: $sequential мс');
  print('Одночасно: $concurrent мс');

  print('\n4. ПОМИЛКИ FUTURE.WAIT');

  try {
    await Future.wait([
      delayedOperation(1, delay: const Duration(milliseconds: 50)),
      delayedOperation(
        2,
        delay: const Duration(milliseconds: 70),
        shouldFail: true,
      ),
      delayedOperation(3, delay: const Duration(milliseconds: 90)),
    ]);
  } catch (error) {
    print('Future.wait: $error');
  }

  print('\n5. ПОМИЛКИ PARALLELWAITERROR');

  try {
    await [
      delayedOperation(1, delay: const Duration(milliseconds: 50)),
      delayedOperation(
        2,
        delay: const Duration(milliseconds: 70),
        shouldFail: true,
      ),
      delayedOperation(3, delay: const Duration(milliseconds: 90)),
    ].wait;
  } on ParallelWaitError catch (error) {
    print('Тип помилки: ${error.runtimeType}');
    print('Успішні результати: ${error.values}');
    print('Помилки за позиціями: ${error.errors}');
    print('Кількість помилок: ${error.errors.where((e) => e != null).length}');
  }

  print('\n6. ASYNC* ТА ЛІНИВІСТЬ');

  final events = [
    const RentalEvent('RENT-001', 'Створено'),
    const RentalEvent('RENT-001', 'Активна'),
    const RentalEvent('RENT-001', 'Завершена'),
  ];

  final stream = generateRentalEvents(events);
  print('Потік створено, але підписки ще немає');

  await for (final event in stream) {
    print('await for: $event');
  }

  print('\n7. STREAMCONTROLLER ТА LISTEN');

  final controller = StreamController<RentalEvent>();

  controller.add(events[0]);
  controller.add(events[1]);
  controller.add(events[2]);

  print('Три події додано до підписки');

  final subscription = controller.stream.listen(
    (event) => print('listen: $event'),
    onError: (Object error) => print('Помилка: $error'),
    cancelOnError: false,
  );

  await Future<void>.delayed(const Duration(milliseconds: 50));
  await subscription.cancel();
  await controller.close();

  print('Підписку скасовано');

  print('\n8. ПОМИЛКА ВСЕРЕДИНІ ПОТОКУ');

  final errorController = StreamController<int>();

  final errorSubscription = errorController.stream.listen(
    (value) => print('listen отримав: $value'),
    onError: (Object error) => print('listen помилка: $error'),
    cancelOnError: false,
  );

  errorController.add(1);
  errorController.addError(StateError('Помилка потоку'));
  errorController.add(3);

  await Future<void>.delayed(const Duration(milliseconds: 50));
  await errorSubscription.cancel();
  await errorController.close();

  Stream<int> streamWithError() async* {
    yield 1;
    throw StateError('Помилка await for');
  }

  try {
    await for (final value in streamWithError()) {
      print('await for отримав: $value');
    }
  } catch (error) {
    print('await for перервано: $error');
  }

  print('\n9. ОДНОРАЗОВИЙ І BROADCAST-ПОТІК');

  final single = StreamController<int>();
  final firstSubscription = single.stream.listen((_) {});

  try {
    final secondSubscription = single.stream.listen((_) {});
    await secondSubscription.cancel();
  } catch (error) {
    print('Повторна підписка: $error');
  }

  await firstSubscription.cancel();
  await single.close();

  final broadcast = StreamController<int>.broadcast();

  final listener1 = broadcast.stream.listen(
    (value) => print('Слухач 1: $value'),
  );

  final listener2 = broadcast.stream.listen(
    (value) => print('Слухач 2: $value'),
  );

  broadcast.add(100);
  await Future<void>.delayed(const Duration(milliseconds: 30));

  await listener1.cancel();
  await listener2.cancel();
  await broadcast.close();

  print('\n10. КОНВЕЄР WHERE, MAP, TAKE');

  final pipeline = Stream.fromIterable(events)
      .where((event) => event.status != 'Створено')
      .map((event) => '${event.rentalId}: ${event.status}')
      .take(2);

  await for (final result in pipeline) {
    print(result);
  }

  print('\n11. ISOLATE.RUN');

  const limit = 300000;

  final directWatch = Stopwatch()..start();
  final directResult = countPrimes(limit);
  directWatch.stop();

  final isolateWatch = Stopwatch()..start();
  final isolateResult = await countPrimesInIsolate(limit);
  isolateWatch.stop();

  print(
    'Основний ізолят: ${directWatch.elapsedMilliseconds} мс, '
    'простих чисел: $directResult',
  );

  print(
    'Isolate.run: ${isolateWatch.elapsedMilliseconds} мс, '
    'простих чисел: $isolateResult',
  );

  print('\n12. ГЛОБАЛЬНИЙ СТАН');

  print('До запуску: $globalCounter');

  final isolateCounter = await modifyGlobalInIsolate();

  print('Всередині ізолята: $isolateCounter');
  print('У головному ізоляті: $globalCounter');

  print('\nРОБОТУ ПРОГРАМИ ЗАВЕРШЕНО');
}
