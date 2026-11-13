abstract interface class Identifiable {
  String get id;
}

enum BikeType {
  city('Міський', 2.0),
  mountain('Гірський', 2.5),
  electric('Електричний', 3.0);

  const BikeType(this.label, this.pricePerMinute);

  final String label;
  final double pricePerMinute;

  static BikeType? fromLabel(String value) {
    for (final type in values) {
      if (type.label == value) return type;
    }
    return null;
  }

  double calculatePrice(int minutes) => minutes * pricePerMinute;
}

extension DurationFormatting on int {
  String get asDuration {
    final hours = this ~/ 60;
    final minutes = this % 60;
    return '$hours год $minutes хв';
  }
}

extension RentalDateFormatting on DateTime {
  String get shortDate =>
      '${day.toString().padLeft(2, '0')}.'
      '${month.toString().padLeft(2, '0')}.$year';
}

abstract class TimedEntity {
  const TimedEntity(this.date);

  final DateTime date;
}

mixin TimeIntervalBehavior on TimedEntity {
  int ageInDays(DateTime now) => now.difference(date).inDays;

  bool isOlderThan(int days, DateTime now) => ageInDays(now) > days;
}

class BikeRental extends TimedEntity
    with TimeIntervalBehavior
    implements Identifiable {
  const BikeRental({
    required this.id,
    required this.station,
    required this.bikeType,
    required this.duration,
    required this.price,
    required DateTime date,
  }) : super(date);

  @override
  final String id;
  final String station;
  final BikeType bikeType;
  final int duration;
  final double price;

  double get pricePerMinute => price / duration;

  String get formattedDuration => duration.asDuration;

  factory BikeRental.fromCsv(String line) {
    final fields = line.split(';');

    if (fields.length != 6) {
      throw const FormatException('Очікується 6 полів');
    }

    final duration = int.tryParse(fields[3]);
    final price = double.tryParse(fields[4]);
    final date = DateTime.tryParse(fields[5]);
    final type = BikeType.fromLabel(fields[2]);

    if (duration == null || price == null || date == null || type == null) {
      throw const FormatException('Некоректні дані');
    }

    final dateParts = fields[5].split('-');
    if (dateParts.length != 3 ||
        date.year != int.tryParse(dateParts[0]) ||
        date.month != int.tryParse(dateParts[1]) ||
        date.day != int.tryParse(dateParts[2])) {
      throw const FormatException('Некоректна дата');
    }

    if (!RegExp(r'^RENT-\d{3}$').hasMatch(fields[0]) ||
        duration < 1 ||
        duration > 1440 ||
        !price.isFinite ||
        price < 0 ||
        price > 10000 ||
        fields[1].trim().isEmpty) {
      throw const FormatException('Порушення правил валідації');
    }

    return BikeRental(
      id: fields[0],
      station: fields[1],
      bikeType: type,
      duration: duration,
      price: price,
      date: date,
    );
  }

  static final BikeRental _empty = BikeRental(
    id: 'RENT-000',
    station: 'Невідома',
    bikeType: BikeType.city,
    duration: 1,
    price: 0,
    date: DateTime(2000),
  );

  factory BikeRental.empty() => _empty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BikeRental &&
          id == other.id &&
          station == other.station &&
          bikeType == other.bikeType &&
          duration == other.duration &&
          price == other.price &&
          date == other.date;

  @override
  int get hashCode => Object.hash(id, station, bikeType, duration, price, date);

  @override
  String toString() =>
      '$id | $station | ${bikeType.label} | '
      '$formattedDuration | ${price.toStringAsFixed(2)} грн';
}

class Maintenance extends TimedEntity
    with TimeIntervalBehavior
    implements Identifiable {
  const Maintenance({
    required this.id,
    required this.description,
    required DateTime date,
  }) : super(date);

  @override
  final String id;
  final String description;
}

// Первинний конструктор Dart 3.13.
class RentalSummary(final String station, final double revenue) {
  @override
  String toString() => '$station: ${revenue.toStringAsFixed(2)} грн';
}

// Варіант зі звичайним конструктором для порівняння.
class TraditionalSummary {
  final String station;
  final double revenue;

  const TraditionalSummary(this.station, this.revenue);

  @override
  String toString() => '$station: ${revenue.toStringAsFixed(2)} грн';
}

sealed class RentalTariff {
  const RentalTariff();

  double calculate(int minutes);

  String get name;
}

final class HourlyTariff extends RentalTariff {
  const HourlyTariff();

  @override
  String get name => 'Погодинний';

  @override
  double calculate(int minutes) => minutes * 2.0;
}

final class DailyTariff extends RentalTariff {
  const DailyTariff();

  @override
  String get name => 'Денний';

  @override
  double calculate(int minutes) => (minutes / 1440).ceil() * 500.0;
}

final class CorporateTariff extends RentalTariff {
  const CorporateTariff();

  @override
  String get name => 'Корпоративний';

  @override
  double calculate(int minutes) => minutes * 1.5;
}

String describeTariff(RentalTariff tariff) => switch (tariff) {
  HourlyTariff() => 'Оплата за кожну хвилину',
  DailyTariff() => 'Фіксована добова оплата',
  CorporateTariff() => 'Спеціальна корпоративна ставка',
};

class Repository<T extends Identifiable> {
  final Map<String, T> _items = {};

  void add(T item) => _items[item.id] = item;

  T? findById(String id) => _items[id];

  Iterable<T> where(bool Function(T) test) => _items.values.where(test);

  Iterable<T> get all => _items.values;

  int get count => _items.length;
}

typedef RentalStatistics = ({
  int count,
  double revenue,
  double averageDuration,
});

RentalStatistics calculateStatistics(Iterable<BikeRental> rentals) {
  final items = rentals.toList();

  final revenue = items
      .map((rental) => rental.price)
      .fold<double>(0, (sum, price) => sum + price);

  final totalMinutes = items
      .map((rental) => rental.duration)
      .fold<int>(0, (sum, minutes) => sum + minutes);

  return (
    count: items.length,
    revenue: revenue,
    averageDuration: items.isEmpty ? 0 : totalMinutes / items.length,
  );
}

Map<String, List<BikeRental>> groupByStation(Iterable<BikeRental> rentals) {
  final result = <String, List<BikeRental>>{};

  for (final rental in rentals) {
    result.putIfAbsent(rental.station, () => []).add(rental);
  }

  return result;
}

List<BikeRental> sortRentals(
  Iterable<BikeRental> rentals, {
  bool ascending = false,
  bool byDuration = false,
}) {
  final result = rentals.toList();

  result.sort((a, b) {
    final comparison = byDuration
        ? a.duration.compareTo(b.duration)
        : a.price.compareTo(b.price);

    if (comparison != 0) {
      return ascending ? comparison : -comparison;
    }

    return a.id.compareTo(b.id);
  });

  return result;
}

String classifyRental(BikeRental rental) {
  return switch (rental) {
    BikeRental(duration: >= 120, bikeType: BikeType.electric) =>
      'Тривала оренда електровелосипеда',
    BikeRental(price: > 300) when rental.duration >= 90 =>
      'Дорога тривала оренда',
    BikeRental(duration: <= 60) => 'Коротка оренда',
    _ => 'Звичайна оренда',
  };
}
