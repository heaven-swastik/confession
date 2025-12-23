class RoomModel {
  final String roomId;
  final String roomName;
  final String secretWordHash;
  final List<String> participants;
  final DateTime createdAt;
  final bool disappearingMessages;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final Map<String, String>? gamePlayerAssignments; // userId -> player role (A, B, C, etc.)
  final String? activeGameId;
  final Map<String, dynamic>? gameState;
  final Map<String, dynamic>? activeGame;

  RoomModel({
    required this.roomId,
    required this.roomName,
    required this.secretWordHash,
    required this.participants,
    required this.createdAt,
    this.disappearingMessages = false,
    this.lastMessage,
    this.lastMessageTime,
    this.gamePlayerAssignments,
    this.activeGameId,
    this.gameState,
    this.activeGame,
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
      gamePlayerAssignments: map['gamePlayerAssignments'] != null
          ? Map<String, String>.from(map['gamePlayerAssignments'])
          : null,
      activeGameId: map['activeGameId'],
      activeGame: map['activeGame'],
      gameState: map['gameState'] != null
          ? Map<String, dynamic>.from(map['gameState'])
          : null,
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
      'gamePlayerAssignments': gamePlayerAssignments,
      'activeGameId': activeGameId,
      'gameState': gameState,
      'activeGame': activeGame,
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
      gamePlayerAssignments: gamePlayerAssignments ?? this.gamePlayerAssignments,
      activeGameId: activeGameId ?? this.activeGameId,
      gameState: gameState ?? this.gameState,
    );
  }
}