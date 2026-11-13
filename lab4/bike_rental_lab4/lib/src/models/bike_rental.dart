class BikeRental {
  const BikeRental({
    required this.id,
    required this.station,
    required this.bikeType,
    required this.duration,
    required this.price,
    required this.date,
  });

  final String id;

  final String station;

  final String bikeType;

  final int duration;

  final double price;

  final DateTime date;

  Map<String, dynamic> toJson() => {
    'id': id,
    'station': station,
    'bikeType': bikeType,
    'duration': duration,
    'price': price,
    'date': date.toIso8601String(),
  };

  factory BikeRental.fromJson(Map<String, dynamic> json) {
    try {
      final id = json['id'] as String;
      final station = json['station'] as String;
      final bikeType = json['bikeType'] as String;
      final duration = json['duration'] as int;
      final price = (json['price'] as num).toDouble();
      final date = DateTime.parse(json['date'] as String);

      if (id.trim().isEmpty ||
          station.trim().isEmpty ||
          bikeType.trim().isEmpty ||
          duration <= 0 ||
          !price.isFinite ||
          price < 0) {
        throw const FormatException('Некоректні значення полів оренди');
      }

      return BikeRental(
        id: id,
        station: station,
        bikeType: bikeType,
        duration: duration,
        price: price,
        date: date,
      );
    } on TypeError catch (error) {
      throw FormatException('Некоректні типи полів оренди: $error');
    }
  }

  @override
  String toString() =>
      '$id | $station | $bikeType | $duration хв | '
      '${price.toStringAsFixed(2)} грн | '
      '${date.toIso8601String().substring(0, 10)}';
}
