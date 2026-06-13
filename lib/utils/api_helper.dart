class ApiHelper {
  static String? buildUrl(dynamic value) {
    if (value == null) return null;

    final s = value.toString().trim();
    if (s.isEmpty) return null;

    if (s.startsWith('http')) return s;

    return 'https://grabitt.in${s.startsWith('/') ? s : '/$s'}';
  }
}