import 'dart:collection';
import '../core/constants.dart';

enum LogLevel { info, warning, error }

class LogEntry {
  final LogLevel level;
  final String message;
  final DateTime timestamp;

  const LogEntry({
    required this.level,
    required this.message,
    required this.timestamp,
  });

  @override
  String toString() {
    final time =
        '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
    final tag = level.name.toUpperCase().padRight(7);
    return '[$time] $tag $message';
  }
}

class LogService {
  static final List<LogEntry> _entries = [];
  static const int _maxEntries = kLogMaxEntries;

  static UnmodifiableListView<LogEntry> get entries =>
      UnmodifiableListView(_entries);

  static void info(String message) {
    _add(LogLevel.info, message);
  }

  static void warning(String message) {
    _add(LogLevel.warning, message);
  }

  static void error(String message) {
    _add(LogLevel.error, message);
  }

  static void _add(LogLevel level, String message) {
    _entries.add(
      LogEntry(level: level, message: message, timestamp: DateTime.now()),
    );
    if (_entries.length > _maxEntries) {
      _entries.removeRange(0, _entries.length - _maxEntries);
    }
  }

  static void clear() {
    _entries.clear();
  }

  static String exportAll() {
    return _entries.map((e) => e.toString()).join('\n');
  }
}
