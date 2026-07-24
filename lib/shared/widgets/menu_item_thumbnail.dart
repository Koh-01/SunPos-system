import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MenuItemThumbnail extends StatelessWidget {
  final String? imagePath;
  final double size;

  const MenuItemThumbnail({super.key, required this.imagePath, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: size,
        height: size,
        color: AppTheme.primary.withValues(alpha: 0.1),
        child: imagePath == null
            ? Icon(Icons.fastfood, color: AppTheme.primary, size: size * 0.5)
            : Image.file(
                File(imagePath!),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(Icons.fastfood,
                    color: AppTheme.primary, size: size * 0.5),
              ),
      ),
    );
  }
}
