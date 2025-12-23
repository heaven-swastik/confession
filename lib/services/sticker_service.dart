class StickerService {
  // Sticker packs with categories
  static final Map<StickerCategory, List<String>> stickerPacks = {
    StickerCategory.trending: [
      'https://media.tenor.com/images/trending1.gif',
      'https://media.tenor.com/images/trending2.gif',
      // Add actual trending sticker URLs
      '🔥', '💯', '✨', '👑', '💎', '🌟', '⭐', '💫',
      '🎉', '🎊', '🎈', '🎁', '🏆', '🥇', '🎯', '💪',
    ],
    
    StickerCategory.cute: [
      '🥰', '😍', '🤗', '😊', '☺️', '😌', '💕', '💖',
      '💗', '💓', '💞', '💝', '🌸', '🌺', '🌻', '🌷',
      '🌹', '🦋', '🐰', '🐻', '🐼', '🐨', '🦄', '🐱',
      '🐶', '🐹', '🐥', '🐣', '🦊', '🦁', '🐙', '🐠',
    ],
    
    StickerCategory.funny: [
      '😂', '🤣', '😆', '😅', '😹', '😸', '🤪', '🤡',
      '🤠', '🥳', '😜', '😝', '🤤', '🤓', '😎', '🥴',
      '🤯', '🥵', '🥶', '😱', '🤐', '🤫', '🙃', '😬',
      '💀', '👻', '🤖', '👽', '🙈', '🙉', '🙊', '💩',
    ],
    
    StickerCategory.romantic: [
      '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍',
      '💔', '❣️', '💕', '💞', '💓', '💗', '💖', '💘',
      '💝', '💟', '😍', '🥰', '😘', '😗', '😙', '😚',
      '💋', '💑', '💏', '👫', '💐', '🌹', '🌺', '🎀',
    ],
    
    StickerCategory.party: [
      '🎉', '🎊', '🎈', '🎁', '🎂', '🍰', '🧁', '🎀',
      '🎪', '🎭', '🎨', '🎬', '🎤', '🎧', '🎼', '🎹',
      '🍾', '🥂', '🍻', '🍺', '🍷', '🍸', '🍹', '🍶',
      '🥳', '🕺', '💃', '🪩', '🎶', '🎵', '🎺', '🎷',
    ],
    
    StickerCategory.savage: [
      '😏', '😤', '😠', '😡', '🤬', '💢', '👿', '😈',
      '💀', '☠️', '👻', '💣', '💥', '🔥', '⚡', '💯',
      '🗿', '🤨', '🧐', '🤐', '😶', '🙄', '😒', '😑',
      '💅', '💁', '🤷', '🙅', '🙆', '💪', '👊', '✊',
    ],
    
    StickerCategory.flirty: [
      '😘', '😗', '😙', '😚', '😍', '🥰', '😏', '😉',
      '💋', '👄', '💕', '💓', '💗', '💖', '💘', '💝',
      '🌹', '💐', '🍷', '🥂', '🎀', '💄', '👗', '👠',
      '🔥', '💯', '✨', '💫', '⭐', '🌟', '💎', '👑',
    ],
    
    StickerCategory.emotions: [
      '😊', '😌', '😍', '🥰', '😘', '😗', '😙', '😚',
      '😋', '😛', '😝', '😜', '🤪', '🤨', '🧐', '🤓',
      '😎', '🥸', '🤩', '🥳', '😏', '😒', '😞', '😔',
      '😟', '😕', '🙁', '☹️', '😣', '😖', '😫', '😩',
      '🥺', '😢', '😭', '😤', '😠', '😡', '🤬', '🤯',
      '😳', '🥵', '🥶', '😱', '😨', '😰', '😥', '😓',
    ],
    
    StickerCategory.dark: [
      '💀', '☠️', '👻', '👽', '👾', '🤖', '🎃', '😈',
      '👿', '👹', '👺', '🤡', '💩', '👁️', '🗿', '🔮',
      '🕷️', '🕸️', '🦇', '🐍', '🦂', '🔪', '💣', '💥',
      '🔥', '⚡', '💢', '☢️', '☣️', '⚠️', '🚫', '⛔',
    ],
    
    StickerCategory.adult: [
      '🍑', '🍆', '💦', '🔥', '😈', '👿', '💋', '👄',
      '🌶️', '🥵', '💯', '😏', '🔞', '⚠️', '🚫', '💅',
      // Note: Keep it tasteful and within app store guidelines
    ],
    
    StickerCategory.animals: [
      '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼',
      '🐨', '🐯', '🦁', '🐮', '🐷', '🐸', '🐵', '🐔',
      '🐧', '🐦', '🐤', '🐣', '🐥', '🦆', '🦅', '🦉',
      '🦇', '🐺', '🐗', '🐴', '🦄', '🐝', '🐛', '🦋',
      '🐌', '🐞', '🐜', '🦗', '🕷️', '🐢', '🐍', '🦎',
      '🦖', '🦕', '🐙', '🦑', '🦐', '🦞', '🦀', '🐡',
      '🐠', '🐟', '🐬', '🐳', '🐋', '🦈', '🐊', '🐅',
    ],
    
    StickerCategory.food: [
      '🍕', '🍔', '🍟', '🌭', '🍿', '🧂', '🥓', '🥚',
      '🍳', '🧇', '🥞', '🧈', '🍞', '🥐', '🥨', '🥯',
      '🥖', '🧀', '🥗', '🥙', '🌮', '🌯', '🥪', '🍖',
      '🍗', '🥩', '🍤', '🍱', '🍛', '🍝', '🍜', '🍲',
      '🍥', '🍣', '🍙', '🍘', '🍚', '🍧', '🍨', '🍦',
      '🍰', '🎂', '🧁', '🥧', '🍮', '🍭', '🍬', '🍫',
      '🍩', '🍪', '🌰', '🥜', '🍯', '☕', '🍵', '🧃',
    ],
  };

  static List<String> getStickers(StickerCategory category) {
    return stickerPacks[category] ?? [];
  }

  static List<String> getAllStickers() {
    return stickerPacks.values.expand((list) => list).toList();
  }

  static List<String> getTrendingStickers() {
    return stickerPacks[StickerCategory.trending] ?? [];
  }

  static List<String> searchStickers(String query) {
    query = query.toLowerCase();
    final results = <String>[];

    for (final category in StickerCategory.values) {
      if (category.toString().toLowerCase().contains(query)) {
        results.addAll(stickerPacks[category] ?? []);
      }
    }

    return results.take(50).toList();
  }
}

enum StickerCategory {
  trending,
  cute,
  funny,
  romantic,
  party,
  savage,
  flirty,
  emotions,
  dark,
  adult,
  animals,
  food,
}

extension StickerCategoryExtension on StickerCategory {
  String get displayName {
    switch (this) {
      case StickerCategory.trending:
        return '🔥 Trending';
      case StickerCategory.cute:
        return '🥰 Cute';
      case StickerCategory.funny:
        return '😂 Funny';
      case StickerCategory.romantic:
        return '💕 Romantic';
      case StickerCategory.party:
        return '🎉 Party';
      case StickerCategory.savage:
        return '😏 Savage';
      case StickerCategory.flirty:
        return '😘 Flirty';
      case StickerCategory.emotions:
        return '😊 Emotions';
      case StickerCategory.dark:
        return '💀 Dark';
      case StickerCategory.adult:
        return '🔞 Adult';
      case StickerCategory.animals:
        return '🐶 Animals';
      case StickerCategory.food:
        return '🍕 Food';
    }
  }

  String get description {
    switch (this) {
      case StickerCategory.trending:
        return 'Hot and popular stickers';
      case StickerCategory.cute:
        return 'Adorable and sweet';
      case StickerCategory.funny:
        return 'Make them laugh';
      case StickerCategory.romantic:
        return 'Love and romance';
      case StickerCategory.party:
        return 'Celebration time';
      case StickerCategory.savage:
        return 'Bold and fierce';
      case StickerCategory.flirty:
        return 'Playful and teasing';
      case StickerCategory.emotions:
        return 'Express how you feel';
      case StickerCategory.dark:
        return 'Edgy and mysterious';
      case StickerCategory.adult:
        return 'For mature audiences';
      case StickerCategory.animals:
        return 'Cute creatures';
      case StickerCategory.food:
        return 'Delicious treats';
    }
  }
}