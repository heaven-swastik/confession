class RoomModel {
  final String roomId;
  final String roomName;
  final String secretWordHash;
  final List<String> participants;
  final DateTime createdAt;
  final bool disappearingMessages;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? activeGameId;
  final String? activeGameType;


  RoomModel({
    required this.roomId,
    required this.roomName,
    required this.secretWordHash,
    required this.participants,
    required this.createdAt,
    this.disappearingMessages = false,
    this.lastMessage,
    this.lastMessageTime,
    this.activeGameId,
    this.activeGameType,
  });

  factory RoomModel.fromMap(Map<String, dynamic> map, String roomId) {
    return RoomModel(
      roomId: roomId,
      roomName: map['roomName'] ?? 'Room ${roomId.substring(0, 6).toUpperCase()}',
      secretWordHash: map['secretWordHash'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      disappearingMessages: map['disappearingMessages'] ?? false,
      lastMessage: map['lastMessage'],
      lastMessageTime: map['lastMessageTime']?.toDate(),
      activeGameId: map['activeGameId'],
      activeGameType: map['activeGameType'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomName': roomName,
      'secretWordHash': secretWordHash,
      'participants': participants,
      'createdAt': createdAt,
      'disappearingMessages': disappearingMessages,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'activeGameId': activeGameId,
      'activeGameType': activeGameType,
    };
  }

  RoomModel copyWith({
    String? roomId,
    String? roomName,
    String? secretWordHash,
    List<String>? participants,
    DateTime? createdAt,
    bool? disappearingMessages,
    String? lastMessage,
    DateTime? lastMessageTime,
    Map<String, String>? gamePlayerAssignments,
    String? activeGameId,
    Map<String, dynamic>? gameState,
  }) {
    return RoomModel(
      roomId: roomId ?? this.roomId,
      roomName: roomName ?? this.roomName,
      secretWordHash: secretWordHash ?? this.secretWordHash,
      participants: participants ?? this.participants,
      createdAt: createdAt ?? this.createdAt,
      disappearingMessages: disappearingMessages ?? this.disappearingMessages,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,

    );
  }
}