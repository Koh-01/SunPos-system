class OrderItem {
  final int? id;
  final int? orderId;
  final int menuItemId;
  final String name;
  final double price;
  final int quantity;

  const OrderItem({
    this.id,
    this.orderId,
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
  });

  double get subtotal => price * quantity;

  OrderItem copyWith({int? quantity}) => OrderItem(
        id: id,
        orderId: orderId,
        menuItemId: menuItemId,
        name: name,
        price: price,
        quantity: quantity ?? this.quantity,
      );

  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
        id: map['id'] as int?,
        orderId: map['order_id'] as int?,
        menuItemId: map['menu_item_id'] as int,
        name: map['name'] as String,
        price: (map['price'] as num).toDouble(),
        quantity: map['quantity'] as int,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        if (orderId != null) 'order_id': orderId,
        'menu_item_id': menuItemId,
        'name': name,
        'price': price,
        'quantity': quantity,
      };
}
