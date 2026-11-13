import 'dart:io';

import 'package:args/args.dart';
import 'package:bike_rental_lab4/bike_rental_lab4.dart';

Future<void> main(List<String> arguments) async {
  String filePath = FileRentalRepository.defaultPath();

  try {
    final parsed = RentalCli.buildParser().parse(arguments);
    filePath = (parsed['file'] as String?) ?? filePath;
  } on ArgParserException {
    exitCode = 2;
  }

  final repository = FileRentalRepository(filePath);
  final cli = RentalCli(repository);

  final result = await cli.execute(arguments);
  exitCode = result.exitCode;
}
