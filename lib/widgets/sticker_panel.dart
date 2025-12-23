import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/sticker_service.dart';

class StickerPanel extends StatefulWidget {
  final Function(String stickerUrl) onStickerSelected;
  final VoidCallback onClose;

  const StickerPanel({
    super.key,
    required this.onStickerSelected,
    required this.onClose,
  });

  @override
  State<StickerPanel> createState() => _StickerPanelState();
}

class _StickerPanelState extends State<StickerPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  StickerCategory _selectedCategory = StickerCategory.trending;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: StickerCategory.values.length,
      vsync: this,
    );
    _tabController.addListener(() {
      setState(() {
        _selectedCategory = StickerCategory.values[_tabController.index];
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stickers = StickerService.getStickers(_selectedCategory);

    return Container(
      height: 350,
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
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Stickers',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose,
                  color: AppTheme.textColor,
                ),
              ],
            ),
          ),

          // Category Tabs
          Container(
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppTheme.accent,
              labelColor: AppTheme.accent,
              unselectedLabelColor: AppTheme.textColor.withOpacity(0.6),
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              tabs: StickerCategory.values.map((category) {
                return Tab(
                  text: category.displayName,
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Stickers Grid
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: StickerCategory.values.map((category) {
                final categoryStickers = StickerService.getStickers(category);
                return _buildStickerGrid(categoryStickers);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickerGrid(List<String> stickers) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: stickers.length,
      itemBuilder: (context, index) {
        final sticker = stickers[index];
        return GestureDetector(
          onTap: () => widget.onStickerSelected(sticker),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: _buildStickerContent(sticker),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStickerContent(String sticker) {
    // Check if it's a URL (for future image stickers)
    if (sticker.startsWith('http')) {
      return Image.network(
        sticker,
        width: 40,
        height: 40,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.error, size: 32, color: AppTheme.errorColor);
        },
      );
    }

    // Display as emoji
    return Text(
      sticker,
      style: const TextStyle(fontSize: 32),
    );
  }
}