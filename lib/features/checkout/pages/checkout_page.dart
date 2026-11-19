import 'dart:async';

import 'package:flutter/material.dart';

import 'package:muarra_app_v1/core/constants/app_colors.dart';
import 'package:muarra_app_v1/models/discount.dart';
import 'package:muarra_app_v1/models/food_item.dart';
import 'package:muarra_app_v1/models/payment_type.dart';

class CheckoutPage extends StatelessWidget {
  final List<CartItem> items;
  final Discount? discount;
  final String? customerName;
  final PaymentType paymentType;
  final void Function(Map<String, dynamic> orderResponse) onPaid;

  // Callback untuk membuat order ke Laravel API.
  // Return value harus berupa response JSON dalam bentuk Map.
  final Future<Map<String, dynamic>> Function(Map<String, dynamic> payload)
  onCreateOrder;

  const CheckoutPage({
    super.key,
    required this.items,
    required this.discount,
    required this.customerName,
    required this.paymentType,
    required this.onPaid,
    required this.onCreateOrder,
  });

  int get subtotal => items.fold(0, (sum, item) => sum + item.total);
  int get discountAmount => discount?.amountFor(subtotal) ?? 0;
  int get total => subtotal - discountAmount;

  Map<String, dynamic> get orderPayload => {
    'cust_name': customerName ?? '',
    'payment_type': paymentType.name,
    if (discount != null) 'discount_code': discount!.code,
    'orderItems': items
        .map((item) => {'product_id': item.food.id, 'quantity': item.qty})
        .toList(),
  };

  @override
  Widget build(BuildContext context) {
    final isQris = paymentType == PaymentType.qris;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Checkout',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: isQris ? _buildQris(context) : _buildManualPayment(context),
        ),
      ),
    );
  }

  // =========================
  // QRIS PAYMENT
  // =========================

  Widget _buildQris(BuildContext context) {
    return QrisPaymentWidget(
      customerName: customerName,
      total: total,
      onCreateOrder: onCreateOrder,
      payload: orderPayload,
    );
  }

  // =========================
  // CARD / CASH PAYMENT
  // =========================

  Widget _buildManualPayment(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 700),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Detail Pembayaran',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    paymentType.label,
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Customer
          if (customerName != null && customerName!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_outline_rounded,
                    color: Color(0xFF858B98),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    customerName!,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

          // Item list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final item = items[index];

                return Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        item.food.icon,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.food.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${item.qty} × ${formatRupiah(item.food.price)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF858B98),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Text(
                      formatRupiah(item.total),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                );
              },
            ),
          ),

          // Summary
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
              border: Border(top: BorderSide(color: Color(0x0F000000))),
            ),
            child: Column(
              children: [
                _summaryRow('Subtotal', subtotal),
                const SizedBox(height: 10),

                if (discount != null) ...[
                  _summaryRow(
                    'Promo (${discount!.code})',
                    -discountAmount,
                    color: const Color(0xFF16A34A),
                  ),
                  const SizedBox(height: 10),
                ],

                _summaryRow('Total', total, bold: true),

                const SizedBox(height: 24),

                PaymentSlider(
                  onConfirmed: () async {
                    // Cash/card: order dibuat terlebih dahulu.
                    // Kalau API gagal, slider akan di-reset.
                    final response = await onCreateOrder(orderPayload);
                    onPaid(response);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    int value, {
    bool bold = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            fontSize: bold ? 16 : 13,
            color: bold ? const Color(0xFF111318) : const Color(0xFF858B98),
          ),
        ),
        Text(
          formatRupiah(value.abs()),
          style: TextStyle(
            fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
            fontSize: bold ? 20 : 13,
            color: color ?? (value < 0 ? const Color(0xFF16A34A) : null),
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

// =========================
// QRIS MIDTRANS
// =========================

class QrisPaymentWidget extends StatefulWidget {
  final String? customerName;
  final int total;
  final Map<String, dynamic> payload;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic> payload)
  onCreateOrder;

  const QrisPaymentWidget({
    super.key,
    required this.customerName,
    required this.total,
    required this.payload,
    required this.onCreateOrder,
  });

  @override
  State<QrisPaymentWidget> createState() => _QrisPaymentWidgetState();
}

class _QrisPaymentWidgetState extends State<QrisPaymentWidget> {
  bool isLoading = true;
  String? errorMessage;
  String? qrUrl;
  String? transactionId;

  @override
  void initState() {
    super.initState();
    _createQrisOrder();
  }

  Future<void> _createQrisOrder() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
      qrUrl = null;
      transactionId = null;
    });

    try {
      final response = await widget.onCreateOrder(widget.payload);

      // Response dari Laravel:
      // {
      //   "data": {...},
      //   "qris": {
      //     "transaction_id": "...",
      //     "transaction_status": "pending",
      //     "qr_url": "https://..."
      //   }
      // }

      final qris = response['qris'];

      if (qris == null || qris['qr_url'] == null) {
        throw Exception('QRIS URL tidak ditemukan dari server.');
      }

      if (!mounted) return;

      setState(() {
        qrUrl = qris['qr_url'].toString();
        transactionId = qris['transaction_id']?.toString();
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 460,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Pembayaran QRIS',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: 8),

          const Text(
            'Scan QR code di bawah untuk membayar',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF858B98)),
          ),

          const SizedBox(height: 28),

          // QR image from Midtrans
          Container(
            width: 252,
            height: 252,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: _buildQrContent(),
          ),

          const SizedBox(height: 24),

          if (widget.customerName != null &&
              widget.customerName!.isNotEmpty) ...[
            Text(
              widget.customerName!,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
          ],

          const Text(
            'Total Pembayaran',
            style: TextStyle(color: Color(0xFF858B98)),
          ),

          const SizedBox(height: 6),

          Text(
            formatRupiah(widget.total),
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryColor,
            ),
          ),

          const SizedBox(height: 16),

          if (!isLoading && errorMessage == null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7E6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    color: Color(0xFFB7791F),
                    size: 18,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Menunggu pembayaran',
                    style: TextStyle(
                      color: Color(0xFFB7791F),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

          if (transactionId != null) ...[
            const SizedBox(height: 12),
            Text(
              'Transaction ID: $transactionId',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Color(0xFF858B98)),
            ),
          ],

          const SizedBox(height: 24),

          if (errorMessage != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _createQrisOrder,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Kembali'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrContent() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Membuat QRIS...',
              style: TextStyle(fontSize: 12, color: Color(0xFF858B98)),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.red,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (qrUrl == null) {
      return const Center(child: Text('QR Code tidak tersedia'));
    }

    return Image.network(
      qrUrl!,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;

        return const Center(child: CircularProgressIndicator());
      },
      errorBuilder: (context, error, stackTrace) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image_rounded, size: 40),
              SizedBox(height: 8),
              Text(
                'Gagal memuat gambar QR',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }
}

// =========================
// SLIDE TO CONFIRM PAYMENT
// =========================

class PaymentSlider extends StatefulWidget {
  final Future<void> Function() onConfirmed;

  const PaymentSlider({super.key, required this.onConfirmed});

  @override
  State<PaymentSlider> createState() => _PaymentSliderState();
}

class _PaymentSliderState extends State<PaymentSlider> {
  double _progress = 0;
  bool _completed = false;
  bool _processing = false;

  Future<void> _confirmPayment() async {
    if (_processing || _completed) return;

    setState(() {
      _processing = true;
      _progress = 1;
    });

    try {
      await widget.onConfirmed();

      if (!mounted) return;

      setState(() {
        _completed = true;
        _processing = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _progress = 0;
        _completed = false;
        _processing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal membuat pesanan: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const knobSize = 52.0;
        final width = constraints.maxWidth;
        final maxDrag = width - knobSize;

        return Container(
          height: 58,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFFE8EBF0),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: Text(
                  _completed
                      ? 'Payment Confirmed'
                      : _processing
                      ? 'Processing Payment...'
                      : 'Slide to confirm payment  →',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: _completed ? Colors.white : const Color(0xFF858B98),
                  ),
                ),
              ),

              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: _progress * maxDrag + knobSize,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _completed
                        ? const Color(0xFF16A34A)
                        : AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              Positioned(
                left: _progress * maxDrag,
                child: GestureDetector(
                  onHorizontalDragUpdate: (_completed || _processing)
                      ? null
                      : (details) {
                          setState(() {
                            _progress = (_progress + details.delta.dx / maxDrag)
                                .clamp(0.0, 1.0);
                          });
                        },
                  onHorizontalDragEnd: (_completed || _processing)
                      ? null
                      : (_) {
                          if (_progress >= 0.85) {
                            _confirmPayment();
                          } else {
                            setState(() => _progress = 0);
                          }
                        },
                  child: Container(
                    width: knobSize,
                    height: knobSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _completed
                          ? Icons.check_rounded
                          : _processing
                          ? Icons.hourglass_top_rounded
                          : Icons.chevron_right_rounded,
                      color: _completed
                          ? const Color(0xFF16A34A)
                          : AppColors.primaryColor,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
