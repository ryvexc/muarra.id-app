import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:muarra_app_v1/features/auth/services/auth_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';

import 'package:muarra_app_v1/core/constants/app_colors.dart';

class ReceiptItem {
  final String name;
  final int quantity;
  final int price;

  const ReceiptItem({
    required this.name,
    required this.quantity,
    required this.price,
  });

  int get total => quantity * price;
}

class ReceiptData {
  final String orderNumber;
  final String customerName;
  final DateTime date;
  final List<ReceiptItem> items;
  final int subtotal;
  final int discount;
  final int total;
  final String paymentMethod;
  final String tenantName;
  final String branchName;
  final String cashierId;
  final String cashierName;

  const ReceiptData({
    required this.orderNumber,
    required this.customerName,
    required this.date,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.paymentMethod,
    this.tenantName = 'MUARRA',
    this.branchName = 'MAIN BRANCH',
    this.cashierId = '99',
    this.cashierName = 'LARA',
  });
}

class NotePage extends StatefulWidget {
  final ReceiptData receipt;
  final VoidCallback onFinished;

  const NotePage({super.key, required this.receipt, required this.onFinished});

  @override
  State<NotePage> createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  static const double paperWidthMm = 58; // 58 atau 80
  static const double receiptFontSize = 9;
  static const double receiptLineHeightMm = 4.0;

  int get charsPerLine =>
      ((paperWidthMm * PdfPageFormat.mm) / (receiptFontSize * 0.6)).floor();

  List<Printer> printers = [];
  Printer? selectedPrinter;

  bool isLoadingPrinters = true;
  bool isPrinting = false;
  bool isPrinted = false;

  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPrinters();
  }

  String get currency {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(0).replaceAll('0', '');
  }

  String formatCurrency(int value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  Future<void> _loadPrinters() async {
    setState(() {
      isLoadingPrinters = true;
      errorMessage = null;
    });

    try {
      final result = await Printing.listPrinters();

      if (!mounted) return;

      setState(() {
        printers = result;

        if (printers.isNotEmpty) {
          selectedPrinter ??= printers.firstWhere(
            (p) => p.isDefault,
            orElse: () => printers.first,
          );
        }

        isLoadingPrinters = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingPrinters = false;
        errorMessage = 'Unable to detect printers.';
      });
    }
  }

  Future<void> _printReceipt() async {
    if (selectedPrinter == null) {
      setState(() => errorMessage = 'Please select a printer first.');
      return;
    }

    setState(() {
      isPrinting = true;
      isPrinted = false;
      errorMessage = null;
    });

    try {
      final heightMm = _calculateReceiptHeight();

      final format = PdfPageFormat(
        paperWidthMm * PdfPageFormat.mm,
        heightMm * PdfPageFormat.mm,
        marginLeft: 0,
        marginRight: 0,
        marginTop: 0,
        marginBottom: 0,
      );

      final pdfBytes = await _generateReceiptPdf();

      final success = await Printing.directPrintPdf(
        printer: selectedPrinter!,
        name: 'Muarra Receipt',
        format: format,
        dynamicLayout: false,
        onLayout: (_) async => pdfBytes,
      );

      if (!mounted) return;

      if (success) {
        setState(() {
          isPrinted = true;
          isPrinting = false;
        });

        await Future.delayed(const Duration(milliseconds: 900));

        if (mounted) widget.onFinished();
      } else {
        setState(() {
          isPrinting = false;
          errorMessage = 'The printer could not complete the print job.';
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Print error: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        isPrinting = false;
        errorMessage = 'Printing failed. Check the printer connection.';
      });
    }
  }

  int get _charsPerLine {
    return (paperWidthMm * 72 / 25.4 / (receiptFontSize * 0.6)).floor();
  }

  List<String> _wrapReceiptText(String text, int width) {
    if (text.isEmpty) return [''];

    final words = text.split(' ');
    final lines = <String>[];
    var current = '';

    for (final word in words) {
      final candidate = current.isEmpty ? word : '$current $word';

      if (candidate.length > width && current.isNotEmpty) {
        lines.add(current);
        current = word;
      } else {
        current = candidate;
      }
    }

    if (current.isNotEmpty) lines.add(current);
    return lines;
  }

  String _fitReceiptText(String text, int width) {
    if (text.length <= width) return text;
    if (width <= 1) return text.substring(0, width);
    return '${text.substring(0, width - 1)}…';
  }

  String _receiptMoney(int value) {
    return NumberFormat('#,##0', 'id_ID').format(value);
  }

  double _receiptFontSize = 7.5;
  int _receiptCharsPerLine = 0;
  int _receiptNameWidth = 0;
  int _receiptQtyWidth = 0;
  int _receiptPriceWidth = 0;
  int _receiptTotalWidth = 0;

  void _calculateReceiptColumns() {
    // Estimasi karakter Courier: 0.6 * fontSize points
    final widthPoints = paperWidthMm * PdfPageFormat.mm;
    _receiptCharsPerLine = (widthPoints / (_receiptFontSize * 0.6)).floor();

    _receiptQtyWidth = 2;
    _receiptPriceWidth = 9;
    _receiptTotalWidth = 9;

    // 3 spasi sebagai pemisah kolom
    _receiptNameWidth =
        _receiptCharsPerLine -
        _receiptQtyWidth -
        _receiptPriceWidth -
        _receiptTotalWidth -
        3;

    if (_receiptNameWidth < 5) {
      _receiptFontSize = 6.5;
      _receiptCharsPerLine = (widthPoints / (_receiptFontSize * 0.6)).floor();

      _receiptNameWidth =
          _receiptCharsPerLine -
          _receiptQtyWidth -
          _receiptPriceWidth -
          _receiptTotalWidth -
          3;
    }
  }

  String _receiptItemRow(String name, int qty, int price, int total) {
    final itemName = _fitReceiptText(
      name,
      _receiptNameWidth,
    ).padRight(_receiptNameWidth);
    final qtyText = qty.toString().padLeft(_receiptQtyWidth);
    final priceText = _receiptMoney(price).padLeft(_receiptPriceWidth);
    final totalText = _receiptMoney(total).padLeft(_receiptTotalWidth);

    return [itemName, qtyText, priceText, totalText].join(' ');
  }

  String _receiptRightRow(String label, int value) {
    final amount = _receiptMoney(value);
    final leftWidth = _receiptCharsPerLine - amount.length;

    return '${label.padLeft(leftWidth)}$amount';
  }

  double _calculateReceiptHeight() {
    _calculateReceiptColumns();

    int lines = 0;

    lines += 2; // header
    lines += 1; // divider
    lines += 1; // date & cashier/order
    lines += 1; // divider

    lines += widget.receipt.items.length; // item rows
    lines += 1; // divider
    lines += 2; // subtotal & total
    if (widget.receipt.discount > 0) lines += 1;

    lines += 1; // divider
    lines += 2; // paid by & for
    lines += 1; // blank spacing
    lines += 2; // footer

    return lines * 3.5 + 4;
  }

  Future<Uint8List> _generateReceiptPdf() async {
    final receipt = widget.receipt;
    final pdf = pw.Document();
    final user = await AuthService().getMe();

    _calculateReceiptColumns();

    final width = paperWidthMm * PdfPageFormat.mm;
    final height = _calculateReceiptHeight() * PdfPageFormat.mm;

    final format = PdfPageFormat(
      width,
      height,
      marginLeft: 0,
      marginRight: 0,
      marginTop: 0,
      marginBottom: 0,
    );

    final normal = pw.TextStyle(
      font: pw.Font.courier(),
      fontSize: _receiptFontSize,
    );

    final bold = pw.TextStyle(
      font: pw.Font.courierBold(),
      fontSize: _receiptFontSize,
    );

    pw.Widget txt(
      String text, {
      bool boldText = false,
      pw.TextAlign align = pw.TextAlign.left,
    }) {
      return pw.Container(
        width: width,
        child: pw.Text(
          text,
          textAlign: align,
          style: boldText ? bold : normal,
          maxLines: 1,
        ),
      );
    }

    final separator = '-' * _receiptCharsPerLine;

    final dateText = DateFormat('dd.MM.yy-HH:mm/ss').format(receipt.date);

    final cashierOrder =
        '${user['id']}/${user['name'].split(' ')[0].toString().toUpperCase()}/${receipt.orderNumber}';

    final content = <pw.Widget>[
      // Tenant & Branch
      txt(
        _fitReceiptText(
          '${receipt.tenantName} - ${receipt.branchName}',
          _receiptCharsPerLine,
        ),
        boldText: true,
        align: pw.TextAlign.center,
      ),
      txt('Thank you for your purchase!', align: pw.TextAlign.center),
      txt(separator),

      // Date and cashier/order identity
      pw.Container(
        width: width,
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(dateText, style: normal),
            pw.Text(cashierOrder, style: normal),
          ],
        ),
      ),
      txt(separator),

      // Item rows
      ...receipt.items.map((item) {
        final name = txt(item.name, boldText: true);

        final qty = item.quantity.toString();
        final price = _receiptMoney(item.price);
        final total = _receiptMoney(item.total);

        final detailLeft = '$qty  $price';
        final spacing = _receiptCharsPerLine - detailLeft.length - total.length;

        final detail = '$detailLeft${' ' * (spacing > 0 ? spacing : 1)}$total';

        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [name, txt(detail)],
        );
      }),

      txt(separator),

      // Summary
      txt(_receiptRightRow('Subtotal ', receipt.subtotal)),
      if (receipt.discount > 0)
        txt(_receiptRightRow('Discount ', receipt.discount)),
      txt(_receiptRightRow('TOTAL ', receipt.total), boldText: true),

      txt(separator),

      // Payment & customer
      txt('Paid by : ${receipt.paymentMethod}'),
      ..._wrapReceiptText(
        'For     : ${receipt.customerName}',
        _receiptCharsPerLine,
      ).map((e) => txt(e)),

      // Footer
      txt('\n'),
      txt('Thank you & see you again!', align: pw.TextAlign.center),
      txt('Powered by Muarra', align: pw.TextAlign.center),
    ];

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        margin: pw.EdgeInsets.zero,
        build: (context) {
          return pw.Container(
            width: width,
            padding: pw.EdgeInsets.zero,
            alignment: pw.Alignment.topLeft,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisSize: pw.MainAxisSize.min,
              children: content,
            ),
          );
        },
      ),
    );

    final bytes = await pdf.save();

    debugPrint('Receipt PDF: ${bytes.length} bytes');
    debugPrint('Paper width: $paperWidthMm mm');
    debugPrint('Paper height: ${_calculateReceiptHeight()} mm');
    debugPrint('Characters per line: $_receiptCharsPerLine');

    return bytes;
  }

  pw.Widget _pdfSummary(String label, int value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            formatCurrency(value.abs()),
            style: pw.TextStyle(
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final receipt = widget.receipt;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildReceiptPreview(receipt)),
                        const SizedBox(width: 24),
                        SizedBox(width: 320, child: _buildPrinterPanel()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (isPrinting || isPrinted) _buildPrintingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF16A34A),
            size: 26,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment successful',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111318),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Your order is complete. Would you like to print the receipt?',
                style: TextStyle(color: Color(0xFF858B98)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptPreview(ReceiptData receipt) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'MUARRA',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Thank you for your purchase!',
                style: TextStyle(color: Color(0xFF858B98)),
              ),
              const SizedBox(height: 20),
              const Divider(),
              _receiptDetail('Order', receipt.orderNumber),
              _receiptDetail('Customer', receipt.customerName),
              _receiptDetail(
                'Date',
                DateFormat('dd MMM yyyy, HH:mm').format(receipt.date),
              ),
              const Divider(height: 24),

              ...receipt.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(formatCurrency(item.total)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${item.quantity} × ${formatCurrency(item.price)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF858B98),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 24),
              _receiptSummary('Subtotal ', receipt.subtotal),
              if (receipt.discount > 0)
                _receiptSummary(
                  'Discount',
                  -receipt.discount,
                  color: const Color(0xFF16A34A),
                ),
              const Divider(height: 24),
              _receiptSummary('Total ', receipt.total, bold: true),
              const SizedBox(height: 16),
              _receiptDetail('Payment', receipt.paymentMethod),
              const SizedBox(height: 20),
              const Divider(),
              const Text(
                'Thank you & see you again!',
                style: TextStyle(fontSize: 12, color: Color(0xFF858B98)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _receiptDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 75,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF858B98), fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptSummary(
    String label,
    int value, {
    bool bold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              fontSize: bold ? 15 : 13,
            ),
          ),
          Text(
            formatCurrency(value.abs()),
            style: TextStyle(
              fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
              fontSize: bold ? 20 : 13,
              color: color ?? (value < 0 ? const Color(0xFF16A34A) : null),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrinterPanel() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Printer device',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Choose where to print your receipt.',
            style: TextStyle(fontSize: 12, color: Color(0xFF858B98)),
          ),
          const SizedBox(height: 20),

          if (isLoadingPrinters)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (printers.isEmpty)
            _noPrintersFound()
          else
            _printerDropdown(),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isLoadingPrinters ? null : _loadPrinters,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh devices'),
            ),
          ),

          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            _errorBox(),
          ],

          const Spacer(),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: selectedPrinter == null || isPrinting
                  ? null
                  : _printReceipt,
              icon: const Icon(Icons.print_rounded),
              label: const Text('Print Receipt'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primaryColor.withValues(
                  alpha: 0.3,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: isPrinting ? null : widget.onFinished,
              child: const Text(
                'Skip receipt',
                style: TextStyle(color: Color(0xFF858B98)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _printerDropdown() {
    return DropdownButtonFormField<Printer>(
      initialValue: selectedPrinter,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Select printer',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: printers.map((printer) {
        return DropdownMenuItem<Printer>(
          value: printer,
          child: Text(printer.name, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (printer) {
        setState(() {
          selectedPrinter = printer;
          errorMessage = null;
        });
      },
    );
  }

  Widget _noPrintersFound() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(Icons.print_disabled_rounded, color: Color(0xFFEA580C)),
          SizedBox(height: 8),
          Text(
            'No printers detected',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 4),
          Text(
            'Connect a printer to enable printing.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF858B98)),
          ),
        ],
      ),
    );
  }

  Widget _errorBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorMessage!,
              style: const TextStyle(fontSize: 12, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrintingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.white.withValues(alpha: 0.96),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(
                  isPrinted ? Icons.check_rounded : Icons.print_rounded,
                  size: 44,
                  color: isPrinted
                      ? const Color(0xFF16A34A)
                      : AppColors.primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isPrinted ? 'Receipt printed!' : 'Printing receipt...',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isPrinted
                    ? 'Returning to menu...'
                    : 'Please wait while your receipt is being printed.',
                style: const TextStyle(color: Color(0xFF858B98)),
              ),
              if (!isPrinted) ...[
                const SizedBox(height: 24),
                const SizedBox(width: 220, child: LinearProgressIndicator()),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
