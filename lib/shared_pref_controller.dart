import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceController {
  static final SharedPreferenceController _sharedPreferenceController =
      SharedPreferenceController._();

  factory SharedPreferenceController() {
    return _sharedPreferenceController;
  }

  SharedPreferenceController._();

  Future<void> setStringListValue(String key, List<String> value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(key, value);
  }

  Future<List<String>> getStringListValue(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getStringList(key);

    if (value != null) {
      return value;
    } else {

      return [];
    }
  }

}
