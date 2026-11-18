import 'package:flutter/material.dart';
import 'package:muarra_app_v1/core/constants/app_colors.dart';
import 'package:muarra_app_v1/models/discount.dart';
import 'package:muarra_app_v1/models/food_item.dart';

class CheckoutPanel extends StatefulWidget {
  final List<CartItem> items;
  final Discount? appliedDiscount;
  final ValueChanged<Discount> onApplyDiscount;
  final VoidCallback onRemoveDiscount;
  final ValueChanged<CartItem> onIncrement;
  final ValueChanged<CartItem> onDecrement;
  final VoidCallback onClear;
  final VoidCallback onCheckout;

  static const double taxRate = 0.10;

  const CheckoutPanel({
    super.key,
    required this.items,
    required this.appliedDiscount,
    required this.onApplyDiscount,
    required this.onRemoveDiscount,
    required this.onIncrement,
    required this.onDecrement,
    required this.onClear,
    required this.onCheckout,
  });

  @override
  State<CheckoutPanel> createState() => _CheckoutPanelState();
}

class _CheckoutPanelState extends State<CheckoutPanel> {
  static const Color successColor = Color(0xFF16A34A);

  final TextEditingController _codeController = TextEditingController();
  String? _error;

  int get subtotal => widget.items.fold(0, (sum, e) => sum + e.total);
  int get discountAmount => widget.appliedDiscount?.amountFor(subtotal) ?? 0;
  int get tax => ((subtotal - discountAmount) * CheckoutPanel.taxRate).round();
  int get total => subtotal - discountAmount + tax;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _applyCode() {
    final input = _codeController.text.trim();

    if (input.isEmpty) {
      setState(() => _error = 'Masukkan kode diskon');
      return;
    }
    if (widget.items.isEmpty) {
      setState(() => _error = 'Tambahkan menu terlebih dahulu');
      return;
    }

    final discount = Discount.find(input);
    if (discount == null) {
      setState(() => _error = 'Kode diskon tidak valid');
      return;
    }
    if (subtotal < discount.minSubtotal) {
      setState(
        () => _error = 'Minimal belanja ${formatRupiah(discount.minSubtotal)}',
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    _codeController.clear();
    widget.onApplyDiscount(discount);
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;

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
                    onPressed: widget.onClear,
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
                      onIncrement: () => widget.onIncrement(items[i]),
                      onDecrement: () => widget.onDecrement(items[i]),
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
                // DISCOUNT CODE (di atas subtotal)
                _buildDiscountSection(),
                const SizedBox(height: 16),

                _SummaryRow(label: 'Subtotal', value: formatRupiah(subtotal)),
                if (discountAmount > 0) ...[
                  const SizedBox(height: 8),
                  _SummaryRow(
                    label: 'Diskon (${widget.appliedDiscount!.code})',
                    value: '-${formatRupiah(discountAmount)}',
                    valueColor: successColor,
                  ),
                ],
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
                    onPressed: items.isEmpty ? null : widget.onCheckout,
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

  Widget _buildDiscountSection() {
    final applied = widget.appliedDiscount;

    // Kode sudah dipakai -> tampilkan chip
    if (applied != null) {
      final unmet = subtotal < applied.minSubtotal;
      final color = unmet ? const Color(0xFFD97706) : successColor;

      return Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(
              unmet ? Icons.info_outline_rounded : Icons.sell_rounded,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    applied.code,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    unmet
                        ? 'Min. belanja ${formatRupiah(applied.minSubtotal)} belum terpenuhi'
                        : applied.label,
                    style: TextStyle(fontSize: 11, color: color),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: widget.onRemoveDiscount,
              tooltip: 'Hapus kode',
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.close_rounded, size: 18, color: color),
            ),
          ],
        ),
      );
    }

    // Belum ada kode -> tampilkan input
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _applyCode(),
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Kode diskon',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0,
                    ),
                    prefixIcon: const Icon(Icons.sell_outlined, size: 18),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.zero,
                    border: _inputBorder(Colors.black.withValues(alpha: 0.1)),
                    enabledBorder: _inputBorder(
                      _error != null
                          ? const Color(0xFFDC2626)
                          : Colors.black.withValues(alpha: 0.1),
                    ),
                    focusedBorder: _inputBorder(
                      _error != null
                          ? const Color(0xFFDC2626)
                          : AppColors.primaryColor,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: _applyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Pakai',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              _error!,
              style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626)),
            ),
          ),
      ],
    );
  }

  OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color),
  );
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
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontSize: bold ? 16 : 13,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      color: bold ? const Color(0xFF111318) : const Color(0xFF858B98),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: base),
        Text(
          value,
          style: valueColor != null
              ? base.copyWith(color: valueColor, fontWeight: FontWeight.w700)
              : base,
        ),
      ],
    );
  }
}
