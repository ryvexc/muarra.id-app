import 'package:muarra_app_v1/core/services/api_client.dart';
import 'package:muarra_app_v1/models/discount.dart';

class DiscountService {
  Future<List<Discount>> getDiscounts() async {
    try {
      final response = await ApiClient.dio.get('/discounts');

      final List<dynamic> data = response.data['data'];

      return data.map((item) => Discount.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil diskon: $e');
    }
  }
}
