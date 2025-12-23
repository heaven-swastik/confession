class UserModel {
  final String uid;
  final String username;
  final String avatarEmoji;
  final DateTime createdAt;
  final String? spotifyAccessToken;
  final String? spotifyRefreshToken;
  final String? currentTrackUri;

  UserModel({
    required this.uid,
    required this.username,
    required this.avatarEmoji,
    required this.createdAt,
    this.spotifyAccessToken,
    this.spotifyRefreshToken,
    this.currentTrackUri,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      username: map['username'] ?? '',
      avatarEmoji: map['avatarEmoji'] ?? '😊',
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      spotifyAccessToken: map['spotifyAccessToken'],
      spotifyRefreshToken: map['spotifyRefreshToken'],
      currentTrackUri: map['currentTrackUri'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'avatarEmoji': avatarEmoji,
      'createdAt': createdAt,
      'spotifyAccessToken': spotifyAccessToken,
      'spotifyRefreshToken': spotifyRefreshToken,
      'currentTrackUri': currentTrackUri,
    };
  }

  UserModel copyWith({
    String? uid,
    String? username,
    String? avatarEmoji,
    DateTime? createdAt,
    String? spotifyAccessToken,
    String? spotifyRefreshToken,
    String? currentTrackUri,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      createdAt: createdAt ?? this.createdAt,
      spotifyAccessToken: spotifyAccessToken ?? this.spotifyAccessToken,
      spotifyRefreshToken: spotifyRefreshToken ?? this.spotifyRefreshToken,
      currentTrackUri: currentTrackUri ?? this.currentTrackUri,
    );
  }
}