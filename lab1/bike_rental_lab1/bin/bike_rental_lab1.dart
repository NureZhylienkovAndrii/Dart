typedef Rental = ({
  String id,
  String station,
  String bikeType,
  int duration,
  double price,
  DateTime date,
});

typedef ParseResult = ({Rental? rental, String? error});

const List<String> rentalData = [
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

  // Навмисно пошкоджені записи.
  'RENT-016;Центр;Міський;60;120.0',
  'RENT-017;Парк;Гірський;abc;200.0;2026-10-17',
  'RENT-018;Вокзал;Міський;45;90.0;invalid-date',

  // Записи з порушеннями допустимих значень.
  'RENT-019;Центр;Міський;-20;100.0;2026-10-19',
  'RENT-020;Парк;Гірський;60;-150.0;2026-10-20',
  'WRONG-021;Вокзал;Міський;30;60.0;2026-10-21',
  'RENT-022;Центр;Міський;60;120.0;2026-02-30',
];

final RegExp rentalIdPattern = RegExp(r'^(?<prefix>RENT)-(?<number>\d{3})$');

final RegExp maskPattern = RegExp(
  r'(?<prefix>RENT-)(?<visible>\d)(?<hidden>\d{2})',
);

DateTime? parseDate(String value) {
  final date = DateTime.tryParse(value);

  if (date == null) {
    return null;
  }

  final parts = value.split('-');

  if (parts.length != 3) {
    return null;
  }

  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);

  if (year == null || month == null || day == null) {
    return null;
  }

  if (date.year != year || date.month != month || date.day != day) {
    return null;
  }

  return date;
}

ParseResult parseLine(String line) {
  final fields = line.split(';');

  if (fields.length != 6) {
    return (
      rental: null,
      error: 'Очікується 6 полів, отримано ${fields.length}',
    );
  }

  final duration = int.tryParse(fields[3].trim());
  final price = double.tryParse(fields[4].trim());
  final date = parseDate(fields[5].trim());

  if (duration == null) {
    return (rental: null, error: 'Некоректна тривалість: ${fields[3]}');
  }

  if (price == null) {
    return (rental: null, error: 'Некоректна вартість: ${fields[4]}');
  }

  if (date == null) {
    return (rental: null, error: 'Некоректна дата: ${fields[5]}');
  }

  return (
    rental: (
      id: fields[0].trim(),
      station: fields[1].trim(),
      bikeType: fields[2].trim(),
      duration: duration,
      price: price,
      date: date,
    ),
    error: null,
  );
}

List<String> validateRental(Rental rental, {DateTime? currentDate}) {
  final errors = <String>[];
  final now = currentDate ?? DateTime.now();

  final idMatch = rentalIdPattern.firstMatch(rental.id);

  if (idMatch == null) {
    errors.add('Некоректний формат ідентифікатора');
  } else {
    final prefix = idMatch.namedGroup('prefix');
    final number = idMatch.namedGroup('number');

    if (prefix != 'RENT' || number == null) {
      errors.add('Некоректні складові ідентифікатора');
    }
  }

  if (rental.station.isEmpty) {
    errors.add('Не вказано станцію');
  }

  if (rental.bikeType.isEmpty) {
    errors.add('Не вказано тип велосипеда');
  }

  if (rental.duration < 1 || rental.duration > 1440) {
    errors.add('Тривалість повинна бути від 1 до 1440 хвилин');
  }

  if (!rental.price.isFinite || rental.price < 0 || rental.price > 10000) {
    errors.add('Вартість повинна бути від 0 до 10000 грн');
  }

  if (rental.date.isAfter(now)) {
    errors.add('Дата оренди не може бути в майбутньому');
  }

  return errors;
}

String maskRentalId(String id) {
  return id.replaceAllMapped(maskPattern, (match) {
    final regExpMatch = match as RegExpMatch;

    final prefix = regExpMatch.namedGroup('prefix') ?? '';
    final visible = regExpMatch.namedGroup('visible') ?? '';

    return '$prefix$visible**';
  });
}

int Function() createCounter() {
  var count = 0;

  return () {
    count++;
    return count;
  };
}

bool Function(Rental) stationFilter(String station) {
  return (rental) => rental.station == station;
}

double calculateRevenue(Iterable<Rental> rentals) {
  return rentals
      .where((rental) => rental.price >= 0)
      .map((rental) => rental.price)
      .fold<double>(0.0, (sum, price) => sum + price);
}

double calculateAverageDuration(Iterable<Rental> rentals) {
  final items = rentals.toList();

  if (items.isEmpty) {
    return 0;
  }

  final total = items
      .where((rental) => rental.duration > 0)
      .map((rental) => rental.duration)
      .fold<int>(0, (sum, duration) => sum + duration);

  return total / items.length;
}

Map<String, List<Rental>> groupByStation(List<Rental> rentals) {
  final groups = <String, List<Rental>>{};

  for (final rental in rentals) {
    groups.putIfAbsent(rental.station, () => <Rental>[]);
    groups[rental.station]!.add(rental);
  }

  return groups;
}

List<Rental> sortRentals(
  List<Rental> rentals, {
  String sortBy = 'price',
  bool ascending = false,
}) {
  final sorted = List<Rental>.from(rentals);

  sorted.sort((a, b) {
    int comparison;

    if (sortBy == 'duration') {
      comparison = a.duration.compareTo(b.duration);
    } else {
      comparison = a.price.compareTo(b.price);
    }

    if (comparison == 0) {
      comparison = a.id.compareTo(b.id);
    }

    return ascending ? comparison : -comparison;
  });

  return sorted;
}

int calculateRentalAge(Rental rental, {DateTime? currentDate}) {
  final now = currentDate ?? DateTime.now();
  final difference = now.difference(rental.date);

  return Duration(seconds: difference.inSeconds).inDays;
}

String buildReport(
  List<Rental> rentals, {
  int topCount = 5,
  bool ascending = false,
  String separator = ' | ',
  String sortBy = 'price',
}) {
  final buffer = StringBuffer();

  final sorted = sortRentals(rentals, sortBy: sortBy, ascending: ascending);

  final selected = sorted.take(topCount);

  buffer.writeln(
    ['ID', 'Станція', 'Тип', 'Тривалість', 'Вартість'].join(separator),
  );
  buffer.writeln('----------------------------------------');

  for (final rental in selected) {
    buffer.writeln(
      '${maskRentalId(rental.id)}'
      '$separator${rental.station}'
      '$separator${rental.bikeType}'
      '$separator${rental.duration} хв'
      '$separator${rental.price.toStringAsFixed(2)} грн',
    );
  }

  return buffer.toString();
}

void main() {
  print('\nСИСТЕМА ПРОКАТУ ВЕЛОСИПЕДІВ');

  print('\n1. РОЗБІР ТА ВАЛІДАЦІЯ ДАНИХ');

  final validRentals = <Rental>[];
  final nextCount = createCounter();

  var invalidCount = 0;
  var processedCount = 0;

  for (final line in rentalData) {
    final processed = nextCount();
    processedCount = processed;
    final result = parseLine(line);

    if (result.rental == null) {
      print('Запис $processed: ${result.error}');
      invalidCount++;
      continue;
    }

    final rental = result.rental!;
    final errors = validateRental(rental);

    if (errors.isNotEmpty) {
      print('Запис $processed (${rental.id}):');
      for (final error in errors) {
        print('  - $error');
      }
      invalidCount++;
      continue;
    }

    validRentals.add(rental);
  }

  print('\nУсього записів: ${rentalData.length}');
  print('Коректних: ${validRentals.length}');
  print('Некоректних: $invalidCount');

  print('\n2. АГРЕГАЦІЯ ДАНИХ');

  final totalRevenue = calculateRevenue(validRentals);
  final averageDuration = calculateAverageDuration(validRentals);

  print('Загальна виручка: ${totalRevenue.toStringAsFixed(2)} грн');
  print(
    'Середня тривалість: '
    '${averageDuration.toStringAsFixed(2)} хв',
  );

  final electricRentals = validRentals
      .where((rental) => rental.bikeType == 'Електричний')
      .toList();

  print('Оренд електричних велосипедів: ${electricRentals.length}');

  final electricRevenue = calculateRevenue(electricRentals);

  print(
    'Виручка від електричних велосипедів: '
    '${electricRevenue.toStringAsFixed(2)} грн',
  );

  print('\n3. ГРУПУВАННЯ ЗА СТАНЦІЯМИ');

  final groups = groupByStation(validRentals);

  for (final entry in groups.entries) {
    final revenue = calculateRevenue(entry.value);

    print(
      '${entry.key}: '
      '${entry.value.length} оренд, '
      '${revenue.toStringAsFixed(2)} грн',
    );
  }

  print('\n4. ФІЛЬТРАЦІЯ ЗА СТАНЦІЄЮ');

  final centerRentals = validRentals.where(stationFilter('Центр')).toList();

  print('Кількість оренд на станції Центр: ${centerRentals.length}');

  print('\n5. ПОШУК ЗАПИСУ');

  final foundRental = validRentals
      .where((rental) => rental.id == 'RENT-007')
      .firstOrNull;

  if (foundRental != null) {
    print('Знайдено: ${foundRental.id}');
    print('Станція: ${foundRental.station}');
    print('Вартість: ${foundRental.price} грн');
  } else {
    print('Запис не знайдено');
  }

  print('\n6. СОРТУВАННЯ ЗА ВАРТІСТЮ');

  print(
    buildReport(validRentals, topCount: 5, ascending: false, sortBy: 'price'),
  );

  print('\n7. СОРТУВАННЯ ЗА ТРИВАЛІСТЮ');

  print(
    buildReport(
      validRentals,
      topCount: 5,
      ascending: true,
      sortBy: 'duration',
      separator: ' / ',
    ),
  );

  print('\n8. РОБОТА З РЕГУЛЯРНИМИ ВИРАЗАМИ');

  final exampleId = 'RENT-007';
  final match = rentalIdPattern.firstMatch(exampleId);

  if (match != null) {
    print('Ідентифікатор: $exampleId');
    print('Префікс: ${match.namedGroup('prefix')}');
    print('Номер: ${match.namedGroup('number')}');
    print('Маскований ID: ${maskRentalId(exampleId)}');
  }

  print('\n9. АРИФМЕТИКА ДАТ');

  if (foundRental != null) {
    final age = calculateRentalAge(foundRental);

    print('Запис: ${foundRental.id}');
    print('Дата оренди: ${foundRental.date.toIso8601String().split('T')[0]}');
    print('Вік запису: $age днів');
  }

  print('\n10. ПЕРЕВІРКА ЗАМИКАННЯ');

  print('Кількість оброблених записів: $processedCount');
  print('Замикання зберігало лічильник між викликами.');

  print('\nОБРОБКУ ЗАВЕРШЕНО');
}
