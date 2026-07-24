import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/order.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/currency_formatter.dart';
import '../../shared/widgets/empty_state.dart';
import 'order_history_provider.dart';

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(orderHistoryProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(orderHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Order History')),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (orders) {
          if (orders.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              message: 'No past orders yet.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final order = orders[index];
              final voided = order.status == OrderStatus.voided;
              return Card(
                child: ListTile(
                  onTap: () => context.push('/history/${order.id}'),
                  leading: CircleAvatar(
                    backgroundColor: voided
                        ? Colors.red.shade50
                        : AppTheme.primary.withValues(alpha: 0.1),
                    child: Icon(
                      voided ? Icons.block : Icons.receipt,
                      color: voided ? Colors.red : AppTheme.primary,
                    ),
                  ),
                  title: Text('Order #${order.id}'),
                  subtitle: Text(_formatDate(order.createdAt)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatRM(order.total),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration:
                              voided ? TextDecoration.lineThrough : null,
                          color: voided ? Colors.grey : null,
                        ),
                      ),
                      if (voided)
                        Text('VOIDED',
                            style: TextStyle(
                                color: Colors.red.shade400,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
