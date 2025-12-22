import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StickerPanel extends StatelessWidget {
  final Function(String stickerUrl) onStickerSelected;
  final VoidCallback onClose;

  const StickerPanel({
    super.key,
    required this.onStickerSelected,
    required this.onClose,
  });

  static const List<String> stickers = [
    '💜', '💕', '💖', '💗', '💓', '💞', '💝', '💘',
    '🌸', '🌺', '🌻', '🌷', '🌹', '🏵️', '💐', '🌼',
    '✨', '⭐', '🌟', '💫', '🌙', '☀️', '🌈', '☁️',
    '🎉', '🎊', '🎈', '🎁', '🎀', '🎂', '🧁', '🍰',
    '🦋', '🐝', '🐞', '🦄', '🐰', '🐻', '🐼', '🐨',
    '🎨', '🎭', '🎪', '🎬', '🎤', '🎧', '🎼', '🎹',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      decoration: const BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Stickers',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                  color: AppTheme.textColor,
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: stickers.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => onStickerSelected(stickers[index]),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        stickers[index],
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
