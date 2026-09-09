import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('ZAFRA', style: TextStyle(fontSize: 34, letterSpacing: 8, color: Colors.white)),
            SizedBox(height: 28),
            SizedBox(width: 150, child: LinearProgressIndicator(color: AppTheme.accent, backgroundColor: Colors.white12)),
          ],
        ),
      ),
    );
  }
}
