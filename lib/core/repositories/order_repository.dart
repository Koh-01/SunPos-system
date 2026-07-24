import 'package:sqflite/sqflite.dart';
import '../db/app_database.dart';
import '../models/order.dart';
import '../models/order_item.dart';

class OrderRepository {
  Future<int> create(Order order, List<OrderItem> items) async {
    final db = await AppDatabase.instance;
    return db.transaction((txn) async {
      final orderId = await txn.insert('orders', order.toMap());
      for (final item in items) {
        await txn.insert('order_items', item.toMap()..['order_id'] = orderId);
      }
      return orderId;
    });
  }

  Future<List<Order>> getAll() async {
    final db = await AppDatabase.instance;
    final rows = await db.query('orders', orderBy: 'created_at DESC');
    final orders = <Order>[];
    for (final row in rows) {
      final order = Order.fromMap(row);
      final items = await _getItems(db, order.id!);
      orders.add(order.copyWith(items: items));
    }
    return orders;
  }

  Future<Order?> getById(int id) async {
    final db = await AppDatabase.instance;
    final rows = await db.query('orders', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final order = Order.fromMap(rows.first);
    final items = await _getItems(db, id);
    return order.copyWith(items: items);
  }

  Future<List<OrderItem>> _getItems(DatabaseExecutor db, int orderId) async {
    final rows =
        await db.query('order_items', where: 'order_id = ?', whereArgs: [orderId]);
    return rows.map<OrderItem>(OrderItem.fromMap).toList();
  }

  Future<void> voidOrder(int id) async {
    final db = await AppDatabase.instance;
    await db.update('orders', {'status': OrderStatus.voided.name},
        where: 'id = ?', whereArgs: [id]);
  }
}
