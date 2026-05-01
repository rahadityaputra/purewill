import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

enum AppTimezoneOption { wib, wita, wit, london }

const String _timezonePreferenceKey = 'selected_app_timezone';

extension AppTimezoneOptionX on AppTimezoneOption {
  String get label {
    switch (this) {
      case AppTimezoneOption.wib:
        return 'WIB';
      case AppTimezoneOption.wita:
        return 'WITA';
      case AppTimezoneOption.wit:
        return 'WIT';
      case AppTimezoneOption.london:
        return 'London';
    }
  }

  String get timezoneName {
    switch (this) {
      case AppTimezoneOption.wib:
        return 'Asia/Jakarta';
      case AppTimezoneOption.wita:
        return 'Asia/Makassar';
      case AppTimezoneOption.wit:
        return 'Asia/Jayapura';
      case AppTimezoneOption.london:
        return 'Europe/London';
    }
  }

  tz.Location get location => tz.getLocation(timezoneName);
}

AppTimezoneOption appTimezoneOptionFromString(String? value) {
  switch (value?.toLowerCase()) {
    case 'wita':
      return AppTimezoneOption.wita;
    case 'wit':
      return AppTimezoneOption.wit;
    case 'london':
    case 'europe/london':
      return AppTimezoneOption.london;
    case 'wib':
    case 'asia/jakarta':
    default:
      return AppTimezoneOption.wib;
  }
}

class AppTimezone {
  static AppTimezoneOption _current = AppTimezoneOption.wib;
  static bool _initialized = false;

  static bool get isInitialized => _initialized;
  static AppTimezoneOption get currentOption => _current;
  static String get currentLabel => _current.label;
  static String get currentTimezoneName => _current.timezoneName;
  static tz.Location get currentLocation => _current.location;

  static Future<void> initialize() async {
    tz.initializeTimeZones();
    final prefs = await SharedPreferences.getInstance();
    _current = appTimezoneOptionFromString(
      prefs.getString(_timezonePreferenceKey),
    );
    tz.setLocalLocation(currentLocation);
    _initialized = true;
  }

  static Future<void> setTimezone(AppTimezoneOption option) async {
    _current = option;
    tz.setLocalLocation(currentLocation);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_timezonePreferenceKey, option.name);
  }
}

Future<void> initializeIndonesiaTimezone() async {
  await AppTimezone.initialize();
}

DateTime nowInIndonesia() {
  return tz.TZDateTime.now(AppTimezone.currentLocation);
}

DateTime toIndonesiaDateTime(DateTime dateTime) {
  return tz.TZDateTime.from(dateTime, AppTimezone.currentLocation);
}

DateTime parseUtcToIndonesia(dynamic value, {DateTime? fallback}) {
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) {
      return toIndonesiaDateTime(parsed);
    }
  } else if (value is DateTime) {
    return toIndonesiaDateTime(value);
  }

  return fallback ?? nowInIndonesia();
}

DateTime dateOnlyInIndonesia(DateTime dateTime) {
  final local = toIndonesiaDateTime(dateTime);
  return DateTime(local.year, local.month, local.day);
}

Future<void> setIndonesiaTimezone(AppTimezoneOption option) {
  return AppTimezone.setTimezone(option);
}

bool isSameIndonesiaDate(DateTime a, DateTime b) {
  final da = dateOnlyInIndonesia(a);
  final db = dateOnlyInIndonesia(b);
  return da.year == db.year && da.month == db.month && da.day == db.day;
}
