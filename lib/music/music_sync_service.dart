import 'package:cloud_firestore/cloud_firestore.dart';

class MusicSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<Map<String, dynamic>?> stream(String roomId) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .snapshots()
        .map((snap) {
      final data = snap.data();
      if (data == null) return null;
      return data['currentSong'] as Map<String, dynamic>?;
    });
  }

  Future<void> changeSong({
    required String roomId,
    required String songId,
    required String title,
    required String audioUrl,
    required String uid,
  }) async {
    final timestamp = FieldValue.serverTimestamp();
    await _firestore.collection('rooms').doc(roomId).set({
      'currentSong': {
        'songId': songId,
        'title': title,
        'audioUrl': audioUrl,
        'uid': uid,
        'isPlaying': true,
        'position': 0.0,
        'lastUpdated': timestamp,
      }
    }, SetOptions(merge: true));
  }

  Future<void> playPause(String roomId, bool isPlaying) async {
    final timestamp = FieldValue.serverTimestamp();
    await _firestore.collection('rooms').doc(roomId).update({
      'currentSong.isPlaying': isPlaying,
      'currentSong.lastUpdated': timestamp,
    });
  }

  Future<void> updatePosition(String roomId, double seconds) async {
    await _firestore.collection('rooms').doc(roomId).update({
      'currentSong.position': seconds,
      'currentSong.lastUpdated': FieldValue.serverTimestamp(),
    });
  }
}