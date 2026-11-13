import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/bike_rental.dart';

class FileRentalRepository {
  /// Створює файлове сховище.
  FileRentalRepository(this.filePath);

  final String filePath;

  static String defaultPath() => p.join('data', 'rentals.json');

  Future<List<BikeRental>> loadAll() async {
    final file = File(filePath);

    if (!await file.exists()) {
      return [];
    }

    final content = await file.readAsString();
    final decoded = jsonDecode(content);

    if (decoded is! List) {
      throw const FormatException('Коренем JSON повинен бути масив');
    }

    return decoded.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Некоректний запис оренди');
      }

      return BikeRental.fromJson(item);
    }).toList();
  }

  Future<void> saveAll(List<BikeRental> rentals) async {
    final file = File(filePath);

    await file.parent.create(recursive: true);

    final json = const JsonEncoder.withIndent('  ')
        .convert(rentals.map((rental) => rental.toJson()).toList());

    await file.writeAsString(json, flush: true);
  }

  Future<void> add(BikeRental rental) async {
    final rentals = await loadAll();

    if (rentals.any((item) => item.id == rental.id)) {
      throw StateError('Оренда з ID ${rental.id} вже існує');
    }

    rentals.add(rental);
    await saveAll(rentals);
  }

  Future<BikeRental?> findById(String id) async {
    final rentals = await loadAll();

    for (final rental in rentals) {
      if (rental.id == id) {
        return rental;
      }
    }

    return null;
  }

  Future<List<BikeRental>> findByStation(String? station) async {
    final rentals = await loadAll();

    if (station == null || station.isEmpty) {
      return rentals;
    }

    return rentals
        .where(
          (rental) => rental.station.toLowerCase() == station.toLowerCase(),
        )
        .toList();
  }

  Future<int> countLines(String path) async {
    final lines = File(path)
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    var count = 0;

    await for (final line in lines) {
      if (line.trim().isNotEmpty) {
        count++;
      }
    }

    return count;
  }
}
