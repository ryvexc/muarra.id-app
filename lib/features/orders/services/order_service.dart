import 'package:muarra_app_v1/core/services/api_client.dart';

class OrderService {
  Future<Map<String, dynamic>> createOrder({
    required String custName,
    required String paymentType,
    String? discountCode,
    required List<Map<String, dynamic>> orderItems,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/orders',
        data: {
          'cust_name': custName,
          'payment_type': paymentType,
          if (discountCode != null && discountCode.isNotEmpty)
            'discount_code': discountCode,
          'orderItems': orderItems,
        },
      );

      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      throw Exception('Gagal membuat order: $e');
    }
  }
}
