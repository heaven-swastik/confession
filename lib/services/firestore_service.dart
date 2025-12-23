import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../models/room_model.dart';
import '../models/message_model.dart';

class FirestoreService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============ USER OPERATIONS ============
  
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

  Stream<UserModel?> streamUser(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
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

  // ============ ONLINE STATUS ============
  
  Future<void> setUserOnline(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error setting user online: $e');
    }
  }

  Future<void> setUserOffline(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error setting user offline: $e');
    }
  }

  // ============ SPOTIFY ============
  
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

  // ============ ROOM OPERATIONS ============
  
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
      final doc = await _firestore.collection('rooms').doc(roomId).get();
      
      if (!doc.exists) {
        return null;
      }

      final room = RoomModel.fromMap(doc.data()!, doc.id);
      final secretWordHash = hashSecretWord(secretWord);

      if (room.secretWordHash != secretWordHash) {
        return null;
      }

      if (!room.participants.contains(userId)) {
        await _firestore.collection('rooms').doc(roomId).update({
          'participants': FieldValue.arrayUnion([userId]),
        });
      }

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

  Future<void> updateRoomName({
    required String roomId,
    required String newName,
  }) async {
    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'roomName': newName,
      });
    } catch (e) {
      debugPrint('Error updating room name: $e');
      rethrow;
    }
  }

  // ============ MESSAGE OPERATIONS WITH REPLY SUPPORT ============
  
  Future<String?> sendMessage({
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
    String? replyToMessageId,
    String? replyToText,
    String? replyToSenderId,
    MessageType? replyToType,
  }) async {
    try {
      final message = MessageModel(
        messageId: '',
        roomId: roomId,
        senderId: senderId,
        text: text,
        timestamp: DateTime.now(),
        type: type,
        reactions: {}, // NEW: Initialize empty reactions map
        readBy: [senderId], // NEW: Sender has read their own message
        deliveredTo: [senderId], // NEW: Message delivered to sender
        stickerUrl: stickerUrl,
        voiceNoteUrl: voiceNoteUrl,
        voiceNoteDuration: voiceNoteDuration,
        spotifyTrackUri: spotifyTrackUri,
        spotifyTrackName: spotifyTrackName,
        spotifyArtistName: spotifyArtistName,
        replyToMessageId: replyToMessageId,
        replyToText: replyToText,
        replyToSenderId: replyToSenderId,
        replyToType: replyToType,
      );

      final docRef = await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('messages')
          .add(message.toMap());

      await _firestore.collection('rooms').doc(roomId).update({
        'lastMessage': text,
        'lastMessageTime': message.timestamp,
      });
      
      return docRef.id;
    } catch (e) {
      debugPrint('Error sending message: $e');
      return null;
    }
  }

  Future<String?> sendVoiceNote({
    required String roomId,
    required String senderId,
    required String voiceNoteUrl,
    required int duration,
    String? replyToMessageId,
    String? replyToText,
    String? replyToSenderId,
    MessageType? replyToType,
  }) async {
    try {
      return await sendMessage(
        roomId: roomId,
        senderId: senderId,
        text: 'Voice note',
        type: MessageType.voiceNote,
        voiceNoteUrl: voiceNoteUrl,
        voiceNoteDuration: duration,
        replyToMessageId: replyToMessageId,
        replyToText: replyToText,
        replyToSenderId: replyToSenderId,
        replyToType: replyToType,
      );
    } catch (e) {
      debugPrint('Error sending voice note: $e');
      return null;
    }
  }

  Future<void> sendSpotifyTrack({
    required String roomId,
    required String senderId,
    required String trackUri,
    required String trackName,
    required String artistName,
    String? replyToMessageId,
    String? replyToText,
    String? replyToSenderId,
    MessageType? replyToType,
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
        replyToMessageId: replyToMessageId,
        replyToText: replyToText,
        replyToSenderId: replyToSenderId,
        replyToType: replyToType,
      );
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

  // ============ NEW: REACTION METHODS ============
  
  // Add or update a user's reaction to a message
  Future<void> addReaction({
    required String roomId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    try {
      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('messages')
          .doc(messageId)
          .update({
        'reactions.$userId': emoji, // Store as map: userId -> emoji
      });
    } catch (e) {
      debugPrint('Error adding reaction: $e');
      rethrow;
    }
  }

  // Remove a user's reaction from a message
  Future<void> removeReaction({
    required String roomId,
    required String messageId,
    required String userId,
  }) async {
    try {
      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('messages')
          .doc(messageId)
          .update({
        'reactions.$userId': FieldValue.delete(),
      });
    } catch (e) {
      debugPrint('Error removing reaction: $e');
      rethrow;
    }
  }

  // ============ NEW: READ RECEIPT METHODS ============
  
  // Mark a single message as read by a user
  Future<void> markMessageAsRead({
    required String roomId,
    required String messageId,
    required String userId,
  }) async {
    try {
      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('messages')
          .doc(messageId)
          .update({
        'readBy': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      debugPrint('Error marking message as read: $e');
    }
  }

  // Mark a message as delivered to a user
  Future<void> markMessageAsDelivered({
    required String roomId,
    required String messageId,
    required String userId,
  }) async {
    try {
      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('messages')
          .doc(messageId)
          .update({
        'deliveredTo': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      debugPrint('Error marking message as delivered: $e');
    }
  }

  // Mark all messages in a room as read by a user (called when opening chat)
  Future<void> markAllMessagesAsRead({
    required String roomId,
    required String userId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('messages')
          .where('senderId', isNotEqualTo: userId) // Not sent by current user
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        final message = MessageModel.fromMap(doc.data(), doc.id);
        if (!message.readBy.contains(userId)) {
          batch.update(doc.reference, {
            'readBy': FieldValue.arrayUnion([userId]),
          });
        }
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all messages as read: $e');
    }
  }

  // ============ MESSAGE DELETION ============

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

  // ============ GAME OPERATIONS ============
  
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
    } catch (e) {
      debugPrint('Error ending game: $e');
      rethrow;
    }
  }

  // ============ MUSIC OPERATIONS ============
  
  Future<void> updateMusicState({
    required String roomId,
    required Map<String, dynamic> musicState,
  }) async {
    try {
      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('music_state')
          .doc('current')
          .set(musicState, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating music state: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getMusicState(String roomId) async {
    try {
      final doc = await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('music_state')
          .doc('current')
          .get();
      
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('Error getting music state: $e');
      return null;
    }
  }

  Stream<Map<String, dynamic>?> streamMusicState(String roomId) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('music_state')
        .doc('current')
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return doc.data();
      }
      return null;
    });
  }

  Future<void> clearMusicState(String roomId) async {
    try {
      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('music_state')
          .doc('current')
          .delete();
    } catch (e) {
      debugPrint('Error clearing music state: $e');
      rethrow;
    }
  }

  // ============ USERNAME OPERATIONS ============
  
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
    } catch (e) {
      debugPrint('Error releasing username: $e');
      rethrow;
    }
  }
}