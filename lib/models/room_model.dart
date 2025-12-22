class RoomModel {
  final String roomId;
  final String secretWordHash;
  final List<String> participants;
  final DateTime createdAt;
  final bool disappearingMessages;
  final String? lastMessage;
  final DateTime? lastMessageTime;

  RoomModel({
    required this.roomId,
    required this.secretWordHash,
    required this.participants,
    required this.createdAt,
    this.disappearingMessages = false,
    this.lastMessage,
    this.lastMessageTime,
  });

  factory RoomModel.fromMap(Map<String, dynamic> map, String roomId) {
    return RoomModel(
      roomId: roomId,
      secretWordHash: map['secretWordHash'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      disappearingMessages: map['disappearingMessages'] ?? false,
      lastMessage: map['lastMessage'],
      lastMessageTime: map['lastMessageTime']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'secretWordHash': secretWordHash,
      'participants': participants,
      'createdAt': createdAt,
      'disappearingMessages': disappearingMessages,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
    };
  }

  RoomModel copyWith({
    String? roomId,
    String? secretWordHash,
    List<String>? participants,
    DateTime? createdAt,
    bool? disappearingMessages,
    String? lastMessage,
    DateTime? lastMessageTime,
  }) {
    return RoomModel(
      roomId: roomId ?? this.roomId,
      secretWordHash: secretWordHash ?? this.secretWordHash,
      participants: participants ?? this.participants,
      createdAt: createdAt ?? this.createdAt,
      disappearingMessages: disappearingMessages ?? this.disappearingMessages,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
    );
  }
}
