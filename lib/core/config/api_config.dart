class ApiConfig {
  ApiConfig._();

  static String baseUrl = 'http://localhost:8000/api/v1';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
