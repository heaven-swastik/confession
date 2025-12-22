class MessageModel {
  final String messageId;
  final String roomId;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final MessageType type;
  final String? reactionEmoji;
  final String? stickerUrl;

  MessageModel({
    required this.messageId,
    required this.roomId,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.type = MessageType.text,
    this.reactionEmoji,
    this.stickerUrl,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String messageId) {
    return MessageModel(
      messageId: messageId,
      roomId: map['roomId'] ?? '',
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      timestamp: map['timestamp']?.toDate() ?? DateTime.now(),
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${map['type']}',
        orElse: () => MessageType.text,
      ),
      reactionEmoji: map['reactionEmoji'],
      stickerUrl: map['stickerUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp,
      'type': type.toString().split('.').last,
      'reactionEmoji': reactionEmoji,
      'stickerUrl': stickerUrl,
    };
  }

  MessageModel copyWith({
    String? messageId,
    String? roomId,
    String? senderId,
    String? text,
    DateTime? timestamp,
    MessageType? type,
    String? reactionEmoji,
    String? stickerUrl,
  }) {
    return MessageModel(
      messageId: messageId ?? this.messageId,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      reactionEmoji: reactionEmoji ?? this.reactionEmoji,
      stickerUrl: stickerUrl ?? this.stickerUrl,
    );
  }
}

enum MessageType {
  text,
  sticker,
  icebreaker,
}
