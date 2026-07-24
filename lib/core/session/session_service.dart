import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const _keyCashierName = 'cashier_name';

  static Future<void> logIn(String cashierName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCashierName, cashierName);
  }

  static Future<void> logOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCashierName);
  }

  static Future<String?> getCashierName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCashierName);
  }
}
