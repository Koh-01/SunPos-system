import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/order.dart';
import '../payment/payment_screen.dart' show orderRepositoryProvider;

class OrderHistoryNotifier extends StateNotifier<AsyncValue<List<Order>>> {
  OrderHistoryNotifier(this._ref) : super(const AsyncValue.loading()) {
    load();
  }

  final Ref _ref;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _ref.read(orderRepositoryProvider).getAll());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> voidOrder(int id) async {
    await _ref.read(orderRepositoryProvider).voidOrder(id);
    await load();
  }
}

final orderHistoryProvider =
    StateNotifierProvider<OrderHistoryNotifier, AsyncValue<List<Order>>>(
        (ref) => OrderHistoryNotifier(ref));
