import 'order_item.dart';

enum PaymentMethod { cash, card, eWallet }

enum OrderStatus { completed, voided }

class Order {
  final int? id;
  final DateTime createdAt;
  final double subtotal;
  final double tax;
  final double total;
  final PaymentMethod paymentMethod;
  final double? cashPaid;
  final double? change;
  final OrderStatus status;
  final List<OrderItem> items;

  const Order({
    this.id,
    required this.createdAt,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.paymentMethod,
    this.cashPaid,
    this.change,
    this.status = OrderStatus.completed,
    this.items = const [],
  });

  Order copyWith({OrderStatus? status, List<OrderItem>? items}) => Order(
        id: id,
        createdAt: createdAt,
        subtotal: subtotal,
        tax: tax,
        total: total,
        paymentMethod: paymentMethod,
        cashPaid: cashPaid,
        change: change,
        status: status ?? this.status,
        items: items ?? this.items,
      );

  factory Order.fromMap(Map<String, dynamic> map) => Order(
        id: map['id'] as int?,
        createdAt: DateTime.parse(map['created_at'] as String),
        subtotal: (map['subtotal'] as num).toDouble(),
        tax: (map['tax'] as num).toDouble(),
        total: (map['total'] as num).toDouble(),
        paymentMethod: PaymentMethod.values.byName(map['payment_method'] as String),
        cashPaid: (map['cash_paid'] as num?)?.toDouble(),
        change: (map['change_due'] as num?)?.toDouble(),
        status: OrderStatus.values.byName(map['status'] as String),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'created_at': createdAt.toIso8601String(),
        'subtotal': subtotal,
        'tax': tax,
        'total': total,
        'payment_method': paymentMethod.name,
        'cash_paid': cashPaid,
        'change_due': change,
        'status': status.name,
      };
}
