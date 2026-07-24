import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/order.dart';
import '../../shared/utils/currency_formatter.dart';

class PrinterService {
  PrinterService._();
  static final PrinterService instance = PrinterService._();

  final BlueThermalPrinter _printer = BlueThermalPrinter.instance;

  static const _keyLastDeviceName = 'printer_last_device_name';

  Future<List<BluetoothDevice>> getBondedDevices() async {
    try {
      return await _printer.getBondedDevices();
    } catch (_) {
      return [];
    }
  }

  Future<bool> get isConnected async {
    try {
      return await _printer.isConnected ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> connect(BluetoothDevice device) async {
    await _printer.connect(device);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastDeviceName, device.name ?? 'Unknown printer');
  }

  Future<void> disconnect() async {
    try {
      await _printer.disconnect();
    } catch (_) {
      // already disconnected
    }
  }

  Future<String?> get lastDeviceName async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastDeviceName);
  }

  Future<void> printTest() async {
    if (!await isConnected) throw StateError('Printer not connected');
    _printer.printCustom('Printer Test', 2, 1);
    _printer.printNewLine();
    _printer.printCustom('Connection OK', 1, 1);
    _printer.printNewLine();
    _printer.printNewLine();
    _printer.paperCut();
  }

  Future<void> printReceipt(Order order) async {
    if (!await isConnected) throw StateError('Printer not connected');

    _printer.printCustom('SunPos', 2, 1);
    _printer.printNewLine();
    _printer.printLeftRight(
        'Order #${order.id}', _formatDate(order.createdAt), 1);
    _printer.printCustom('--------------------------------', 0, 1);
    for (final item in order.items) {
      _printer.printLeftRight(
        '${item.name} x${item.quantity}',
        formatRM(item.subtotal),
        1,
      );
    }
    _printer.printCustom('--------------------------------', 0, 1);
    _printer.printLeftRight('Subtotal', formatRM(order.subtotal), 1);
    _printer.printLeftRight('SST', formatRM(order.tax), 1);
    _printer.printLeftRight('TOTAL', formatRM(order.total), 2);
    if (order.cashPaid != null) {
      _printer.printLeftRight('Cash', formatRM(order.cashPaid!), 1);
      _printer.printLeftRight('Change', formatRM(order.change ?? 0), 1);
    }
    _printer.printNewLine();
    _printer.printCustom('Thank you!', 1, 1);
    _printer.printNewLine();
    _printer.printNewLine();
    _printer.paperCut();
  }

  static String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
