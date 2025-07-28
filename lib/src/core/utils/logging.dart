import 'package:logger/logger.dart';

Logger? _logger;
Logger logger() => _logger ??= Logger();
