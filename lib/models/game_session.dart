import 'package:cloud_firestore/cloud_firestore.dart';

enum GameType {
  colorSplit,
  emojiGuess,
  musicSection,
}

class GameSession {
  final String gameId;
  final GameType gameType;
  final String roomId;
  final List<PlayerInfo> players;
  final Map<String, int> scores;
  final int currentRound;
  final int maxRounds;
  final GameState state;
  final DateTime createdAt;
  final Map<String, dynamic>? gameData;

  GameSession({
    required this.gameId,
    required this.gameType,
    required this.roomId,
    required this.players,
    Map<String, int>? scores,
    this.currentRound = 1,
    this.maxRounds = 5,
    this.state = GameState.waiting,
    DateTime? createdAt,
    this.gameData,
  })  : scores = scores ?? {},
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'gameId': gameId,
      'gameType': gameType.name,
      'roomId': roomId,
      'players': players.map((p) => p.toJson()).toList(),
      'scores': scores,
      'currentRound': currentRound,
      'maxRounds': maxRounds,
      'state': state.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'gameData': gameData,
    };
  }

  factory GameSession.fromJson(Map<String, dynamic> json) {
    return GameSession(
      gameId: json['gameId'],
      gameType: GameType.values.firstWhere((e) => e.name == json['gameType']),
      roomId: json['roomId'],
      players: (json['players'] as List).map((p) => PlayerInfo.fromJson(p)).toList(),
      scores: Map<String, int>.from(json['scores'] ?? {}),
      currentRound: json['currentRound'] ?? 1,
      maxRounds: json['maxRounds'] ?? 5,
      state: GameState.values.firstWhere((e) => e.name == json['state'], orElse: () => GameState.waiting),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      gameData: json['gameData'],
    );
  }

  GameSession copyWith({
    Map<String, int>? scores,
    int? currentRound,
    GameState? state,
    Map<String, dynamic>? gameData,
  }) {
    return GameSession(
      gameId: gameId,
      gameType: gameType,
      roomId: roomId,
      players: players,
      scores: scores ?? this.scores,
      currentRound: currentRound ?? this.currentRound,
      maxRounds: maxRounds,
      state: state ?? this.state,
      createdAt: createdAt,
      gameData: gameData ?? this.gameData,
    );
  }
}

class PlayerInfo {
  final String userId;
  final String username;
  final int playerNumber;
  final bool isReady;

  PlayerInfo({
    required this.userId,
    required this.username,
    required this.playerNumber,
    this.isReady = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'playerNumber': playerNumber,
      'isReady': isReady,
    };
  }

  factory PlayerInfo.fromJson(Map<String, dynamic> json) {
    return PlayerInfo(
      userId: json['userId'],
      username: json['username'],
      playerNumber: json['playerNumber'],
      isReady: json['isReady'] ?? false,
    );
  }

  PlayerInfo copyWith({bool? isReady}) {
    return PlayerInfo(
      userId: userId,
      username: username,
      playerNumber: playerNumber,
      isReady: isReady ?? this.isReady,
    );
  }
}

enum GameState {
  waiting,
  ready,
  playing,
  finished,
}

// Color Split Game Data
class ColorSplitData {
  final Map<String, List<DrawPoint>> strokes;
  final String? winner;
  final int player1Coverage;
  final int player2Coverage;

  ColorSplitData({
    Map<String, List<DrawPoint>>? strokes,
    this.winner,
    this.player1Coverage = 0,
    this.player2Coverage = 0,
  }) : strokes = strokes ?? {};

  Map<String, dynamic> toJson() {
    return {
      'strokes': strokes.map((key, value) => MapEntry(key, value.map((p) => p.toJson()).toList())),
      'winner': winner,
      'player1Coverage': player1Coverage,
      'player2Coverage': player2Coverage,
    };
  }

  factory ColorSplitData.fromJson(Map<String, dynamic> json) {
    return ColorSplitData(
      strokes: (json['strokes'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              (value as List).map((p) => DrawPoint.fromJson(p)).toList(),
            ),
          ) ??
          {},
      winner: json['winner'],
      player1Coverage: json['player1Coverage'] ?? 0,
      player2Coverage: json['player2Coverage'] ?? 0,
    );
  }
}

class DrawPoint {
  final double x;
  final double y;
  final String color;
  final double strokeWidth;

  DrawPoint({
    required this.x,
    required this.y,
    required this.color,
    this.strokeWidth = 5.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'color': color,
      'strokeWidth': strokeWidth,
    };
  }

  factory DrawPoint.fromJson(Map<String, dynamic> json) {
    return DrawPoint(
      x: json['x'],
      y: json['y'],
      color: json['color'],
      strokeWidth: json['strokeWidth'] ?? 5.0,
    );
  }
}

// Emoji Guess Game Data
class EmojiGuessData {
  final String? currentWord;
  final String? currentHint;
  final String? currentGuesser;
  final String? currentHinter;
  final DateTime? roundStartTime;
  final int timeLimit;
  final List<String> usedWords;

  EmojiGuessData({
    this.currentWord,
    this.currentHint,
    this.currentGuesser,
    this.currentHinter,
    this.roundStartTime,
    this.timeLimit = 30,
    List<String>? usedWords,
  }) : usedWords = usedWords ?? [];

  Map<String, dynamic> toJson() {
    return {
      'currentWord': currentWord,
      'currentHint': currentHint,
      'currentGuesser': currentGuesser,
      'currentHinter': currentHinter,
      'roundStartTime': roundStartTime != null ? Timestamp.fromDate(roundStartTime!) : null,
      'timeLimit': timeLimit,
      'usedWords': usedWords,
    };
  }

  factory EmojiGuessData.fromJson(Map<String, dynamic> json) {
    return EmojiGuessData(
      currentWord: json['currentWord'],
      currentHint: json['currentHint'],
      currentGuesser: json['currentGuesser'],
      currentHinter: json['currentHinter'],
      roundStartTime: json['roundStartTime'] != null ? (json['roundStartTime'] as Timestamp).toDate() : null,
      timeLimit: json['timeLimit'] ?? 30,
      usedWords: List<String>.from(json['usedWords'] ?? []),
    );
  }
}

// Music Session Data
class MusicSessionData {
  final TrackInfo? currentTrack;
  final Map<String, PlayerMusicState> playerStates;

  MusicSessionData({
    this.currentTrack,
    Map<String, PlayerMusicState>? playerStates,
  }) : playerStates = playerStates ?? {};

  Map<String, dynamic> toJson() {
    return {
      'currentTrack': currentTrack?.toJson(),
      'playerStates': playerStates.map((key, value) => MapEntry(key, value.toJson())),
    };
  }

  factory MusicSessionData.fromJson(Map<String, dynamic> json) {
    return MusicSessionData(
      currentTrack: json['currentTrack'] != null ? TrackInfo.fromJson(json['currentTrack']) : null,
      playerStates: (json['playerStates'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, PlayerMusicState.fromJson(value)),
          ) ??
          {},
    );
  }
}

class TrackInfo {
  final String name;
  final String artist;
  final int duration;
  final String? url;

  TrackInfo({
    required this.name,
    required this.artist,
    required this.duration,
    this.url,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'artist': artist,
      'duration': duration,
      'url': url,
    };
  }

  factory TrackInfo.fromJson(Map<String, dynamic> json) {
    return TrackInfo(
      name: json['name'],
      artist: json['artist'],
      duration: json['duration'],
      url: json['url'],
    );
  }
}

class PlayerMusicState {
  final bool isPlaying;
  final int position;

  PlayerMusicState({
    this.isPlaying = false,
    this.position = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'isPlaying': isPlaying,
      'position': position,
    };
  }

  factory PlayerMusicState.fromJson(Map<String, dynamic> json) {
    return PlayerMusicState(
      isPlaying: json['isPlaying'] ?? false,
      position: json['position'] ?? 0,
    );
  }
}