import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String messageId;
  final String roomId;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final MessageType type;
  
  // REACTIONS: Map of userId -> emoji
  final Map<String, String> reactions;
  
  // READ RECEIPTS
  final List<String> readBy;
  final List<String> deliveredTo;
  
  final String? stickerUrl;
  final String? voiceNoteUrl;
  final int? voiceNoteDuration;
  final String? spotifyTrackUri;
  final String? spotifyTrackName;
  final String? spotifyArtistName;
  
  // Reply features
  final String? replyToMessageId;
  final String? replyToText;
  final String? replyToSenderId;
  final MessageType? replyToType;

  MessageModel({
    required this.messageId,
    required this.roomId,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.type = MessageType.text,
    this.reactions = const {},
    this.readBy = const [],
    this.deliveredTo = const [],
    this.stickerUrl,
    this.voiceNoteUrl,
    this.voiceNoteDuration,
    this.spotifyTrackUri,
    this.spotifyTrackName,
    this.spotifyArtistName,
    this.replyToMessageId,
    this.replyToText,
    this.replyToSenderId,
    this.replyToType,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String messageId) {
    MessageType? replyType;
    if (map['replyToType'] != null) {
      try {
        replyType = MessageType.values.firstWhere(
          (e) => e.toString() == 'MessageType.${map['replyToType']}',
        );
      } catch (e) {
        replyType = null;
      }
    }

    // Parse reactions map
    Map<String, String> reactions = {};
    if (map['reactions'] != null && map['reactions'] is Map) {
      reactions = Map<String, String>.from(map['reactions']);
    }
    
    // Parse read receipts
    List<String> readBy = [];
    if (map['readBy'] != null && map['readBy'] is List) {
      readBy = List<String>.from(map['readBy']);
    }
    
    List<String> deliveredTo = [];
    if (map['deliveredTo'] != null && map['deliveredTo'] is List) {
      deliveredTo = List<String>.from(map['deliveredTo']);
    }

    return MessageModel(
      messageId: messageId,
      roomId: map['roomId'] ?? '',
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${map['type']}',
        orElse: () => MessageType.text,
      ),
      reactions: reactions,
      readBy: readBy,
      deliveredTo: deliveredTo,
      stickerUrl: map['stickerUrl'],
      voiceNoteUrl: map['voiceNoteUrl'],
      voiceNoteDuration: map['voiceNoteDuration'],
      spotifyTrackUri: map['spotifyTrackUri'],
      spotifyTrackName: map['spotifyTrackName'],
      spotifyArtistName: map['spotifyArtistName'],
      replyToMessageId: map['replyToMessageId'],
      replyToText: map['replyToText'],
      replyToSenderId: map['replyToSenderId'],
      replyToType: replyType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'senderId': senderId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type.toString().split('.').last,
      'reactions': reactions,
      'readBy': readBy,
      'deliveredTo': deliveredTo,
      'stickerUrl': stickerUrl,
      'voiceNoteUrl': voiceNoteUrl,
      'voiceNoteDuration': voiceNoteDuration,
      'spotifyTrackUri': spotifyTrackUri,
      'spotifyTrackName': spotifyTrackName,
      'spotifyArtistName': spotifyArtistName,
      'replyToMessageId': replyToMessageId,
      'replyToText': replyToText,
      'replyToSenderId': replyToSenderId,
      'replyToType': replyToType?.toString().split('.').last,
    };
  }

  MessageModel copyWith({
    String? messageId,
    String? roomId,
    String? senderId,
    String? text,
    DateTime? timestamp,
    MessageType? type,
    Map<String, String>? reactions,
    List<String>? readBy,
    List<String>? deliveredTo,
    String? stickerUrl,
    String? voiceNoteUrl,
    int? voiceNoteDuration,
    String? spotifyTrackUri,
    String? spotifyTrackName,
    String? spotifyArtistName,
    String? replyToMessageId,
    String? replyToText,
    String? replyToSenderId,
    MessageType? replyToType,
  }) {
    return MessageModel(
      messageId: messageId ?? this.messageId,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      reactions: reactions ?? this.reactions,
      readBy: readBy ?? this.readBy,
      deliveredTo: deliveredTo ?? this.deliveredTo,
      stickerUrl: stickerUrl ?? this.stickerUrl,
      voiceNoteUrl: voiceNoteUrl ?? this.voiceNoteUrl,
      voiceNoteDuration: voiceNoteDuration ?? this.voiceNoteDuration,
      spotifyTrackUri: spotifyTrackUri ?? this.spotifyTrackUri,
      spotifyTrackName: spotifyTrackName ?? this.spotifyTrackName,
      spotifyArtistName: spotifyArtistName ?? this.spotifyArtistName,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToText: replyToText ?? this.replyToText,
      replyToSenderId: replyToSenderId ?? this.replyToSenderId,
      replyToType: replyToType ?? this.replyToType,
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