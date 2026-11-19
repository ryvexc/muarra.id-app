import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:muarra_app_v1/core/constants/app_colors.dart';
import 'package:muarra_app_v1/features/discounts/services/discount_service.dart';
import 'package:muarra_app_v1/models/discount.dart';
import 'package:muarra_app_v1/models/food_item.dart';
import 'package:muarra_app_v1/features/discounts/services/discount_service.dart';

class DiscountsPage extends StatefulWidget {
  const DiscountsPage({super.key});

  @override
  State<DiscountsPage> createState() => _DiscountsPageState();
}

class _DiscountsPageState extends State<DiscountsPage> {
  static const Color successColor = Color(0xFF16A34A);
  static const double minTableWidth = 760;

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Kode $code disalin'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  String query = '';
  DiscountType? typeFilter;

  final DiscountService _discountService = DiscountService();

  List<Discount> discounts = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDiscounts();
  }

  Future<void> _fetchDiscounts() async {
    try {
      final result = await _discountService.getDiscounts();

      if (!mounted) return;

      setState(() {
        discounts = result;
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

  List<Discount> get filtered => discounts.where((d) {
    final matchType = typeFilter == null || d.type == typeFilter;
    final q = query.toLowerCase();

    final matchQuery =
        d.code.toLowerCase().contains(q) || d.label.toLowerCase().contains(q);

    return matchType && matchQuery;
  }).toList();

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
                            _fetchDiscounts();
                          },
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  )
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
                'Diskon',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111318),
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Daftar kode diskon yang tersedia',
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
              hintText: 'Cari kode atau keterangan...',
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
      ],
    );
  }

  OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color),
  );

  Widget _buildFilters() {
    final options = <MapEntry<String, DiscountType?>>[
      const MapEntry('Semua', null),
      const MapEntry('Persen', DiscountType.percent),
      const MapEntry('Nominal', DiscountType.fixed),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final opt = options[i];
          final selected = typeFilter == opt.value;
          return ChoiceChip(
            label: Text(opt.key),
            selected: selected,
            onSelected: (_) => setState(() => typeFilter = opt.value),
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

  Widget _buildTable(List<Discount> data) {
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
                        const _HeaderRow(),
                        const Divider(height: 1),
                        Expanded(
                          child: data.isEmpty
                              ? const _EmptyState()
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
                  'Menampilkan ${data.length} dari ${discounts.length} kode',
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

  Widget _buildRow(Discount d) {
    final isPercent = d.type == DiscountType.percent;
    final typeColor = isPercent ? AppColors.primaryColor : successColor;

    return InkWell(
      onTap: () => _copyCode(d.code),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // Kode
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
                    color: AppColors.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    d.code,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ),
            ),
            // Keterangan
            Expanded(
              flex: 4,
              child: Text(
                d.label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111318),
                ),
              ),
            ),
            // Tipe
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isPercent ? 'Persen' : 'Nominal',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: typeColor,
                    ),
                  ),
                ),
              ),
            ),
            // Nilai
            Expanded(
              flex: 2,
              child: Text(
                isPercent ? '${d.value}%' : formatRupiah(d.value),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111318),
                ),
              ),
            ),
            // Min. belanja
            Expanded(
              flex: 2,
              child: Text(
                d.minSubtotal > 0 ? formatRupiah(d.minSubtotal) : '-',
                style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
              ),
            ),
            // Maks. diskon
            Expanded(
              flex: 2,
              child: Text(
                d.maxDiscount != null ? formatRupiah(d.maxDiscount!) : '-',
                style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
      color: Color(0xFF858B98),
    );

    return Container(
      color: const Color(0xFFF9FAFB),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: const Row(
        children: [
          Expanded(flex: 2, child: Text('KODE', style: style)),
          Expanded(flex: 4, child: Text('KETERANGAN', style: style)),
          Expanded(flex: 2, child: Text('TIPE', style: style)),
          Expanded(flex: 2, child: Text('NILAI', style: style)),
          Expanded(flex: 2, child: Text('MIN. BELANJA', style: style)),
          Expanded(flex: 2, child: Text('MAKS. DISKON', style: style)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sell_outlined, size: 44, color: Color(0xFFCBD0D8)),
          SizedBox(height: 12),
          Text(
            'Kode diskon tidak ditemukan',
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
