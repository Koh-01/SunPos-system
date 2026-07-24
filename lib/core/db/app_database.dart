import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static Database? _db;

  static Future<Database> get instance async {
    _db ??= await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'pos_app.db'),
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE menu_items ADD COLUMN image_path TEXT');
    }
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE menu_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        price REAL NOT NULL,
        description TEXT,
        is_available INTEGER NOT NULL DEFAULT 1,
        image_path TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        created_at TEXT NOT NULL,
        subtotal REAL NOT NULL,
        tax REAL NOT NULL,
        total REAL NOT NULL,
        payment_method TEXT NOT NULL,
        cash_paid REAL,
        change_due REAL,
        status TEXT NOT NULL DEFAULT 'completed'
      )
    ''');

    await db.execute('''
      CREATE TABLE order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL REFERENCES orders (id),
        menu_item_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL
      )
    ''');

    await _seedMenu(db);
  }

  static Future<void> _seedMenu(Database db) async {
    final seed = [
      {'name': 'Chicken Rice', 'category': 'Mains', 'price': 8.50},
      {'name': 'Nasi Lemak', 'category': 'Mains', 'price': 7.00},
      {'name': 'Fried Noodles', 'category': 'Mains', 'price': 7.50},
      {'name': 'Curry Laksa', 'category': 'Mains', 'price': 9.00},
      {'name': 'Iced Milo', 'category': 'Drinks', 'price': 3.50},
      {'name': 'Teh Tarik', 'category': 'Drinks', 'price': 3.00},
      {'name': 'Mineral Water', 'category': 'Drinks', 'price': 2.00},
      {'name': 'French Fries', 'category': 'Sides', 'price': 4.50},
      {'name': 'Spring Rolls', 'category': 'Sides', 'price': 5.00},
    ];
    for (final item in seed) {
      await db.insert('menu_items', {...item, 'is_available': 1});
    }
  }
}
