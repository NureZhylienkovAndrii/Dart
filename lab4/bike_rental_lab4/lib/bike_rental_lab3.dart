import 'dart:async';
import 'dart:isolate';

import 'bike_rental_lab2.dart';

export 'bike_rental_lab2.dart';

class AsyncRepository<T extends Identifiable> {
  AsyncRepository({this._delay = const Duration(milliseconds: 100)});

  final Duration _delay;
  final Map<String, T> _items = {};

  Future<void> save(T item) async {
    await Future<void>.delayed(_delay);
    _items[item.id] = item;
  }

  Future<T?> load(String id) async {
    await Future<void>.delayed(_delay);
    return _items[id];
  }

  Future<bool> delete(String id) async {
    await Future<void>.delayed(_delay);
    return _items.remove(id) != null;
  }

  Stream<T> watchAll() async* {
    print('Генератор watchAll запущено');

    for (final item in _items.values) {
      await Future<void>.delayed(_delay);
      yield item;
    }
  }

  int get count => _items.length;
}

class RentalEvent {
  const RentalEvent(this.rentalId, this.status);

  final String rentalId;
  final String status;

  @override
  String toString() => '$rentalId: $status';
}

Stream<RentalEvent> generateRentalEvents(
  List<RentalEvent> events, {
  Duration interval = const Duration(milliseconds: 50),
}) async* {
  print('Тіло async* почало виконуватися');

  for (final event in events) {
    await Future<void>.delayed(interval);
    yield event;
  }
}

Future<int> delayedOperation(
  int number, {
  Duration delay = const Duration(milliseconds: 500),
  bool shouldFail = false,
}) async {
  await Future<void>.delayed(delay);

  if (shouldFail) {
    throw StateError('Помилка операції $number');
  }

  return number * 10;
}

Future<int> measureSequential() async {
  final stopwatch = Stopwatch()..start();

  await delayedOperation(1);
  await delayedOperation(2);
  await delayedOperation(3);

  stopwatch.stop();
  return stopwatch.elapsedMilliseconds;
}

Future<int> measureConcurrent() async {
  final stopwatch = Stopwatch()..start();

  await Future.wait([
    delayedOperation(1),
    delayedOperation(2),
    delayedOperation(3),
  ]);

  stopwatch.stop();
  return stopwatch.elapsedMilliseconds;
}

int countPrimes(int limit) {
  var count = 0;

  for (var number = 2; number <= limit; number++) {
    var prime = true;

    for (var divisor = 2; divisor * divisor <= number; divisor++) {
      if (number % divisor == 0) {
        prime = false;
        break;
      }
    }

    if (prime) {
      count++;
    }
  }

  return count;
}

Future<int> countPrimesInIsolate(int limit) {
  return Isolate.run(() => countPrimes(limit));
}

int globalCounter = 0;

Future<int> modifyGlobalInIsolate() {
  return Isolate.run(() {
    globalCounter = 100;
    return globalCounter;
  });
}
