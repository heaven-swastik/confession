import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String username;
  final String? email;
  final DateTime createdAt;
  final String? spotifyAccessToken;
  final String? spotifyRefreshToken;
  final String? currentTrackUri;
  final bool isOnline;
  final DateTime? lastSeen;
  final String? avatarUrl;

  UserModel({
    required this.uid,
    required this.username,
    this.email,
    required this.createdAt,
    this.spotifyAccessToken,
    this.spotifyRefreshToken,
    this.currentTrackUri,
    this.isOnline = false,
    this.lastSeen,
    this.avatarUrl,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      username: map['username'] ?? '',
      email: map['email'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      spotifyAccessToken: map['spotifyAccessToken'],
      spotifyRefreshToken: map['spotifyRefreshToken'],
      currentTrackUri: map['currentTrackUri'],
      isOnline: map['isOnline'] ?? false,
      lastSeen: (map['lastSeen'] as Timestamp?)?.toDate(),
      avatarUrl: map['avatarUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
      'spotifyAccessToken': spotifyAccessToken,
      'spotifyRefreshToken': spotifyRefreshToken,
      'currentTrackUri': currentTrackUri,
      'isOnline': isOnline,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'avatarUrl': avatarUrl,
    };
  }

  String getLastSeenText() {
    if (isOnline) return 'Online';
    if (lastSeen == null) return 'Offline';

    final now = DateTime.now();
    final difference = now.difference(lastSeen!);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return 'Long ago';
    }
  }

  UserModel copyWith({
    String? uid,
    String? username,
    String? email,
    DateTime? createdAt,
    String? spotifyAccessToken,
    String? spotifyRefreshToken,
    String? currentTrackUri,
    bool? isOnline,
    DateTime? lastSeen,
    String? avatarUrl,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      spotifyAccessToken: spotifyAccessToken ?? this.spotifyAccessToken,
      spotifyRefreshToken: spotifyRefreshToken ?? this.spotifyRefreshToken,
      currentTrackUri: currentTrackUri ?? this.currentTrackUri,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}