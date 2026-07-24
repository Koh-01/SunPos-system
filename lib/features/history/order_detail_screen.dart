import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/order.dart';
import '../../shared/utils/currency_formatter.dart';
import '../receipt/receipt_screen.dart' show orderByIdProvider;
import 'order_history_provider.dart';

class OrderDetailScreen extends ConsumerWidget {
  final int orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  Future<void> _confirmVoid(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Void this order?'),
        content: const Text(
            'This marks the order as voided. It stays in history for records but is no longer counted as a valid sale.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Void Order')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(orderHistoryProvider.notifier).voidOrder(orderId);
      ref.invalidate(orderByIdProvider(orderId));
      if (context.mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderByIdProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: Text('Order #$orderId')),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (order) {
          if (order == null) {
            return const Center(child: Text('Order not found'));
          }
          final voided = order.status == OrderStatus.voided;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (voided)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.block, color: Colors.red),
                      SizedBox(width: 8),
                      Text('This order has been voided',
                          style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Placed on ${_formatDate(order.createdAt)}',
                          style: TextStyle(color: Colors.grey.shade600)),
                      const Divider(height: 24),
                      ...order.items.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                    child: Text('${item.name} x${item.quantity}')),
                                Text(formatRM(item.subtotal)),
                              ],
                            ),
                          )),
                      const Divider(height: 24),
                      _Row('Subtotal', formatRM(order.subtotal)),
                      _Row('SST', formatRM(order.tax)),
                      _Row('Grand Total', formatRM(order.total), bold: true),
                      const SizedBox(height: 8),
                      _Row('Payment Method', _methodLabel(order.paymentMethod)),
                      if (order.cashPaid != null) ...[
                        _Row('Cash Received', formatRM(order.cashPaid!)),
                        _Row('Change', formatRM(order.change ?? 0)),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (!voided)
                OutlinedButton.icon(
                  onPressed: () => _confirmVoid(context, ref),
                  icon: const Icon(Icons.block, color: Colors.red),
                  label: const Text('Void Order',
                      style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
            ],
          );
        },
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

  const _Row(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                    fontSize: bold ? 17 : 14)),
            Text(value,
                style: TextStyle(
                    fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                    fontSize: bold ? 17 : 14)),
          ],
        ),
      );
}
