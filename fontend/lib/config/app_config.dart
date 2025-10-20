import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Resolve API base URL in priority: .env -> --dart-define -> fallback
  static String get apiBaseUrl {
    final env = dotenv.env['API_BASE_URL']?.trim();
    if (env != null && env.isNotEmpty) return _normalize(env);

    const define = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (define.isNotEmpty) return _normalize(define);

    const fallback = 'https://1q632lhb-5035.asse.devtunnels.ms';
    return _normalize(fallback);
  }

  static String _normalize(String base) {
    var b = base;
    while (b.endsWith('/')) {
      b = b.substring(0, b.length - 1);
    }
    return b;
  }
}
