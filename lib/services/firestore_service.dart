import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../models/room_model.dart';
import '../models/message_model.dart';

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
  }) async {
    try {
      final secretWordHash = hashSecretWord(secretWord);
      
      final room = RoomModel(
        roomId: roomId,
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

  // Message operations
  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String text,
    MessageType type = MessageType.text,
    String? stickerUrl,
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
}
