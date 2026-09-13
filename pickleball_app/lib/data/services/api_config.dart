class ApiConfig {
  static const String defaultProductionUrl = 'https://pickleball-backend-production-c00e.up.railway.app';

  static String get baseUrl {
    const override = String.fromEnvironment('API_URL');
    if (override.isNotEmpty) {
      return override;
    }
    return defaultProductionUrl;
  }

  static String resolveUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$baseUrl$cleanPath';
  }
}
