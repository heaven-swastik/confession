import 'package:flutter/material.dart';

class ScreenshotBlocker {
  // Screenshot blocking is implemented at the native Android level
  // using FLAG_SECURE in MainActivity.kt
  // This ensures screenshots, screen recording, and recent apps preview are blocked
  
  static void showScreenshotWarning(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Row(
          children: [
            Icon(Icons.shield, color: Color(0xFFD3C4FF)),
            SizedBox(width: 12),
            Text('Protected Space'),
          ],
        ),
        content: const Text(
          'Screenshots and screen recording are blocked to protect your privacy. Your words stay safe here. 💜',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
