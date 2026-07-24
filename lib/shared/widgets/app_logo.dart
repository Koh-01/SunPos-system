import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppLogo extends StatelessWidget {
  final double diameter;
  const AppLogo({super.key, this.diameter = 140});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/logo_icon.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 12),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: diameter * 0.2,
              fontWeight: FontWeight.w800,
            ),
            children: const [
              TextSpan(text: 'Sun', style: TextStyle(color: AppTheme.accent)),
              TextSpan(text: 'Pos', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }
}
