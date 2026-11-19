import 'package:flutter/material.dart';
import 'package:muarra_app_v1/core/constants/app_colors.dart';
import 'package:muarra_app_v1/features/products/services/product_service.dart';
import 'package:muarra_app_v1/models/discount.dart';
import 'package:muarra_app_v1/models/food_item.dart';
import 'package:muarra_app_v1/widgets/checkout_panel.dart';
import 'package:muarra_app_v1/widgets/food_card.dart';
import 'package:muarra_app_v1/features/discounts/services/discount_service.dart';
import 'package:muarra_app_v1/features/checkout/pages/checkout_page.dart';
import 'package:muarra_app_v1/models/payment_type.dart';
import 'package:muarra_app_v1/features/orders/services/order_service.dart';

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

  final DiscountService _discountService = DiscountService();
  final OrderService _orderService = OrderService();

  List<Discount> discounts = [];
  Discount? appliedDiscount;
  bool isLoadingDiscounts = true;

  String customerName = '';
  PaymentType selectedPaymentType = PaymentType.cash;

  Future<void> _fetchDiscounts() async {
    try {
      final result = await _discountService.getDiscounts();

      if (!mounted) return;

      setState(() {
        discounts = result;
        isLoadingDiscounts = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingDiscounts = false;
      });

      debugPrint('Fetch discounts error: $e');
    }
  }

  final ProductService _productService = ProductService();

  List<FoodItem> products = [];
  bool isLoading = true;
  String? errorMessage;

  List<String> get categories => [
    allCategory,
    ...{for (final p in products) p.category},
  ];

  List<FoodItem> get filteredFoods => products.where((p) {
    final matchCategory =
        selectedCategory == allCategory || p.category == selectedCategory;

    final matchQuery = p.name.toLowerCase().contains(query.toLowerCase());

    return matchCategory && matchQuery;
  }).toList();

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _fetchDiscounts();
  }

  Future<void> _fetchProducts() async {
    try {
      final result = await _productService.getProducts();

      if (!mounted) return;

      setState(() {
        products = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

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

  void _clearCart() {
    setState(() {
      cart.clear();
      appliedDiscount = null;
    });
  }

  Future<Map<String, dynamic>> _createOrder(
    Map<String, dynamic> payload,
  ) async {
    final response = await _orderService.createOrder(
      custName: payload['cust_name'] ?? '',
      paymentType: payload['payment_type'],
      discountCode: payload['discount'],
      orderItems: List<Map<String, dynamic>>.from(payload['orderItems']),
    );

    return response;
  }

  Future<void> _checkout() async {
    if (cart.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutPage(
          items: cart.values.toList(),
          discount: appliedDiscount,
          customerName: customerName.trim().isEmpty
              ? null
              : customerName.trim(),
          paymentType: selectedPaymentType,
          onPaid: () {
            _clearCart();

            Navigator.pop(context);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pembayaran berhasil!')),
            );
          },
          onCreateOrder: _createOrder,
        ),
      ),
    );
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
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(errorMessage!),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    isLoading = true;
                                    errorMessage = null;
                                  });
                                  _fetchProducts();
                                },
                                child: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        )
                      : foods.isEmpty
                      ? const Center(child: Text('Menu tidak ditemukan'))
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
          discounts: discounts,
          appliedDiscount: appliedDiscount,
          onCustomerNameChanged: (value) {
            customerName = value;
          },
          onPaymentTypeChanged: (value) {
            selectedPaymentType = value;
          },
          onApplyDiscount: (d) => setState(() => appliedDiscount = d),
          onRemoveDiscount: () => setState(() => appliedDiscount = null),
          onIncrement: (item) => setState(() => item.qty++),
          onDecrement: _decrement,
          onClear: _clearCart,
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
