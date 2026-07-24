import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/menu_item.dart';
import '../../core/models/order_item.dart';

class CartNotifier extends StateNotifier<List<OrderItem>> {
  CartNotifier() : super([]);

  void addItem(MenuItem item) {
    final index = state.indexWhere((i) => i.menuItemId == item.id);
    if (index >= 0) {
      final updated = [...state];
      updated[index] =
          updated[index].copyWith(quantity: updated[index].quantity + 1);
      state = updated;
    } else {
      state = [
        ...state,
        OrderItem(
          menuItemId: item.id!,
          name: item.name,
          price: item.price,
          quantity: 1,
        ),
      ];
    }
  }

  void incrementQuantity(int menuItemId) {
    state = [
      for (final i in state)
        if (i.menuItemId == menuItemId) i.copyWith(quantity: i.quantity + 1) else i,
    ];
  }

  void decrementQuantity(int menuItemId) {
    final updated = <OrderItem>[];
    for (final i in state) {
      if (i.menuItemId == menuItemId) {
        if (i.quantity > 1) updated.add(i.copyWith(quantity: i.quantity - 1));
      } else {
        updated.add(i);
      }
    }
    state = updated;
  }

  void removeItem(int menuItemId) {
    state = state.where((i) => i.menuItemId != menuItemId).toList();
  }

  void clear() {
    state = [];
  }
}

final cartProvider =
    StateNotifierProvider<CartNotifier, List<OrderItem>>((ref) => CartNotifier());

final cartSubtotalProvider = Provider<double>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold(0.0, (sum, i) => sum + i.subtotal);
});

final cartItemCountProvider = Provider<int>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold(0, (sum, i) => sum + i.quantity);
});
