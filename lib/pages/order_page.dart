import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:muarra_app_v1/core/constants/app_colors.dart';
import 'package:muarra_app_v1/models/food_item.dart';
import 'package:muarra_app_v1/features/orders/services/order_service.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  static const double minTableWidth = 1050;

  final OrderService _ordersService = OrderService();

  List<Map<String, dynamic>> orders = [];

  bool isLoading = true;
  String? errorMessage;

  String query = '';
  String? statusFilter;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      final result = await _ordersService.getOrders();

      if (!mounted) return;

      setState(() {
        orders = result;
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get filtered {
    return orders.where((order) {
      final q = query.toLowerCase();

      final id = order['id'].toString();
      final customer = (order['cust_name'] ?? '').toString().toLowerCase();

      final matchQuery = id.contains(q) || customer.contains(q);

      final status = (order['payment_status'] ?? '').toString().toLowerCase();
      final matchStatus = statusFilter == null || status == statusFilter;

      return matchQuery && matchStatus;
    }).toList();
  }

  String _orderCode(dynamic id) {
    return 'ORD-${id.toString().padLeft(4, '0')}';
  }

  String _paymentLabel(dynamic value) {
    switch (value.toString().toLowerCase()) {
      case 'qris':
        return 'QRIS';
      case 'cash':
        return 'Cash';
      case 'card':
        return 'Card';
      default:
        return value.toString().toUpperCase();
    }
  }

  String _statusLabel(dynamic value) {
    switch (value.toString().toLowerCase()) {
      case 'paid':
        return 'Paid';
      case 'pending':
        return 'Pending';
      case 'cancelled':
        return 'Cancelled';
      case 'expired':
        return 'Expired';
      case 'denied':
        return 'Denied';
      default:
        return value.toString();
    }
  }

  Color _statusColor(dynamic value) {
    switch (value.toString().toLowerCase()) {
      case 'paid':
        return const Color(0xFF16A34A);
      case 'pending':
        return const Color(0xFFB7791F);
      case 'cancelled':
      case 'expired':
      case 'denied':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF858B98);
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';

    try {
      final date = DateTime.parse(value.toString()).toLocal();
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    } catch (_) {
      return '-';
    }
  }

  int _itemCount(Map<String, dynamic> order) {
    final items = order['order_items'] as List? ?? [];

    return items.fold<int>(
      0,
      (sum, item) => sum + ((item['quantity'] as num?)?.toInt() ?? 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = filtered;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildFilters(),
          const SizedBox(height: 20),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                ? _buildError()
                : _buildTable(data),
          ),
        ],
      ),
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
                'Orders',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111318),
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Daftar pesanan yang telah dibuat',
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
              hintText: 'Cari order atau customer...',
              hintStyle: const TextStyle(fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.zero,
              border: _inputBorder(Colors.black.withValues(alpha: 0.08)),
              enabledBorder: _inputBorder(Colors.black.withValues(alpha: 0.08)),
              focusedBorder: _inputBorder(AppColors.primaryColor),
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: () {
            setState(() {
              isLoading = true;
              errorMessage = null;
            });
            _fetchOrders();
          },
          tooltip: 'Refresh orders',
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }

  OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color),
  );

  Widget _buildFilters() {
    final options = <MapEntry<String, String?>>[
      const MapEntry('All', null),
      const MapEntry('Pending', 'pending'),
      const MapEntry('Paid', 'paid'),
      const MapEntry('Cancelled', 'cancelled'),
      const MapEntry('Expired', 'expired'),
      const MapEntry('Denied', 'denied'),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final opt = options[i];
          final selected = statusFilter == opt.value;

          return ChoiceChip(
            label: Text(opt.key),
            selected: selected,
            onSelected: (_) => setState(() => statusFilter = opt.value),
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

  Widget _buildError() {
    return Center(
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
              _fetchOrders();
            },
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<Map<String, dynamic>> data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tableWidth = constraints.maxWidth < minTableWidth
              ? minTableWidth
              : constraints.maxWidth;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: Column(
                      children: [
                        const _OrdersHeaderRow(),
                        const Divider(height: 1),
                        Expanded(
                          child: data.isEmpty
                              ? const _OrdersEmptyState()
                              : ListView.separated(
                                  itemCount: data.length,
                                  separatorBuilder: (_, _) => Divider(
                                    height: 1,
                                    color: Colors.black.withValues(alpha: 0.05),
                                  ),
                                  itemBuilder: (context, i) =>
                                      _buildRow(data[i]),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  border: Border(
                    top: BorderSide(
                      color: Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                child: Text(
                  'Menampilkan ${data.length} dari ${orders.length} order',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF858B98),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> order) {
    final status = order['payment_status'] ?? '';
    final statusColor = _statusColor(status);

    return InkWell(
      onTap: () {
        // Nanti bisa diisi untuk membuka detail order.
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // Order ID
            Expanded(
              flex: 2,
              child: Text(
                _orderCode(order['id']),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryColor,
                ),
              ),
            ),

            // Customer
            Expanded(
              flex: 2,
              child: Text(
                (order['cust_name'] ?? 'Guest').toString().isEmpty
                    ? 'Guest'
                    : order['cust_name'].toString(),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111318),
                ),
              ),
            ),

            // Items
            Expanded(
              flex: 1,
              child: Text(
                '${_itemCount(order)} items',
                style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
              ),
            ),

            // Subtotal
            Expanded(
              flex: 2,
              child: Text(
                formatRupiah((order['subtotal'] as num?)?.toInt() ?? 0),
                style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
              ),
            ),

            // Total
            Expanded(
              flex: 2,
              child: Text(
                formatRupiah((order['total'] as num?)?.toInt() ?? 0),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111318),
                ),
              ),
            ),

            // Payment method
            Expanded(
              flex: 1,
              child: Text(
                _paymentLabel(order['payment_type']),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4B5563),
                ),
              ),
            ),

            // Status
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ),
            ),

            // Date
            Expanded(
              flex: 2,
              child: Text(
                _formatDate(order['created_at']),
                style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersHeaderRow extends StatelessWidget {
  const _OrdersHeaderRow();

  static const style = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
    color: Color(0xFF858B98),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF9FAFB),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: const Row(
        children: [
          Expanded(flex: 2, child: Text('ORDER ID', style: style)),
          Expanded(flex: 2, child: Text('CUSTOMER', style: style)),
          Expanded(flex: 1, child: Text('ITEMS', style: style)),
          Expanded(flex: 2, child: Text('SUBTOTAL', style: style)),
          Expanded(flex: 2, child: Text('TOTAL', style: style)),
          Expanded(flex: 1, child: Text('PAYMENT', style: style)),
          Expanded(flex: 2, child: Text('STATUS', style: style)),
          Expanded(flex: 2, child: Text('DATE', style: style)),
        ],
      ),
    );
  }
}

class _OrdersEmptyState extends StatelessWidget {
  const _OrdersEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_rounded, size: 44, color: Color(0xFFCBD0D8)),
          SizedBox(height: 12),
          Text(
            'Order tidak ditemukan',
            style: TextStyle(
              color: Color(0xFF858B98),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
