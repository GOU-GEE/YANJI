import 'dart:developer' as developer;

enum LogArea {
  app,
  database,
  sync,
  auth,
  frontier,
  ops,
  verify,
  apply,
  conflict,
}

/// Log event names and non-sensitive counts/IDs, never payloads or secrets.
final class AppLog {
  const AppLog();

  void event(LogArea area, String event, {int level = 800}) {
    developer.log(
      event,
      name: 'YANJI.${area.name.toUpperCase()}',
      level: level,
    );
  }
}
