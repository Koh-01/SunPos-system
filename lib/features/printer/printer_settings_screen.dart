import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/empty_state.dart';
import 'printer_service.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  List<BluetoothDevice> _devices = [];
  bool _loading = true;
  bool _connected = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final devices = await PrinterService.instance.getBondedDevices();
      final connected = await PrinterService.instance.isConnected;
      if (mounted) {
        setState(() {
          _devices = devices;
          _connected = connected;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Bluetooth not available on this device: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _connect(BluetoothDevice device) async {
    setState(() => _loading = true);
    try {
      await PrinterService.instance.connect(device);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Connected to ${device.name ?? 'printer'}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not connect: $e')));
      }
    } finally {
      await _refresh();
    }
  }

  Future<void> _disconnect() async {
    await PrinterService.instance.disconnect();
    await _refresh();
  }

  Future<void> _testPrint() async {
    try {
      await PrinterService.instance.printTest();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Test receipt sent')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Print failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Printer Settings'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? EmptyState(icon: Icons.bluetooth_disabled, message: _error!)
              : Column(
                  children: [
                    if (_connected)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        color: AppTheme.success.withValues(alpha: 0.1),
                        child: Row(
                          children: [
                            const Icon(Icons.bluetooth_connected,
                                color: AppTheme.success),
                            const SizedBox(width: 8),
                            const Expanded(child: Text('Printer connected')),
                            TextButton(
                                onPressed: _disconnect,
                                child: const Text('Disconnect')),
                          ],
                        ),
                      ),
                    Expanded(
                      child: _devices.isEmpty
                          ? const EmptyState(
                              icon: Icons.bluetooth_searching,
                              message:
                                  'No paired Bluetooth devices found.\nPair your thermal printer in Android Bluetooth settings first.',
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: _devices.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final device = _devices[index];
                                return Card(
                                  child: ListTile(
                                    leading: const Icon(Icons.print_outlined),
                                    title:
                                        Text(device.name ?? 'Unknown device'),
                                    subtitle: Text(device.address ?? ''),
                                    onTap: () => _connect(device),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _connected ? _testPrint : null,
            icon: const Icon(Icons.print),
            label: const Text('Test Print'),
          ),
        ),
      ),
    );
  }
}
