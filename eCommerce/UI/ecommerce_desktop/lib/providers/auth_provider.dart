class AuthProvider {
  static String? username;
  static String? password; // kept for backward compat, prefer token
  static String? token; // JWT
  static int? userId;

  /// Called when API returns 401 (e.g. token expired). Set in main to navigate to login.
  static void Function()? onUnauthorized;

  static void clear() {
    username = null;
    password = null;
    token = null;
    userId = null;
  }
}
