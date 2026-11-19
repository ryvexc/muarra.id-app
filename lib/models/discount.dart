enum DiscountType { percent, fixed }

class Discount {
  final String id;
  final String code;
  final String label;
  final DiscountType type;
  final int value;
  final DateTime? expiryDate;

  final int minSubtotal;
  final int? maxDiscount;

  const Discount({
    required this.id,
    required this.code,
    required this.label,
    required this.type,
    required this.value,
    this.expiryDate,
    this.minSubtotal = 0,
    this.maxDiscount,
  });

  factory Discount.fromJson(Map<String, dynamic> json) {
    return Discount(
      id: json['id'].toString(),
      code: json['name'] ?? '',
      label: json['description'] ?? '',
      type: json['type'] == 'percentage'
          ? DiscountType.percent
          : DiscountType.fixed,
      value: int.tryParse(json['value'].toString()) ?? 0,
      expiryDate: json['expiry_date'] != null
          ? DateTime.tryParse(json['expiry_date'].toString())
          : null,
    );
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    return !DateTime.now().isBefore(expiryDate!);
  }

  int amountFor(int subtotal) {
    if (type == DiscountType.percent) {
      final amount = (subtotal * value / 100).round();

      if (maxDiscount != null) {
        return amount.clamp(0, maxDiscount!);
      }

      return amount.clamp(0, subtotal);
    }

    return value.clamp(0, subtotal);
  }
}
