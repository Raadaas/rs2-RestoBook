class AuthProvider {
  static String? username;
  static String? password;
  static String? token; // JWT
  static int? userId;

  /// Called when API returns 401. Set in main to navigate to login.
  static void Function()? onUnauthorized;

  static void clear() {
    username = null;
    password = null;
    token = null;
    userId = null;
  }
}
