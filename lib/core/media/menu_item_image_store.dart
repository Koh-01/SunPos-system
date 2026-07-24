import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class MenuItemImageStore {
  static final ImagePicker _picker = ImagePicker();

  static Future<String?> pick(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (picked == null) return null;

    final docsDir = await getApplicationDocumentsDirectory();
    final menuImagesDir = Directory(p.join(docsDir.path, 'menu_images'));
    if (!await menuImagesDir.exists()) {
      await menuImagesDir.create(recursive: true);
    }

    final fileName =
        '${DateTime.now().microsecondsSinceEpoch}${p.extension(picked.path)}';
    final savedPath = p.join(menuImagesDir.path, fileName);
    await File(picked.path).copy(savedPath);
    return savedPath;
  }

  static Future<void> deleteIfExists(String? path) async {
    if (path == null) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
