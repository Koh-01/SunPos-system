import '../db/app_database.dart';
import '../models/menu_item.dart';

class MenuRepository {
  Future<List<MenuItem>> getAll() async {
    final db = await AppDatabase.instance;
    final rows = await db.query('menu_items', orderBy: 'category, name');
    return rows.map(MenuItem.fromMap).toList();
  }

  Future<List<String>> getCategories() async {
    final items = await getAll();
    return items.map((i) => i.category).toSet().toList()..sort();
  }

  Future<int> create(MenuItem item) async {
    final db = await AppDatabase.instance;
    return db.insert('menu_items', item.toMap());
  }

  Future<void> update(MenuItem item) async {
    final db = await AppDatabase.instance;
    await db.update('menu_items', item.toMap(),
        where: 'id = ?', whereArgs: [item.id]);
  }

  Future<void> delete(int id) async {
    final db = await AppDatabase.instance;
    await db.delete('menu_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setAvailability(int id, bool isAvailable) async {
    final db = await AppDatabase.instance;
    await db.update('menu_items', {'is_available': isAvailable ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }
}
