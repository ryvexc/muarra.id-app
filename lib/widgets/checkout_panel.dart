import 'package:flutter/material.dart';
import 'package:muarra_app_v1/core/constants/app_colors.dart';
import 'package:muarra_app_v1/models/food_item.dart';

class CheckoutPanel extends StatelessWidget {
  final List<CartItem> items;
  final ValueChanged<CartItem> onIncrement;
  final ValueChanged<CartItem> onDecrement;
  final VoidCallback onClear;
  final VoidCallback onCheckout;

  static const double taxRate = 0.10;

  const CheckoutPanel({
    super.key,
    required this.items,
    required this.onIncrement,
    required this.onDecrement,
    required this.onClear,
    required this.onCheckout,
  });

  int get subtotal => items.fold(0, (sum, e) => sum + e.total);
  int get tax => (subtotal * taxRate).round();
  int get total => subtotal + tax;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 12, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Pesanan',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111318),
                    ),
                  ),
                ),
                if (items.isNotEmpty)
                  TextButton(
                    onPressed: onClear,
                    child: const Text('Hapus semua'),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Items
          Expanded(
            child: items.isEmpty
                ? const _EmptyCart()
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _CartRow(
                      item: items[i],
                      onIncrement: () => onIncrement(items[i]),
                      onDecrement: () => onDecrement(items[i]),
                    ),
                  ),
          ),

          // Summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              border: Border(
                top: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
              ),
            ),
            child: Column(
              children: [
                _SummaryRow(label: 'Subtotal', value: formatRupiah(subtotal)),
                const SizedBox(height: 8),
                _SummaryRow(label: 'Pajak (10%)', value: formatRupiah(tax)),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                _SummaryRow(
                  label: 'Total',
                  value: formatRupiah(total),
                  bold: true,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: items.isEmpty ? null : onCheckout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primaryColor
                          .withValues(alpha: 0.3),
                      disabledForegroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Checkout',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 48,
            color: Color(0xFFCBD0D8),
          ),
          SizedBox(height: 12),
          Text(
            'Belum ada pesanan',
            style: TextStyle(
              color: Color(0xFF858B98),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Pilih menu di sebelah kiri',
            style: TextStyle(color: Color(0xFFB0B5C0), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _CartRow extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _CartRow({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(item.food.icon, color: AppColors.primaryColor, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.food.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111318),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                formatRupiah(item.total),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        _QtyButton(icon: Icons.remove_rounded, onTap: onDecrement),
        SizedBox(
          width: 28,
          child: Text(
            '${item.qty}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
        _QtyButton(icon: Icons.add_rounded, onTap: onIncrement, filled: true),
      ],
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _QtyButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: filled ? AppColors.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: filled
                ? AppColors.primaryColor
                : Colors.black.withValues(alpha: 0.12),
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: filled ? Colors.white : const Color(0xFF111318),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: bold ? 16 : 13,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      color: bold ? const Color(0xFF111318) : const Color(0xFF858B98),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}
