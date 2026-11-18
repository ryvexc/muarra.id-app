enum DiscountType { percent, fixed }

class Discount {
  final String code;
  final String label;
  final DiscountType type;

  /// percent: 10 = 10%, fixed: nominal rupiah
  final int value;

  /// Minimal belanja (subtotal) agar kode bisa dipakai
  final int minSubtotal;

  /// Batas maksimal potongan (untuk tipe percent)
  final int? maxDiscount;

  const Discount({
    required this.code,
    required this.label,
    required this.type,
    required this.value,
    this.minSubtotal = 0,
    this.maxDiscount,
  });

  /// Besar potongan untuk [subtotal]. 0 kalau minimal belanja belum terpenuhi.
  int amountFor(int subtotal) {
    if (subtotal < minSubtotal) return 0;

    int amount = type == DiscountType.percent
        ? (subtotal * value / 100).round()
        : value;

    if (maxDiscount != null && amount > maxDiscount!) amount = maxDiscount!;
    if (amount > subtotal) amount = subtotal;
    return amount;
  }

  /// TODO: ganti dengan validasi ke backend/database.
  static const List<Discount> available = [
    Discount(
      code: 'DISKON5K',
      label: 'Potongan Rp 5.000',
      type: DiscountType.fixed,
      value: 5000,
    ),
    Discount(
      code: 'HEMAT10',
      label: 'Diskon 10% (maks. Rp 20.000)',
      type: DiscountType.percent,
      value: 10,
      minSubtotal: 50000,
      maxDiscount: 20000,
    ),
    Discount(
      code: 'MUARRA20',
      label: 'Diskon 20% (maks. Rp 50.000)',
      type: DiscountType.percent,
      value: 20,
      minSubtotal: 100000,
      maxDiscount: 50000,
    ),
  ];

  static Discount? find(String input) {
    final code = input.trim().toUpperCase();
    for (final d in available) {
      if (d.code == code) return d;
    }
    return null;
  }
}
