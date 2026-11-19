enum PaymentType { qris, card, cash }

extension PaymentTypeExtension on PaymentType {
  String get label {
    switch (this) {
      case PaymentType.qris:
        return 'QRIS';
      case PaymentType.card:
        return 'Card';
      case PaymentType.cash:
        return 'Cash';
    }
  }
}
