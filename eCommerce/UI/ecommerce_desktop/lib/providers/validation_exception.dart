/// Exception with a map of validation errors per field (key = field name, value = list of messages).
class ValidationException implements Exception {
  final Map<String, List<String>> errors;
  ValidationException(this.errors);

  String get message {
    for (final list in errors.values) {
      if (list.isNotEmpty) return list.first;
    }
    return 'Please check your input.';
  }

  /// Returns the first error message for [field], or null.
  String? firstErrorFor(String field) {
    final list = errors[field];
    if (list == null || list.isEmpty) return null;
    return list.first;
  }

  /// Returns a map of field -> first message (suitable for errorText in forms).
  Map<String, String> get firstErrors {
    final map = <String, String>{};
    errors.forEach((key, value) {
      if (value.isNotEmpty) map[key] = value.first;
    });
    return map;
  }
}
