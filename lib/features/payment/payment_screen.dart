import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/tax.dart';
import '../../core/models/order.dart' as model;
import '../../core/repositories/order_repository.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/currency_formatter.dart';
import '../cart/cart_provider.dart';
import '../history/order_history_provider.dart';

final orderRepositoryProvider = Provider((ref) => OrderRepository());

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  model.PaymentMethod _method = model.PaymentMethod.cash;
  final _cashCtrl = TextEditingController();
  String? _cashError;
  bool _submitting = false;

  @override
  void dispose() {
    _cashCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm(double subtotal, double tax, double total) async {
    double? cashPaid;
    double? change;

    if (_method == model.PaymentMethod.cash) {
      final entered = double.tryParse(_cashCtrl.text.trim());
      if (entered == null) {
        setState(() => _cashError = 'Enter the cash amount received');
        return;
      }
      if (entered < total) {
        setState(() => _cashError = 'Cash received is less than the total due');
        return;
      }
      cashPaid = entered;
      change = entered - total;
    }
    setState(() {
      _cashError = null;
      _submitting = true;
    });

    final cartItems = ref.read(cartProvider);
    final order = model.Order(
      createdAt: DateTime.now(),
      subtotal: subtotal,
      tax: tax,
      total: total,
      paymentMethod: _method,
      cashPaid: cashPaid,
      change: change,
    );
    final orderId =
        await ref.read(orderRepositoryProvider).create(order, cartItems);
    ref.read(cartProvider.notifier).clear();
    await ref.read(orderHistoryProvider.notifier).load();

    if (mounted) {
      context.go('/receipt/$orderId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = ref.watch(cartSubtotalProvider);
    final tax = subtotal * sstRate;
    final total = subtotal + tax;
    final change = _method == model.PaymentMethod.cash
        ? (double.tryParse(_cashCtrl.text.trim()) ?? 0) - total
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _Row('Subtotal', formatRM(subtotal)),
                    _Row('SST (6%)', formatRM(tax)),
                    const Divider(),
                    _Row('Grand Total', formatRM(total),
                        bold: true, fontSize: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Payment Method',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      children: [
                        _MethodChip(
                          label: 'Cash',
                          icon: Icons.payments_outlined,
                          selected: _method == model.PaymentMethod.cash,
                          onTap: () =>
                              setState(() => _method = model.PaymentMethod.cash),
                        ),
                        _MethodChip(
                          label: 'Card',
                          icon: Icons.credit_card,
                          selected: _method == model.PaymentMethod.card,
                          onTap: () =>
                              setState(() => _method = model.PaymentMethod.card),
                        ),
                        _MethodChip(
                          label: 'e-Wallet',
                          icon: Icons.qr_code,
                          selected: _method == model.PaymentMethod.eWallet,
                          onTap: () => setState(
                              () => _method = model.PaymentMethod.eWallet),
                        ),
                      ],
                    ),
                    if (_method == model.PaymentMethod.cash) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _cashCtrl,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Cash Received (RM)',
                          prefixText: 'RM ',
                          errorText: _cashError,
                        ),
                        onChanged: (_) => setState(() => _cashError = null),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: (change ?? -1) >= 0
                              ? AppTheme.success.withValues(alpha: 0.12)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Change',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                            Text(
                              change == null || _cashCtrl.text.trim().isEmpty
                                  ? '—'
                                  : formatRM(change < 0 ? 0 : change),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitting
                  ? null
                  : () => _confirm(subtotal, tax, total),
              style: AppTheme.accentButtonStyle.copyWith(
                padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(vertical: 16)),
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text('Confirm & Save — ${formatRM(total)}',
                      style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final double fontSize;

  const _Row(this.label, this.value, {this.bold = false, this.fontSize = 14});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                    fontSize: fontSize)),
            Text(value,
                style: TextStyle(
                    fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                    fontSize: fontSize)),
          ],
        ),
      );
}

class _MethodChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _MethodChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppTheme.primary : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
            color: selected ? AppTheme.primary.withValues(alpha: 0.1) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 20,
                  color: selected ? AppTheme.primary : Colors.grey),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: selected ? AppTheme.primary : null,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        ),
      );
}
