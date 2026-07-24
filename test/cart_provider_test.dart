import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/core/models/menu_item.dart';
import 'package:pos_app/features/cart/cart_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() => container.dispose());

  const burger = MenuItem(id: 1, name: 'Burger', category: 'Mains', price: 10);
  const fries = MenuItem(id: 2, name: 'Fries', category: 'Sides', price: 4);

  test('adding a new item puts it in the cart with quantity 1', () {
    container.read(cartProvider.notifier).addItem(burger);

    final cart = container.read(cartProvider);
    expect(cart.length, 1);
    expect(cart.first.menuItemId, 1);
    expect(cart.first.quantity, 1);
  });

  test('adding the same item twice increments quantity instead of duplicating', () {
    final notifier = container.read(cartProvider.notifier);
    notifier.addItem(burger);
    notifier.addItem(burger);

    final cart = container.read(cartProvider);
    expect(cart.length, 1);
    expect(cart.first.quantity, 2);
  });

  test('decrementing to zero removes the item', () {
    final notifier = container.read(cartProvider.notifier);
    notifier.addItem(burger);
    notifier.decrementQuantity(burger.id!);

    expect(container.read(cartProvider), isEmpty);
  });

  test('removeItem drops only the targeted item', () {
    final notifier = container.read(cartProvider.notifier);
    notifier.addItem(burger);
    notifier.addItem(fries);
    notifier.removeItem(burger.id!);

    final cart = container.read(cartProvider);
    expect(cart.length, 1);
    expect(cart.first.menuItemId, fries.id);
  });

  test('clear empties the cart', () {
    final notifier = container.read(cartProvider.notifier);
    notifier.addItem(burger);
    notifier.addItem(fries);
    notifier.clear();

    expect(container.read(cartProvider), isEmpty);
  });

  test('cartSubtotalProvider sums price * quantity across items', () {
    final notifier = container.read(cartProvider.notifier);
    notifier.addItem(burger); // 10
    notifier.addItem(burger); // 10 -> qty 2 = 20
    notifier.addItem(fries); // 4

    expect(container.read(cartSubtotalProvider), 24.0);
  });

  test('cartItemCountProvider sums quantities, not distinct items', () {
    final notifier = container.read(cartProvider.notifier);
    notifier.addItem(burger);
    notifier.addItem(burger);
    notifier.addItem(fries);

    expect(container.read(cartItemCountProvider), 3);
  });
}
