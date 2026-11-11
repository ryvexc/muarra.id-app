import 'package:flutter/material.dart';
import 'package:muarra_app_v1/core/constants/app_colors.dart';
import 'package:muarra_app_v1/models/food_item.dart';
import 'package:muarra_app_v1/widgets/checkout_panel.dart';
import 'package:muarra_app_v1/widgets/food_card.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  static const String allCategory = 'Semua';

  String selectedCategory = allCategory;
  String query = '';

  /// key = food.id
  final Map<String, CartItem> cart = {};

  List<String> get categories => [
    allCategory,
    ...{for (final f in dummyFoods) f.category},
  ];

  List<FoodItem> get filteredFoods => dummyFoods.where((f) {
    final matchCategory =
        selectedCategory == allCategory || f.category == selectedCategory;
    final matchQuery = f.name.toLowerCase().contains(query.toLowerCase());
    return matchCategory && matchQuery;
  }).toList();

  void _add(FoodItem food) {
    setState(() {
      final existing = cart[food.id];
      if (existing != null) {
        existing.qty++;
      } else {
        cart[food.id] = CartItem(food: food);
      }
    });
  }

  void _decrement(CartItem item) {
    setState(() {
      if (item.qty > 1) {
        item.qty--;
      } else {
        cart.remove(item.food.id);
      }
    });
  }

  Future<void> _checkout() async {
    final total = cart.values.fold<int>(0, (s, e) => s + e.total);
    final grand = total + (total * CheckoutPanel.taxRate).round();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Pesanan'),
        content: Text(
          '${cart.length} jenis menu\nTotal: ${formatRupiah(grand)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Bayar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // TODO: kirim order ke backend / simpan ke database
      setState(cart.clear);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pesanan berhasil dibuat')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final foods = filteredFoods;

    return Row(
      children: [
        // MENU AREA
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildCategories(),
                const SizedBox(height: 20),
                Expanded(
                  child: foods.isEmpty
                      ? const Center(
                          child: Text(
                            'Menu tidak ditemukan',
                            style: TextStyle(color: Color(0xFF858B98)),
                          ),
                        )
                      : GridView.builder(
                          itemCount: foods.length,
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 220,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 0.82,
                              ),
                          itemBuilder: (context, i) {
                            final food = foods[i];
                            return FoodCard(
                              food: food,
                              qtyInCart: cart[food.id]?.qty ?? 0,
                              onTap: () => _add(food),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),

        // CHECKOUT
        CheckoutPanel(
          items: cart.values.toList(),
          onIncrement: (item) => setState(() => item.qty++),
          onDecrement: _decrement,
          onClear: () => setState(cart.clear),
          onCheckout: _checkout,
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Menu',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111318),
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Pilih menu untuk ditambahkan ke pesanan',
                style: TextStyle(fontSize: 13, color: Color(0xFF858B98)),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 260,
          child: TextField(
            onChanged: (v) => setState(() => query = v),
            decoration: InputDecoration(
              hintText: 'Cari menu...',
              hintStyle: const TextStyle(fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.black.withValues(alpha: 0.08),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.black.withValues(alpha: 0.08),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryColor),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final cat = categories[i];
          final selected = cat == selectedCategory;
          return ChoiceChip(
            label: Text(cat),
            selected: selected,
            onSelected: (_) => setState(() => selectedCategory = cat),
            showCheckmark: false,
            backgroundColor: Colors.white,
            selectedColor: AppColors.primaryColor,
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : const Color(0xFF4B5563),
            ),
            side: BorderSide(
              color: selected
                  ? AppColors.primaryColor
                  : Colors.black.withValues(alpha: 0.08),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }
}
