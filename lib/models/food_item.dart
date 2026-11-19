import 'package:flutter/material.dart';

class FoodItem {
  final String id;
  final String name;
  final String category;
  final int price;
  final int costPrice;
  final IconData icon;

  const FoodItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.costPrice,
    this.icon = Icons.inventory_2_rounded,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      category: json['category']?['name'] ?? 'Lainnya',
      price: (json['harga_jual'] as num).toInt(),
      costPrice: (json['harga_modal'] as num).toInt(),
    );
  }
}

class CartItem {
  final FoodItem food;
  int qty;

  CartItem({required this.food, this.qty = 1});

  int get total => food.price * qty;
}

String formatRupiah(int value) {
  final s = value.toString();
  final buffer = StringBuffer();

  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(s[i]);
  }

  return 'Rp $buffer';
}
