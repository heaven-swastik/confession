import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../models/room_model.dart';
import '../models/message_model.dart';
import '../models/game_model.dart';
import '../screens/game_lobby_screen.dart';
import '../screens/game_play_screen.dart';


class FirestoreService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User operations
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(user.toMap());
    } catch (e) {
      debugPrint('Error creating user: $e');
      rethrow;
    }
  }

  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user: $e');
      return null;
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update(user.toMap());
    } catch (e) {
      debugPrint('Error updating user: $e');
      rethrow;
    }
  }

  Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
    } catch (e) {
      debugPrint('Error deleting user: $e');
      rethrow;
    }
  }

  Future<void> updateUserSpotifyTokens({
    required String uid,
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'spotifyAccessToken': accessToken,
        'spotifyRefreshToken': refreshToken,
      });
    } catch (e) {
      debugPrint('Error updating Spotify tokens: $e');
      rethrow;
    }
  }

  Future<void> updateCurrentTrack({
    required String uid,
    required String? trackUri,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'currentTrackUri': trackUri,
      });
    } catch (e) {
      debugPrint('Error updating current track: $e');
      rethrow;
    }
  }

  // Room operations
  String hashSecretWord(String secretWord) {
    final bytes = utf8.encode(secretWord.toLowerCase().trim());
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<RoomModel?> createRoom({
    required String roomId,
    required String secretWord,
    required String creatorUid,
    bool disappearingMessages = false,
    String? roomName,
  }) async {
    try {
      final secretWordHash = hashSecretWord(secretWord);
      
      final room = RoomModel(
        roomId: roomId,
        roomName: roomName ?? 'Room ${roomId.substring(0, 6).toUpperCase()}',
        secretWordHash: secretWordHash,
        participants: [creatorUid],
        createdAt: DateTime.now(),
        disappearingMessages: disappearingMessages,
      );

      await _firestore.collection('rooms').doc(roomId).set(room.toMap());
      return room;
    } catch (e) {
      debugPrint('Error creating room: $e');
      return null;
    }
  }

  Future<RoomModel?> joinRoom({
    required String roomId,
    required String secretWord,
    required String userId,
  }) async {
    try {
      debugPrint('Attempting to join room: $roomId');
      final doc = await _firestore.collection('rooms').doc(roomId).get();
      
      if (!doc.exists) {
        debugPrint('Room does not exist: $roomId');
        return null;
      }

      final room = RoomModel.fromMap(doc.data()!, doc.id);
      final secretWordHash = hashSecretWord(secretWord);
      
      debugPrint('Stored hash: ${room.secretWordHash}');
      debugPrint('Entered hash: $secretWordHash');

      if (room.secretWordHash != secretWordHash) {
        debugPrint('Secret word does not match');
        return null;
      }

      if (!room.participants.contains(userId)) {
        await _firestore.collection('rooms').doc(roomId).update({
          'participants': FieldValue.arrayUnion([userId]),
        });
      }

      debugPrint('Successfully joined room: $roomId');
      return room;
    } catch (e) {
      debugPrint('Error joining room: $e');
      return null;
    }
  }

  Future<RoomModel?> getRoom(String roomId) async {
    try {
      final doc = await _firestore.collection('rooms').doc(roomId).get();
      if (doc.exists) {
        return RoomModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting room: $e');
      return null;
    }
  }

  Stream<List<RoomModel>> getUserRooms(String userId) {
    return _firestore
        .collection('rooms')
        .where('participants', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RoomModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> deleteRoom(String roomId) async {
    try {
      await _firestore.collection('rooms').doc(roomId).delete();
      
      final messagesSnapshot = await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('messages')
          .get();
      
      for (var doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('Error deleting room: $e');
      rethrow;
    }
  }

  // NEW: Update room name
  Future<void> updateRoomName({
    required String roomId,
    required String newName,
  }) async {
    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'roomName': newName,
      });
      debugPrint('Room name updated: $newName');
    } catch (e) {
      debugPrint('Error updating room name: $e');
      rethrow;
    }
  }

  // NEW: Game operations
  Future<void> startGame({
    required String roomId,
    required String gameId,
    required Map<String, String> playerAssignments,
  }) async {
    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'activeGameId': gameId,
        'gamePlayerAssignments': playerAssignments,
        'gameState': {},
      });
      debugPrint('Game started: $gameId');
    } catch (e) {
      debugPrint('Error starting game: $e');
      rethrow;
    }
  }

  Future<void> updateGameState({
    required String roomId,
    required Map<String, dynamic> gameState,
  }) async {
    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'gameState': gameState,
      });
    } catch (e) {
      debugPrint('Error updating game state: $e');
      rethrow;
    }
  }

  Future<void> endGame(String roomId) async {
    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'activeGameId': null,
        'gamePlayerAssignments': null,
        'gameState': null,
      });
      debugPrint('Game ended');
    } catch (e) {
      debugPrint('Error ending game: $e');
      rethrow;
    }
  }

  Stream<RoomModel?> getRoomStream(String roomId) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return RoomModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  // Message operations - COMPLETE WITH ALL PARAMETERS
  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String text,
    MessageType type = MessageType.text,
    String? stickerUrl,
    String? voiceNoteUrl,
    int? voiceNoteDuration,
    String? spotifyTrackUri,
    String? spotifyTrackName,
    String? spotifyArtistName,
  }) async {
    try {
      final message = MessageModel(
        messageId: '',
        roomId: roomId,
        senderId: senderId,
        text: text,
        timestamp: DateTime.now(),
        type: type,
        stickerUrl: stickerUrl,
        voiceNoteUrl: voiceNoteUrl,
        voiceNoteDuration: voiceNoteDuration,
        spotifyTrackUri: spotifyTrackUri,
        spotifyTrackName: spotifyTrackName,
        spotifyArtistName: spotifyArtistName,
      );

      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('messages')
          .add(message.toMap());

      await _firestore.collection('rooms').doc(roomId).update({
        'lastMessage': text,
        'lastMessageTime': message.timestamp,
      });
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  // NEW: Convenience method for voice notes
 Future<void> sendVoiceNote({
  required String roomId,
  required String senderId,
  required String voiceNoteUrl,
  required int duration,
}) async {
  await sendMessage(
    roomId: roomId,
    senderId: senderId,
    text: 'Voice note',
    type: MessageType.voiceNote,
    voiceNoteUrl: voiceNoteUrl,
    voiceNoteDuration: duration,
  );
}
// Start game session
Future<void> startGameSession({
  required String roomId,
  required GameSession gameSession,
}) async {
  try {
    await _firestore.collection('rooms').doc(roomId).update({
      'activeGame': gameSession.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    debugPrint('Error starting game: $e');
    rethrow;
  }
}

// Update game state
// Update game state using Map
Future<void> updateGameStateMap({
  required String roomId,
  required Map<String, dynamic> gameState,
}) async {
  try {
    await _firestore.collection('rooms').doc(roomId).update({
      'gameState': gameState,
    });
    debugPrint('Game state updated (Map)');
  } catch (e) {
    debugPrint('Error updating game state (Map): $e');
    rethrow;
  }
}

// Update game state using GameSession object
Future<void> updateGameStateSession({
  required String roomId,
  required GameSession gameSession,
}) async {
  try {
    await _firestore.collection('rooms').doc(roomId).update({
      'activeGame': gameSession.toJson(),
    });
    debugPrint('Game state updated (GameSession)');
  } catch (e) {
    debugPrint('Error updating game state (GameSession): $e');
    rethrow;
  }
}

// End game (Map version)
Future<void> endGameMap(String roomId) async {
  try {
    await _firestore.collection('rooms').doc(roomId).update({
      'activeGameId': null,
      'gamePlayerAssignments': null,
      'gameState': null,
    });
    debugPrint('Game ended (Map)');
  } catch (e) {
    debugPrint('Error ending game (Map): $e');
    rethrow;
  }
}

// End game (GameSession version)
Future<void> endGameSession(String roomId) async {
  try {
    await _firestore.collection('rooms').doc(roomId).update({
      'activeGame': null,
    });
    debugPrint('Game ended (GameSession)');
  } catch (e) {
    debugPrint('Error ending game (GameSession): $e');
    rethrow;
  }
}

  // NEW: Convenience method for Spotify tracks
  Future<void> sendSpotifyTrack({
    required String roomId,
    required String senderId,
    required String trackUri,
    required String trackName,
    required String artistName,
  }) async {
    try {
      await sendMessage(
        roomId: roomId,
        senderId: senderId,
        text: '🎵 $trackName',
        type: MessageType.spotifyTrack,
        spotifyTrackUri: trackUri,
        spotifyTrackName: trackName,
        spotifyArtistName: artistName,
      );
      debugPrint('Spotify track sent: $trackName');
    } catch (e) {
      debugPrint('Error sending Spotify track: $e');
      rethrow;
    }
  }

  Stream<List<MessageModel>> getRoomMessages(String roomId) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> addReaction({
    required String roomId,
    required String messageId,
    required String emoji,
  }) async {
    try {
      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('messages')
          .doc(messageId)
          .update({'reactionEmoji': emoji});
    } catch (e) {
      debugPrint('Error adding reaction: $e');
      rethrow;
    }
  }

  Future<void> deleteMessage({
    required String roomId,
    required String messageId,
  }) async {
    try {
      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting message: $e');
      rethrow;
    }
  }

  // NEW: Username operations
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final result = await _firestore
          .collection('usernames')
          .doc(username.toLowerCase())
          .get();
      return !result.exists;
    } catch (e) {
      debugPrint('Error checking username: $e');
      return false;
    }
  }

  Future<void> reserveUsername({
    required String username,
    required String uid,
  }) async {
    try {
      await _firestore
          .collection('usernames')
          .doc(username.toLowerCase())
          .set({
        'uid': uid,
        'createdAt': DateTime.now(),
      });
      debugPrint('Username reserved: $username');
    } catch (e) {
      debugPrint('Error reserving username: $e');
      rethrow;
    }
  }

  Future<void> releaseUsername(String username) async {
    try {
      await _firestore
          .collection('usernames')
          .doc(username.toLowerCase())
          .delete();
      debugPrint('Username released: $username');
    } catch (e) {
      debugPrint('Error releasing username: $e');
      rethrow;
    }
  }
}