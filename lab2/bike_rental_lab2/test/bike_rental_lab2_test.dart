import 'package:bike_rental_lab2/bike_rental_lab2.dart';
import 'package:test/test.dart';

void main() {
  group('BikeRental', () {
    const csv = 'RENT-001;Центр;Міський;60;120.0;2026-10-01';

    test('Розбір коректного CSV', () {
      final rental = BikeRental.fromCsv(csv);

      expect(rental.id, 'RENT-001');
      expect(rental.station, 'Центр');
      expect(rental.bikeType, BikeType.city);
      expect(rental.duration, 60);
      expect(rental.price, 120);
    });

    test('Некоректний CSV викликає FormatException', () {
      expect(() => BikeRental.fromCsv('invalid'), throwsFormatException);
    });

    test('Рівність обʼєктів та hashCode', () {
      final first = BikeRental.fromCsv(csv);
      final second = BikeRental.fromCsv(csv);

      expect(first, equals(second));
      expect(first.hashCode, second.hashCode);
      expect({first, second}.length, 1);
    });

    test('Фабричний конструктор повертає той самий обʼєкт', () {
      expect(identical(BikeRental.empty(), BikeRental.empty()), isTrue);
    });

    test('Обчислювані властивості', () {
      final rental = BikeRental.fromCsv(csv);

      expect(rental.pricePerMinute, 2.0);
      expect(rental.formattedDuration, '1 год 0 хв');
    });
  });

  group('RentalTariff', () {
    test('Поліморфне обчислення тарифів', () {
      const tariffs = <RentalTariff>[
        HourlyTariff(),
        DailyTariff(),
        CorporateTariff(),
      ];

      expect(tariffs[0].calculate(120), 240);
      expect(tariffs[1].calculate(120), 500);
      expect(tariffs[2].calculate(120), 180);
    });
  });

  group('Repository', () {
    test('Додавання та пошук обʼєктів', () {
      final repository = Repository<BikeRental>();
      final rental = BikeRental.fromCsv(
        'RENT-002;Парк;Електричний;90;270.0;2026-10-02',
      );

      repository.add(rental);

      expect(repository.count, 1);
      expect(repository.findById('RENT-002'), rental);
      expect(repository.findById('RENT-999'), isNull);
    });
  });

  group('Statistics', () {
    test('Обчислення агрегованих показників', () {
      final rentals = [
        BikeRental.fromCsv('RENT-001;Центр;Міський;60;120.0;2026-10-01'),
        BikeRental.fromCsv('RENT-002;Парк;Електричний;90;270.0;2026-10-02'),
      ];

      final stats = calculateStatistics(rentals);

      expect(stats.count, 2);
      expect(stats.revenue, 390);
      expect(stats.averageDuration, 75);
    });
  });
}
