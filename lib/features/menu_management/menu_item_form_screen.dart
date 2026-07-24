import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/media/menu_item_image_store.dart';
import '../../core/models/menu_item.dart';
import '../menu/menu_provider.dart';

class MenuItemFormScreen extends ConsumerStatefulWidget {
  final MenuItem? item;
  const MenuItemFormScreen({super.key, this.item});

  @override
  ConsumerState<MenuItemFormScreen> createState() => _MenuItemFormScreenState();
}

class _MenuItemFormScreenState extends ConsumerState<MenuItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl =
      TextEditingController(text: widget.item?.name ?? '');
  late final _categoryCtrl =
      TextEditingController(text: widget.item?.category ?? '');
  late final _priceCtrl =
      TextEditingController(text: widget.item?.price.toStringAsFixed(2) ?? '');
  late final _descCtrl =
      TextEditingController(text: widget.item?.description ?? '');
  late bool _isAvailable = widget.item?.isAvailable ?? true;
  late String? _imagePath = widget.item?.imagePath;
  bool _saving = false;
  bool _pickingImage = false;

  bool get _isEditing => widget.item != null;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _pickingImage = true);
    try {
      final path = await MenuItemImageStore.pick(source);
      if (path != null && mounted) {
        setState(() => _imagePath = path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not get photo: $e')));
      }
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  void _removeImage() {
    setState(() => _imagePath = null);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final item = MenuItem(
      id: widget.item?.id,
      name: _nameCtrl.text.trim(),
      category: _categoryCtrl.text.trim(),
      price: double.parse(_priceCtrl.text.trim()),
      description:
          _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      isAvailable: _isAvailable,
      imagePath: _imagePath,
    );

    if (_isEditing) {
      await ref.read(menuProvider.notifier).updateItem(item);
    } else {
      await ref.read(menuProvider.notifier).addItem(item);
    }

    // Clean up the old photo file if it was replaced or removed.
    final oldPath = widget.item?.imagePath;
    if (oldPath != null && oldPath != _imagePath) {
      await MenuItemImageStore.deleteIfExists(oldPath);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Menu Item' : 'Add Menu Item')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(child: _buildPhotoPicker()),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _categoryCtrl,
              decoration: const InputDecoration(
                  labelText: 'Category', hintText: 'e.g. Mains, Drinks, Sides'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Category is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Price (RM)'),
              validator: (v) {
                final price = double.tryParse(v?.trim() ?? '');
                if (price == null) return 'Enter a valid price';
                if (price <= 0) return 'Price must be greater than 0';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              decoration:
                  const InputDecoration(labelText: 'Description (optional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Available for sale'),
              value: _isAvailable,
              onChanged: (v) => setState(() => _isAvailable = v),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(_isEditing ? 'Save Changes' : 'Add Item'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPicker() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 120,
            height: 120,
            color: Colors.grey.shade200,
            child: _pickingImage
                ? const Center(child: CircularProgressIndicator())
                : _imagePath == null
                    ? Icon(Icons.fastfood, size: 40, color: Colors.grey.shade500)
                    : Image.file(File(_imagePath!), fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: _pickingImage ? null : () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.photo_camera_outlined, size: 18),
              label: const Text('Camera'),
            ),
            TextButton.icon(
              onPressed: _pickingImage ? null : () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: const Text('Gallery'),
            ),
            if (_imagePath != null)
              TextButton.icon(
                onPressed: _pickingImage ? null : _removeImage,
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                label: const Text('Remove', style: TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ],
    );
  }
}
