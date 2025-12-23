import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/game_session.dart';

class GameService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new game session
  Future<GameSession> createGameSession({
    required String roomId,
    required GameType gameType,
    required List<PlayerInfo> players,
    int maxRounds = 5,
  }) async {
    final gameId = _firestore.collection('games').doc().id;

    final session = GameSession(
      gameId: gameId,
      gameType: gameType,
      roomId: roomId,
      players: players,
      maxRounds: maxRounds,
      scores: {for (var p in players) p.userId: 0},
    );

    await _firestore.collection('games').doc(gameId).set(session.toJson());
    await _firestore.collection('rooms').doc(roomId).update({
      'activeGameId': gameId,
      'activeGameType': gameType.name,
    });

    return session;
  }

  // Stream game session
  Stream<GameSession?> streamGameSession(String gameId) {
    return _firestore.collection('games').doc(gameId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return GameSession.fromJson(snapshot.data()!);
    });
  }

  // Update game session
  Future<void> updateGameSession(GameSession session) async {
    await _firestore.collection('games').doc(session.gameId).update(session.toJson());
  }

  // Update game data only
  Future<void> updateGameData(String gameId, Map<String, dynamic> gameData) async {
    await _firestore.collection('games').doc(gameId).update({
      'gameData': gameData,
    });
  }

  // Update scores
  Future<void> updateScores(String gameId, Map<String, int> scores) async {
    await _firestore.collection('games').doc(gameId).update({
      'scores': scores,
    });
  }

  // Update game state
  Future<void> updateGameState(String gameId, GameState state) async {
    await _firestore.collection('games').doc(gameId).update({
      'state': state.name,
    });
  }

  // Player ready toggle
  Future<void> togglePlayerReady(String gameId, String userId, bool isReady) async {
    final doc = await _firestore.collection('games').doc(gameId).get();
    if (!doc.exists) return;

    final session = GameSession.fromJson(doc.data()!);
    final updatedPlayers = session.players.map((p) {
      if (p.userId == userId) {
        return p.copyWith(isReady: isReady);
      }
      return p;
    }).toList();

    await _firestore.collection('games').doc(gameId).update({
      'players': updatedPlayers.map((p) => p.toJson()).toList(),
    });
  }

  // Next round
  Future<void> nextRound(String gameId) async {
    final doc = await _firestore.collection('games').doc(gameId).get();
    if (!doc.exists) return;

    final session = GameSession.fromJson(doc.data()!);
    final nextRound = session.currentRound + 1;

    if (nextRound > session.maxRounds) {
      await updateGameState(gameId, GameState.finished);
    } else {
      await _firestore.collection('games').doc(gameId).update({
        'currentRound': nextRound,
      });
    }
  }

  // End game
  Future<void> endGame(String gameId, String roomId) async {
    await _firestore.collection('games').doc(gameId).update({
      'state': GameState.finished.name,
    });

    await _firestore.collection('rooms').doc(roomId).update({
      'activeGameId': null,
      'activeGameType': null,
    });
  }

  // === COLOR SPLIT GAME ===
  Future<void> addDrawStroke(String gameId, String playerId, List<DrawPoint> points) async {
    final doc = await _firestore.collection('games').doc(gameId).get();
    if (!doc.exists) return;

    final session = GameSession.fromJson(doc.data()!);
    final gameData = session.gameData ?? {};
    final colorData = ColorSplitData.fromJson(gameData);

    final updatedStrokes = Map<String, List<DrawPoint>>.from(colorData.strokes);
    updatedStrokes[playerId] = [...(updatedStrokes[playerId] ?? []), ...points];

    final updatedData = ColorSplitData(
      strokes: updatedStrokes,
      player1Coverage: colorData.player1Coverage,
      player2Coverage: colorData.player2Coverage,
      winner: colorData.winner,
    );

    await updateGameData(gameId, updatedData.toJson());
  }

  Future<void> updateCoverage(String gameId, int player1Coverage, int player2Coverage) async {
    final doc = await _firestore.collection('games').doc(gameId).get();
    if (!doc.exists) return;

    final session = GameSession.fromJson(doc.data()!);
    final gameData = session.gameData ?? {};
    final colorData = ColorSplitData.fromJson(gameData);

    final updatedData = ColorSplitData(
      strokes: colorData.strokes,
      player1Coverage: player1Coverage,
      player2Coverage: player2Coverage,
      winner: colorData.winner,
    );

    await updateGameData(gameId, updatedData.toJson());
  }

  // === EMOJI GUESS GAME ===
  Future<void> startEmojiRound(String gameId, String word, String hinter, String guesser) async {
    final emojiData = EmojiGuessData(
      currentWord: word,
      currentHint: null,
      currentGuesser: guesser,
      currentHinter: hinter,
      roundStartTime: DateTime.now(),
      timeLimit: 30,
    );

    await updateGameData(gameId, emojiData.toJson());
  }

  Future<void> submitHint(String gameId, String hint) async {
    final doc = await _firestore.collection('games').doc(gameId).get();
    if (!doc.exists) return;

    final session = GameSession.fromJson(doc.data()!);
    final gameData = session.gameData ?? {};
    final emojiData = EmojiGuessData.fromJson(gameData);

    final updatedData = EmojiGuessData(
      currentWord: emojiData.currentWord,
      currentHint: hint,
      currentGuesser: emojiData.currentGuesser,
      currentHinter: emojiData.currentHinter,
      roundStartTime: emojiData.roundStartTime,
      timeLimit: emojiData.timeLimit,
      usedWords: emojiData.usedWords,
    );

    await updateGameData(gameId, updatedData.toJson());
  }

  Future<void> checkGuess(String gameId, String guess, GameSession session) async {
    final gameData = session.gameData ?? {};
    final emojiData = EmojiGuessData.fromJson(gameData);

    final isCorrect = guess.trim().toLowerCase() == emojiData.currentWord?.toLowerCase();
    final scores = Map<String, int>.from(session.scores);

    if (isCorrect) {
      scores[emojiData.currentGuesser!] = (scores[emojiData.currentGuesser!] ?? 0) + 10;
    } else {
      scores[emojiData.currentHinter!] = (scores[emojiData.currentHinter!] ?? 0) + 5;
    }

    await updateScores(gameId, scores);
  }

  // === MUSIC SESSION ===
  Future<void> setCurrentTrack(String gameId, TrackInfo track) async {
    final doc = await _firestore.collection('games').doc(gameId).get();
    if (!doc.exists) return;

    final session = GameSession.fromJson(doc.data()!);
    final gameData = session.gameData ?? {};
    final musicData = MusicSessionData.fromJson(gameData);

    final updatedData = MusicSessionData(
      currentTrack: track,
      playerStates: musicData.playerStates,
    );

    await updateGameData(gameId, updatedData.toJson());
  }

  Future<void> updatePlayerMusicState(String gameId, String playerId, bool isPlaying, int position) async {
    final doc = await _firestore.collection('games').doc(gameId).get();
    if (!doc.exists) return;

    final session = GameSession.fromJson(doc.data()!);
    final gameData = session.gameData ?? {};
    final musicData = MusicSessionData.fromJson(gameData);

    final updatedStates = Map<String, PlayerMusicState>.from(musicData.playerStates);
    updatedStates[playerId] = PlayerMusicState(
      isPlaying: isPlaying,
      position: position,
    );

    final updatedData = MusicSessionData(
      currentTrack: musicData.currentTrack,
      playerStates: updatedStates,
    );

    await updateGameData(gameId, updatedData.toJson());
  }

  // Get player number for user in game
  int? getPlayerNumber(GameSession session, String userId) {
    try {
      final player = session.players.firstWhere((p) => p.userId == userId);
      return player.playerNumber;
    } catch (e) {
      return null;
    }
  }

  // Check if all players ready
  bool areAllPlayersReady(GameSession session) {
    return session.players.every((p) => p.isReady);
  }

  // Get winner
  String? getWinner(GameSession session) {
    if (session.scores.isEmpty) return null;

    final sorted = session.scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxScore = sorted.first.value;
    final winners = sorted.where((e) => e.value == maxScore).toList();

    if (winners.length > 1) return 'Tie!';

    final winnerId = winners.first.key;
    final player = session.players.firstWhere((p) => p.userId == winnerId);
    return '${player.username} (Player ${player.playerNumber})';
  }
}