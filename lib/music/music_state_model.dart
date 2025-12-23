class MusicStateModel {
  final String songId;
  final String title;
  final String audioUrl;
  final bool isPlaying;
  final double position;
  final String uid;

  MusicStateModel({
    required this.songId,
    required this.title,
    required this.audioUrl,
    required this.isPlaying,
    required this.position,
    required this.uid,
  });

  factory MusicStateModel.fromMap(Map<String, dynamic> map) {
    return MusicStateModel(
      songId: map['songId'] ?? '',
      title: map['title'] ?? 'Unknown',
      audioUrl: map['audioUrl'] ?? '',
      isPlaying: map['isPlaying'] ?? false,
      position: (map['position'] as num?)?.toDouble() ?? 0.0,
      uid: map['uid'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'songId': songId,
      'title': title,
      'audioUrl': audioUrl,
      'isPlaying': isPlaying,
      'position': position,
      'uid': uid,
    };
  }
}