import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../models/bike_rental.dart';
import '../repositories/file_rental_repository.dart';

const _jsonHeaders = {'content-type': 'application/json; charset=utf-8'};

Response _jsonResponse(int status, Object data) {
  return Response(status, body: jsonEncode(data), headers: _jsonHeaders);
}

Router buildRentalRouter(FileRentalRepository repository) {
  final router = Router();

  router.get('/items', (Request request) async {
    try {
      final station = request.url.queryParameters['station'];
      final rentals = await repository.findByStation(station);

      return _jsonResponse(
        200,
        rentals.map((rental) => rental.toJson()).toList(),
      );
    } on FileSystemException {
      return _jsonResponse(500, {'error': 'Помилка файлової системи'});
    } on FormatException {
      return _jsonResponse(500, {'error': 'Некоректні дані сховища'});
    }
  });

  router.get('/items/<id>', (Request request, String id) async {
    try {
      final rental = await repository.findById(id);

      if (rental == null) {
        return _jsonResponse(404, {'error': 'Оренду $id не знайдено'});
      }

      return _jsonResponse(200, rental.toJson());
    } on FileSystemException {
      return _jsonResponse(500, {'error': 'Помилка файлової системи'});
    } on FormatException {
      return _jsonResponse(500, {'error': 'Некоректні дані сховища'});
    }
  });

  router.post('/items', (Request request) async {
    try {
      final body = await request.readAsString();
      final decoded = jsonDecode(body);

      if (decoded is! Map<String, dynamic>) {
        return _jsonResponse(400, {'error': 'Очікувався JSON-об’єкт'});
      }

      final rental = BikeRental.fromJson(decoded);

      await repository.add(rental);

      return _jsonResponse(201, {
        'message': 'Оренду створено',
        'item': rental.toJson(),
      });
    } on FormatException catch (error) {
      return _jsonResponse(400, {'error': error.message});
    } on StateError catch (error) {
      return _jsonResponse(409, {'error': error.toString()});
    } on FileSystemException {
      return _jsonResponse(500, {'error': 'Помилка файлової системи'});
    }
  });

  return router;
}

Handler buildRentalHandler(FileRentalRepository repository) {
  final router = buildRentalRouter(repository);

  return Pipeline().addMiddleware(logRequests()).addHandler(router.call);
}
