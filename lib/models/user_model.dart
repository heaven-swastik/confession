class UserModel {
  final String uid;
  final String username;
  final String avatarEmoji;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.username,
    required this.avatarEmoji,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      username: map['username'] ?? '',
      avatarEmoji: map['avatarEmoji'] ?? '😊',
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'avatarEmoji': avatarEmoji,
      'createdAt': createdAt,
    };
  }

  UserModel copyWith({
    String? uid,
    String? username,
    String? avatarEmoji,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
