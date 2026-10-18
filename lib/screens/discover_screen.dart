import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Découvrir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore_outlined, size: 80, color: AppTheme.textGrey.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              'Bientôt disponible',
              style: TextStyle(color: AppTheme.textGrey, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Explore les tendances, les entreprises et les communautés.',
              style: TextStyle(color: AppTheme.textGrey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}