import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeriko_app/main.dart';

class LocalStorage {
  static Future<bool> setStringItem(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(key, value);
  }

  static Future<bool> setBoolItem(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setBool(key, value);
  }

  static Future<String> getStringItem(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key) ?? "";
  }

  static Future<List<String>> getStringListItem(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key) ?? <String>[];
  }

  static Future<bool> getBoolItem(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }

  static Future<bool> removeItem(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(key);
  }

  // ignore: strict_top_level_inference
  static Future<void> logOut(context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await LocalStorage.setStringItem("firstTime", "1");
    await LocalStorage.setStringItem("terms", "1");
    // Phoenix.rebirth(context);
  }

  // ignore: strict_top_level_inference
  static Future<void> clearSharedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Deletes all stored data
    userData = null; // Reset userData to null
    // Phoenix.rebirth(context);
  }
}
