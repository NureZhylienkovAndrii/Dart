import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:bike_rental_lab4/bike_rental_lab4.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

BikeRental makeRental({String id = 'RENT-001', String station = 'Центр'}) {
  return BikeRental(
    id: id,
    station: station,
    bikeType: 'city',
    duration: 60,
    price: 120,
    date: DateTime(2026, 11, 13),
  );
}

void main() {
  late Directory directory;
  late FileRentalRepository repository;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('bike_rental_test_');
    repository = FileRentalRepository(
      '${directory.path}${Platform.pathSeparator}rentals.json',
    );
  });

  tearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  group('JSON-серіалізація', () {
    test('Об’єкт перетворюється в JSON і назад', () {
      final rental = makeRental();
      final restored = BikeRental.fromJson(rental.toJson());

      expect(restored.id, rental.id);
      expect(restored.station, rental.station);
      expect(restored.duration, rental.duration);
      expect(restored.price, rental.price);
      expect(restored.date, rental.date);
    });

    test('Некоректний тип поля викликає FormatException', () {
      final json = makeRental().toJson();
      json['duration'] = 'invalid';

      expect(() => BikeRental.fromJson(json), throwsA(isA<FormatException>()));
    });

    test('Від’ємна вартість відхиляється', () {
      final json = makeRental().toJson();
      json['price'] = -100;

      expect(() => BikeRental.fromJson(json), throwsA(isA<FormatException>()));
    });
  });

  group('Файлове сховище', () {
    test('Відсутній файл повертає порожній список', () async {
      expect(await repository.loadAll(), isEmpty);
    });

    test('Збереження та завантаження запису', () async {
      await repository.add(makeRental());

      final rentals = await repository.loadAll();

      expect(rentals, hasLength(1));
      expect(rentals.first.id, 'RENT-001');
    });

    test('Пошук за ідентифікатором', () async {
      await repository.add(makeRental());

      final rental = await repository.findById('RENT-001');

      expect(rental, isNotNull);
      expect(rental!.station, 'Центр');
    });

    test('Відсутній ідентифікатор повертає null', () async {
      expect(await repository.findById('RENT-999'), isNull);
    });

    test('Повторний ідентифікатор відхиляється', () async {
      await repository.add(makeRental());

      await expectLater(
        repository.add(makeRental()),
        throwsA(isA<StateError>()),
      );
    });

    test('Фільтрація за станцією', () async {
      await repository.add(makeRental());
      await repository.add(makeRental(id: 'RENT-002', station: 'Вокзал'));

      final rentals = await repository.findByStation('Центр');

      expect(rentals, hasLength(1));
      expect(rentals.first.id, 'RENT-001');
    });

    test('Потокове читання текстового файлу', () async {
      final file = File('${directory.path}${Platform.pathSeparator}large.txt');

      await file.writeAsString('Перший\n\nДругий\nТретій\n');

      expect(await repository.countLines(file.path), 3);
    });
  });

  group('Аргументи CLI', () {
    test('Розпізнавання команди та опцій', () {
      final parser = RentalCli.buildParser();

      final result = parser.parse(['list', '--station', 'Центр']);

      expect(result.rest, ['list']);
      expect(result['station'], 'Центр');
    });

    test('Значення опцій за замовчуванням', () {
      final result = RentalCli.buildParser().parse(['add']);

      expect(result['type'], 'city');
      expect(result['duration'], '60');
      expect(result['price'], '120');
    });

    test('Невідома опція викликає помилку', () {
      expect(
        () => RentalCli.buildParser().parse(['--unknown']),
        throwsA(isA<ArgParserException>()),
      );
    });
  });

  group('HTTP-сервіс', () {
    late Handler handler;

    setUp(() {
      handler = buildRentalHandler(repository);
    });

    test('GET /items повертає список', () async {
      await repository.add(makeRental());

      final response = await handler(
        Request('GET', Uri.parse('http://localhost/items')),
      );

      final body = jsonDecode(await response.readAsString()) as List;

      expect(response.statusCode, 200);
      expect(body, hasLength(1));
      expect(response.headers['content-type'], contains('application/json'));
    });

    test('GET /items підтримує фільтрацію', () async {
      await repository.add(makeRental());
      await repository.add(makeRental(id: 'RENT-002', station: 'Вокзал'));

      final response = await handler(
        Request('GET', Uri.parse('http://localhost/items?station=Центр')),
      );

      final body = jsonDecode(await response.readAsString()) as List;

      expect(response.statusCode, 200);
      expect(body, hasLength(1));
    });

    test('GET /items/id повертає запис', () async {
      await repository.add(makeRental());

      final response = await handler(
        Request('GET', Uri.parse('http://localhost/items/RENT-001')),
      );

      final body =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;

      expect(response.statusCode, 200);
      expect(body['id'], 'RENT-001');
    });

    test('GET відсутнього запису повертає 404', () async {
      final response = await handler(
        Request('GET', Uri.parse('http://localhost/items/RENT-999')),
      );

      expect(response.statusCode, 404);
    });

    test('POST створює новий запис', () async {
      final response = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/items'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode(makeRental().toJson()),
        ),
      );

      expect(response.statusCode, 201);
      expect(await repository.findById('RENT-001'), isNotNull);
    });

    test('POST з некоректним JSON повертає 400', () async {
      final response = await handler(
        Request('POST', Uri.parse('http://localhost/items'), body: '{invalid}'),
      );

      expect(response.statusCode, 400);
    });

    test('POST з повторним ID повертає 409', () async {
      await repository.add(makeRental());

      final response = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/items'),
          body: jsonEncode(makeRental().toJson()),
        ),
      );

      expect(response.statusCode, 409);
    });
  });

  group('Зовнішній REST API', () {
    test('Успішна відповідь перетворюється на BikeRental', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode([
            {
              'id': 1,
              'company': {'name': 'Test Station'},
            },
          ]),
          200,
        );
      });

      final service = ExternalRentalService(client: client);

      try {
        final rentals = await service.fetchRentals();

        expect(rentals, hasLength(1));
        expect(rentals.first.id, 'RENT-EXT-001');
        expect(rentals.first.station, 'Test Station');
      } finally {
        client.close();
      }
    });

    test('HTTP 503 викликає HttpStatusException', () async {
      final client = MockClient(
        (request) async => http.Response('Unavailable', 503),
      );

      final service = ExternalRentalService(client: client);

      try {
        await expectLater(
          service.fetchRentals(),
          throwsA(isA<HttpStatusException>()),
        );
      } finally {
        client.close();
      }
    });

    test('Некоректний JSON викликає FormatException', () async {
      final client = MockClient(
        (request) async => http.Response('{invalid}', 200),
      );

      final service = ExternalRentalService(client: client);

      try {
        await expectLater(
          service.fetchRentals(),
          throwsA(isA<FormatException>()),
        );
      } finally {
        client.close();
      }
    });

    test('Помилка з’єднання передається клієнтом', () async {
      final client = MockClient((request) async {
        throw const SocketException('Connection refused');
      });

      final service = ExternalRentalService(client: client);

      try {
        await expectLater(
          service.fetchRentals(),
          throwsA(isA<SocketException>()),
        );
      } finally {
        client.close();
      }
    });
  });
}
