import 'package:bike_rental_lab2/bike_rental_lab2.dart';

const rentalData = <String>[
  'RENT-001;Центр;Міський;60;120.0;2026-10-01',
  'RENT-002;Парк;Електричний;90;270.0;2026-10-02',
  'RENT-003;Вокзал;Гірський;120;300.0;2026-10-03',
  'RENT-004;Центр;Електричний;45;135.0;2026-10-04',
  'RENT-005;Парк;Міський;30;60.0;2026-10-05',
  'RENT-006;Вокзал;Міський;75;150.0;2026-10-06',
  'RENT-007;Центр;Гірський;180;450.0;2026-10-07',
  'RENT-008;Парк;Електричний;120;360.0;2026-10-08',
  'RENT-009;Вокзал;Гірський;60;150.0;2026-10-09',
  'RENT-010;Центр;Міський;90;180.0;2026-10-10',
  'RENT-011;Парк;Гірський;45;112.5;2026-10-11',
  'RENT-012;Вокзал;Електричний;150;450.0;2026-10-12',
  'RENT-013;Центр;Електричний;60;180.0;2026-10-13',
  'RENT-014;Парк;Міський;120;240.0;2026-10-14',
  'RENT-015;Вокзал;Гірський;90;225.0;2026-10-15',
  'RENT-016;Центр;Міський;60;120.0',
  'RENT-017;Парк;Гірський;abc;200.0;2026-10-17',
  'RENT-018;Вокзал;Міський;45;90.0;invalid-date',
  'RENT-019;Центр;Міський;-20;100.0;2026-10-19',
  'RENT-020;Парк;Гірський;60;-150.0;2026-10-20',
  'WRONG-021;Вокзал;Міський;30;60.0;2026-10-21',
  'RENT-022;Центр;Міський;60;120.0;2026-02-30',
];

void main() {
  print('\nОБ\'ЄКТНО-ОРІЄНТОВАНА СИСТЕМА ПРОКАТУ');

  final repository = Repository<BikeRental>();
  var invalidCount = 0;

  print('\n1. СТВОРЕННЯ ОБ\'ЄКТІВ ІЗ CSV');

  for (var i = 0; i < rentalData.length; i++) {
    try {
      final rental = BikeRental.fromCsv(rentalData[i]);
      repository.add(rental);
    } on FormatException catch (error) {
      invalidCount++;
      print('Запис ${i + 1}: ${error.message}');
    }
  }

  print('Коректних об\'єктів: ${repository.count}');
  print('Некоректних записів: $invalidCount');

  print('\n2. НЕЗМІННА СУТНІСТЬ І ГЕТЕРИ');

  final rental = repository.findById('RENT-007')!;
  print(rental);
  print('Вартість за хвилину: ${rental.pricePerMinute}');
  print('Дата оренди: ${rental.date.shortDate}');

  print('\n3. ПОРІВНЯННЯ КОНСТРУКТОРІВ');

  final primary = RentalSummary('Центр', 1065);
  const traditional = TraditionalSummary('Центр', 1065);

  print('Первинний: $primary');
  print('Звичайний: $traditional');

  print('\n4. РІВНІСТЬ ОБ\'ЄКТІВ ТА SET');

  final first = repository.findById('RENT-001')!;
  final second = BikeRental.fromCsv(rentalData.first);

  final uniqueRentals = {first, second};

  print('Однакові за значенням: ${first == second}');
  print('Однаковий hashCode: ${first.hashCode == second.hashCode}');
  print('Розмір Set: ${uniqueRentals.length}');

  print('\n5. ФАБРИЧНИЙ КОНСТРУКТОР');

  final empty1 = BikeRental.empty();
  final empty2 = BikeRental.empty();

  print('Повернуто той самий екземпляр: ${identical(empty1, empty2)}');

  print('\n6. ІЄРАРХІЯ ТАРИФІВ І ПОЛІМОРФІЗМ');

  final tariffs = <RentalTariff>[
    const HourlyTariff(),
    const DailyTariff(),
    const CorporateTariff(),
  ];

  for (final tariff in tariffs) {
    print(
      '${tariff.name}: '
      '${tariff.calculate(120).toStringAsFixed(2)} грн',
    );
    print('  ${describeTariff(tariff)}');
  }

  print('\n7. ДОМІШКА TIMEINTERVALBEHAVIOR');

  final maintenance = Maintenance(
    id: 'SERVICE-001',
    description: 'Технічний огляд',
    date: DateTime(2026, 10, 1),
  );

  final referenceDate = DateTime(2026, 11, 9);

  print('Вік оренди: ${rental.ageInDays(referenceDate)} днів');
  print(
    'Вік технічного огляду: '
    '${maintenance.ageInDays(referenceDate)} днів',
  );

  print('\n8. GENERICS І REPOSITORY');

  print('Кількість об\'єктів: ${repository.count}');
  print('Пошук RENT-007: ${repository.findById('RENT-007')?.id}');

  final electric = repository.where(
    (item) => item.bikeType == BikeType.electric,
  );

  print('Електричних велосипедів: ${electric.length}');

  print('\n9. АГРЕГАЦІЯ ТА RECORDS');

  final (count: count, revenue: revenue, averageDuration: average) =
      calculateStatistics(repository.all);

  print('Кількість: $count');
  print('Виручка: ${revenue.toStringAsFixed(2)} грн');
  print('Середня тривалість: ${average.toStringAsFixed(2)} хв');

  print('\n10. ГРУПУВАННЯ ЗА СТАНЦІЯМИ');

  final groups = groupByStation(repository.all);

  for (final entry in groups.entries) {
    final stats = calculateStatistics(entry.value);
    print(
      '${entry.key}: ${stats.count} оренд, '
      '${stats.revenue.toStringAsFixed(2)} грн',
    );
  }

  print('\n11. СОРТУВАННЯ');

  final expensive = sortRentals(repository.all).take(3);

  for (final item in expensive) {
    print(item);
  }

  print('\n12. ENUM І МЕТОД РОЗШИРЕННЯ');

  for (final type in BikeType.values) {
    print(
      '${type.label}: '
      '${type.calculatePrice(60).toStringAsFixed(2)} грн/год',
    );
  }

  print('Тривалість RENT-007: ${rental.duration.asDuration}');

  print('\n13. PATTERN MATCHING З WHEN');

  for (final item in repository.all.take(5)) {
    print('${item.id}: ${classifyRental(item)}');
  }

  print('\nРОБОТУ ПРОГРАМИ ЗАВЕРШЕНО');
}
