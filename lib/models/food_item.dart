import 'package:flutter/material.dart';

class FoodItem {
  final String id;
  final String name;
  final String category;
  final int price;
  final IconData icon;

  const FoodItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.icon,
  });
}

class CartItem {
  final FoodItem food;
  int qty;

  CartItem({required this.food, this.qty = 1});

  int get total => food.price * qty;
}

/// 25000 -> "Rp 25.000"
String formatRupiah(int value) {
  final s = value.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
    buffer.write(s[i]);
  }
  return 'Rp $buffer';
}

const List<FoodItem> dummyFoods = [
  FoodItem(
    id: 'f1',
    name: 'Nasi Goreng Spesial',
    category: 'Makanan',
    price: 28000,
    icon: Icons.rice_bowl_rounded,
  ),
  FoodItem(
    id: 'f2',
    name: 'Mie Ayam Bakso',
    category: 'Makanan',
    price: 24000,
    icon: Icons.ramen_dining_rounded,
  ),
  FoodItem(
    id: 'f3',
    name: 'Ayam Geprek',
    category: 'Makanan',
    price: 26000,
    icon: Icons.set_meal_rounded,
  ),
  FoodItem(
    id: 'f4',
    name: 'Sate Ayam (10 tusuk)',
    category: 'Makanan',
    price: 32000,
    icon: Icons.kebab_dining_rounded,
  ),
  FoodItem(
    id: 'f5',
    name: 'Es Teh Manis',
    category: 'Minuman',
    price: 6000,
    icon: Icons.local_cafe_rounded,
  ),
  FoodItem(
    id: 'f6',
    name: 'Es Jeruk',
    category: 'Minuman',
    price: 9000,
    icon: Icons.local_drink_rounded,
  ),
  FoodItem(
    id: 'f7',
    name: 'Kopi Susu',
    category: 'Minuman',
    price: 15000,
    icon: Icons.coffee_rounded,
  ),
  FoodItem(
    id: 'f8',
    name: 'Jus Alpukat',
    category: 'Minuman',
    price: 18000,
    icon: Icons.blender_rounded,
  ),
  FoodItem(
    id: 'f9',
    name: 'Kentang Goreng',
    category: 'Snack',
    price: 14000,
    icon: Icons.fastfood_rounded,
  ),
  FoodItem(
    id: 'f10',
    name: 'Pisang Goreng',
    category: 'Snack',
    price: 12000,
    icon: Icons.bakery_dining_rounded,
  ),
  FoodItem(
    id: 'f11',
    name: 'Es Krim Vanilla',
    category: 'Dessert',
    price: 13000,
    icon: Icons.icecream_rounded,
  ),
  FoodItem(
    id: 'f12',
    name: 'Pudding Coklat',
    category: 'Dessert',
    price: 11000,
    icon: Icons.cake_rounded,
  ),
];
