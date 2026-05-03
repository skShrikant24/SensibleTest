class ApiHelper {
  static String? buildUrl(dynamic value) {
    if (value == null) return null;

    final s = value.toString().trim();
    if (s.isEmpty) return null;

    return s.startsWith('http')
        ? s
        : 'https://grabitt.in/$s';
  }
}
