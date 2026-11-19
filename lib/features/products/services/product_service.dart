import 'package:muarra_app_v1/core/services/api_client.dart';
import 'package:muarra_app_v1/models/food_item.dart';

class ProductService {
  Future<List<FoodItem>> getProducts() async {
    try {
      final response = await ApiClient.dio.get('/products');

      final List<dynamic> data = response.data['data'];

      return data.map((item) => FoodItem.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil produk: $e');
    }
  }
}
