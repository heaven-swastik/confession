class MessageModel {
  final String messageId;
  final String roomId;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final MessageType type;
  final String? reactionEmoji;
  final String? stickerUrl;
  final String? voiceNoteUrl;
  final int? voiceNoteDuration; // in seconds
  final String? spotifyTrackUri;
  final String? spotifyTrackName;
  final String? spotifyArtistName;

  MessageModel({
    required this.messageId,
    required this.roomId,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.type = MessageType.text,
    this.reactionEmoji,
    this.stickerUrl,
    this.voiceNoteUrl,
    this.voiceNoteDuration,
    this.spotifyTrackUri,
    this.spotifyTrackName,
    this.spotifyArtistName,
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
      voiceNoteUrl: map['voiceNoteUrl'],
      voiceNoteDuration: map['voiceNoteDuration'],
      spotifyTrackUri: map['spotifyTrackUri'],
      spotifyTrackName: map['spotifyTrackName'],
      spotifyArtistName: map['spotifyArtistName'],
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
      'voiceNoteUrl': voiceNoteUrl,
      'voiceNoteDuration': voiceNoteDuration,
      'spotifyTrackUri': spotifyTrackUri,
      'spotifyTrackName': spotifyTrackName,
      'spotifyArtistName': spotifyArtistName,
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
    String? voiceNoteUrl,
    int? voiceNoteDuration,
    String? spotifyTrackUri,
    String? spotifyTrackName,
    String? spotifyArtistName,
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
      voiceNoteUrl: voiceNoteUrl ?? this.voiceNoteUrl,
      voiceNoteDuration: voiceNoteDuration ?? this.voiceNoteDuration,
      spotifyTrackUri: spotifyTrackUri ?? this.spotifyTrackUri,
      spotifyTrackName: spotifyTrackName ?? this.spotifyTrackName,
      spotifyArtistName: spotifyArtistName ?? this.spotifyArtistName,
    );
  }
}

enum MessageType {
  text,
  sticker,
  icebreaker,
  voiceNote,
  spotifyTrack,
}