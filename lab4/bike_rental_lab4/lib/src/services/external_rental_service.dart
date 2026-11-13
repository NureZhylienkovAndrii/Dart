import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/bike_rental.dart';

class HttpStatusException implements Exception {
  const HttpStatusException(this.statusCode);

  final int statusCode;

  @override
  String toString() => 'HTTP-помилка: статус $statusCode';
}

class ExternalRentalService {
  ExternalRentalService({http.Client? client, Uri? endpoint})
    : _client = client ?? http.Client(),
      _ownsClient = client == null,
      endpoint =
          endpoint ?? Uri.parse('https://jsonplaceholder.typicode.com/users');

  final http.Client _client;
  final bool _ownsClient;
  final Uri endpoint;

  Future<List<BikeRental>> fetchRentals() async {
    try {
      final response = await _client
          .get(endpoint)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpStatusException(response.statusCode);
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));

      if (decoded is! List) {
        throw const FormatException('Очікувався масив JSON');
      }

      return decoded.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Некоректний об’єкт API');
        }

        final id = item['id'] as int;
        final company = item['company'] as Map<String, dynamic>;
        final station = company['name'] as String;

        return BikeRental(
          id: 'RENT-EXT-${id.toString().padLeft(3, '0')}',
          station: station,
          bikeType: 'city',
          duration: 60,
          price: 120,
          date: DateTime(2026, 11, 13),
        );
      }).toList();
    } on TypeError catch (error) {
      throw FormatException('Некоректні типи даних API: $error');
    }
  }

  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }
}
