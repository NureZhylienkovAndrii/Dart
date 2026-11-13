import 'package:http/http.dart' as http;

import '../services/external_rental_service.dart';

import 'dart:io';

import 'package:args/args.dart';

import '../models/bike_rental.dart';
import '../repositories/file_rental_repository.dart';

import 'dart:async';

class CliResult {
  const CliResult(this.exitCode);

  final int exitCode;
}

class RentalCli {
  RentalCli(this.repository);

  final FileRentalRepository repository;

  static ArgParser buildParser() {
    return ArgParser()
      ..addFlag('help', abbr: 'h', negatable: false)
      ..addOption('file', abbr: 'f')
      ..addOption('station', abbr: 's')
      ..addOption('id')
      ..addOption('type', defaultsTo: 'city')
      ..addOption('duration', defaultsTo: '60')
      ..addOption('price', defaultsTo: '120');
  }

  Future<CliResult> execute(List<String> arguments) async {
    final parser = buildParser();

    try {
      final result = parser.parse(arguments);

      if (result['help'] == true || result.rest.isEmpty) {
        stdout.writeln('СИСТЕМА ПРОКАТУ ВЕЛОСИПЕДІВ');
        stdout.writeln('Команди: list, get, add, count-lines, fetch');
        stdout.writeln(parser.usage);
        return const CliResult(0);
      }

      final command = result.rest.first;

      switch (command) {
        case 'fetch':
          final service = ExternalRentalService();

          try {
            final rentals = await service.fetchRentals();

            stdout.writeln('Отримано записів із REST API: ${rentals.length}');

            for (final rental in rentals) {
              stdout.writeln(rental);
            }
          } finally {
            service.close();
          }

        case 'list':
          final station = result['station'] as String?;
          final rentals = await repository.findByStation(station);

          stdout.writeln('Знайдено записів: ${rentals.length}');

          for (final rental in rentals) {
            stdout.writeln(rental);
          }

        case 'get':
          final id = result['id'] as String?;

          if (id == null || id.isEmpty) {
            throw const FormatException('Потрібно вказати --id');
          }

          final rental = await repository.findById(id);

          if (rental == null) {
            stderr.writeln('Оренду $id не знайдено');
            return const CliResult(1);
          }

          stdout.writeln(rental);

        case 'add':
          final id = result['id'] as String?;
          final station = result['station'] as String?;

          if (id == null || station == null) {
            throw const FormatException('Для add потрібні --id і --station');
          }

          final duration = int.parse(result['duration'] as String);
          final price = double.parse(result['price'] as String);

          final rental = BikeRental(
            id: id,
            station: station,
            bikeType: result['type'] as String,
            duration: duration,
            price: price,
            date: DateTime.now(),
          );

          if (duration <= 0 || !price.isFinite || price < 0) {
            throw const FormatException('Некоректна тривалість або вартість');
          }

          await repository.add(rental);
          stdout.writeln('Оренду $id успішно додано');

        case 'count-lines':
          final path = result['file'] as String?;

          if (path == null) {
            throw const FormatException('Потрібно вказати --file');
          }

          final count = await repository.countLines(path);
          stdout.writeln('Непорожніх рядків: $count');

        default:
          throw FormatException('Невідома команда: $command');
      }

      return const CliResult(0);
    } on ArgParserException catch (error) {
      stderr.writeln('Помилка аргументів: $error');
      return const CliResult(2);
    } on FormatException catch (error) {
      stderr.writeln('Помилка формату: $error');
      return const CliResult(2);
    } on FileSystemException catch (error) {
      stderr.writeln('Помилка файлової системи: $error');
      return const CliResult(3);
    } on StateError catch (error) {
      stderr.writeln('Помилка стану: $error');
      return const CliResult(4);
    } on SocketException catch (error) {
      stderr.writeln('Помилка мережевого з’єднання: $error');
      return const CliResult(5);
    } on http.ClientException catch (error) {
      stderr.writeln('Помилка HTTP-клієнта: $error');
      return const CliResult(5);
    } on HttpStatusException catch (error) {
      stderr.writeln(error);
      return const CliResult(6);
    } on TimeoutException catch (error) {
      stderr.writeln('Перевищено час очікування: $error');
      return const CliResult(5);
    }
  }
}
