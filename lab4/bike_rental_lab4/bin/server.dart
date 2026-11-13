import 'dart:io';

import 'package:bike_rental_lab4/bike_rental_lab4.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

Future<void> main(List<String> arguments) async {
  try {
    final port = arguments.isEmpty ? 8080 : int.parse(arguments.first);

    if (port < 1 || port > 65535) {
      throw const FormatException('Порт має бути від 1 до 65535');
    }

    final repository = FileRentalRepository(FileRentalRepository.defaultPath());

    final handler = buildRentalHandler(repository);

    final server = await shelf_io.serve(
      handler,
      InternetAddress.loopbackIPv4,
      port,
    );

    stdout.writeln('HTTP-сервер запущено');
    stdout.writeln('Адреса: http://127.0.0.1:${server.port}');
    stdout.writeln('Для зупинки натисніть Ctrl+C');
  } on FormatException catch (error) {
    stderr.writeln('Помилка параметрів: $error');
    exitCode = 2;
  } on SocketException catch (error) {
    stderr.writeln('Не вдалося запустити сервер: $error');
    exitCode = 3;
  }
}
