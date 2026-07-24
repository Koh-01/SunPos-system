import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/order.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/currency_formatter.dart';
import '../payment/payment_screen.dart' show orderRepositoryProvider;
import '../printer/printer_service.dart';

final orderByIdProvider =
    FutureProvider.family<Order?, int>((ref, id) async {
  return ref.read(orderRepositoryProvider).getById(id);
});

class ReceiptScreen extends ConsumerWidget {
  final int orderId;
  const ReceiptScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderByIdProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt'),
        automaticallyImplyLeading: false,
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (order) {
          if (order == null) {
            return const Center(child: Text('Order not found'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppTheme.success, size: 60),
                    const SizedBox(height: 12),
                    const Text('Payment Successful',
                        style:
                            TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text('SunPos',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 16),
                          const Divider(),
                          _Row('Order #', '${order.id}'),
                          _Row('Date', _formatDate(order.createdAt)),
                          _Row('Method', _methodLabel(order.paymentMethod)),
                          const Divider(),
                          ...order.items.map((item) => _Row(
                                '${item.name} x${item.quantity}',
                                formatRM(item.subtotal),
                              )),
                          const Divider(),
                          _Row('Subtotal', formatRM(order.subtotal)),
                          _Row('SST', formatRM(order.tax)),
                          const Divider(),
                          _Row('Grand Total', formatRM(order.total),
                              bold: true, fontSize: 18),
                          if (order.cashPaid != null) ...[
                            const SizedBox(height: 4),
                            _Row('Cash Received', formatRM(order.cashPaid!)),
                            _Row('Change', formatRM(order.change ?? 0)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _PrintReceiptButton(order: order),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () => context.go('/menu'),
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14)),
            child: const Text('New Order', style: TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }

  static String _methodLabel(PaymentMethod method) => switch (method) {
        PaymentMethod.cash => 'Cash',
        PaymentMethod.card => 'Card',
        PaymentMethod.eWallet => 'e-Wallet',
      };

  static String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final double fontSize;

  const _Row(this.label, this.value, {this.bold = false, this.fontSize = 13});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                      fontSize: fontSize)),
            ),
            Text(value,
                style: TextStyle(
                    fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                    fontSize: fontSize)),
          ],
        ),
      );
}

class _PrintReceiptButton extends StatefulWidget {
  final Order order;
  const _PrintReceiptButton({required this.order});

  @override
  State<_PrintReceiptButton> createState() => _PrintReceiptButtonState();
}

class _PrintReceiptButtonState extends State<_PrintReceiptButton> {
  bool _printing = false;

  Future<void> _print() async {
    setState(() => _printing = true);
    try {
      await PrinterService.instance.printReceipt(widget.order);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Receipt sent to printer')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not print: $e'),
          action: SnackBarAction(
            label: 'Printer Settings',
            onPressed: () => context.push('/printer-settings'),
          ),
        ));
      }
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: _printing ? null : _print,
        icon: _printing
            ? const SizedBox(
                width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.print_outlined),
        label: Text(_printing ? 'Printing...' : 'Print Receipt'),
      );
}
