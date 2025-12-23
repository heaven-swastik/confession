import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/room_model.dart';
import '../models/game_session.dart';
import '../services/game_service.dart';
import '../services/auth_service.dart';

class EmojiHintGuessGame extends StatefulWidget {
  final String gameId;
  final RoomModel room;

  const EmojiHintGuessGame({super.key, required this.gameId, required this.room});

  @override
  State<EmojiHintGuessGame> createState() => _EmojiHintGuessGameState();
}

class _EmojiHintGuessGameState extends State<EmojiHintGuessGame> {
  final GameService _gameService = GameService();
  final TextEditingController _hintController = TextEditingController();
  final TextEditingController _guessController = TextEditingController();
  
  Timer? _timer;
  int _timeRemaining = 30;
  
  // Indian-themed words
  final List<String> _words = [
    'Bollywood', 'Taj Mahal', 'Cricket', 'Biryani', 'Diwali',
    'Holi', 'Mumbai', 'Delhi', 'Monsoon', 'Rickshaw',
    'Masala Chai', 'Samosa', 'Sari', 'Yoga', 'Gandhi',
  ];

  @override
  void dispose() {
    _timer?.cancel();
    _hintController.dispose();
    _guessController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userId = authService.user?.uid ?? '';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF8B7FD9), Color(0xFFB8A5E8), Color(0xFFD4C4F7)],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<GameSession?>(
            stream: _gameService.streamGameSession(widget.gameId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }

              final session = snapshot.data!;
              final myPlayerNumber = _gameService.getPlayerNumber(session, userId);
              final gameData = session.gameData != null
                  ? EmojiGuessData.fromJson(session.gameData!)
                  : null;

              final isMyTurnToHint = gameData?.currentHinter == userId;
              final isMyTurnToGuess = gameData?.currentGuesser == userId;

              return Column(
                children: [
                  _buildHeader(myPlayerNumber),
                  _buildScoreboard(session),
                  _buildTimer(),
                  Expanded(
                    child: _buildGameArea(
                      session,
                      gameData,
                      isMyTurnToHint,
                      isMyTurnToGuess,
                      userId,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(int? playerNumber) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.9),
      ),
      child: Row(
        children: [
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Color(0xFF8B7FD9), Color(0xFF6B5FB5)]),
            ),
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🤔 Emoji Guess',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                ),
                Text(
                  'Guess from hints!',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF8B7FD9).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Player $playerNumber',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF333333)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreboard(GameSession session) {
    final player1 = session.players[0];
    final player2 = session.players[1];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildPlayerScore(
            'Player 1',
            session.scores[player1.userId] ?? 0,
            Colors.blue,
          ),
          Container(width: 2, height: 30, color: Colors.grey[300]),
          _buildPlayerScore(
            'Player 2',
            session.scores[player2.userId] ?? 0,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerScore(String name, int score, Color color) {
    return Column(
      children: [
        Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text('$score pts', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTimer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _timeRemaining > 10 ? Colors.green : Colors.red,
            _timeRemaining > 10 ? Colors.green[700]! : Colors.red[700]!,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            '$_timeRemaining seconds',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameArea(
    GameSession session,
    EmojiGuessData? gameData,
    bool isMyTurnToHint,
    bool isMyTurnToGuess,
    String userId,
  ) {
    if (session.state == GameState.waiting) {
      return _buildWaitingScreen();
    }

    if (gameData == null) {
      return _buildStartButton(session, userId);
    }

    if (isMyTurnToHint) {
      return _buildHintScreen(gameData);
    }

    if (isMyTurnToGuess) {
      return _buildGuessScreen(gameData);
    }

    return _buildWatchingScreen(gameData);
  }

  Widget _buildWaitingScreen() {
    return const Center(
      child: Text(
        'Waiting for players...',
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }

  Widget _buildStartButton(GameSession session, String userId) {
    return Center(
      child: ElevatedButton(
        onPressed: () => _startRound(session, userId),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B7FD9),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text(
          'START ROUND',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildHintScreen(EmojiGuessData gameData) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Your word is:',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            gameData.currentWord ?? '',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B7FD9),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _hintController,
            decoration: InputDecoration(
              hintText: 'Enter hint or emojis...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            maxLength: 50,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _submitHint(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B7FD9),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'SEND HINT',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuessScreen(EmojiGuessData gameData) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Hint:',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            gameData.currentHint ?? 'Waiting for hint...',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B7FD9),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _guessController,
            decoration: InputDecoration(
              hintText: 'Your guess...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _submitGuess(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B7FD9),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'GUESS',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWatchingScreen(EmojiGuessData gameData) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: Text(
          'Watching others play...',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
    );
  }

  void _startRound(GameSession session, String userId) {
    final word = (_words..shuffle()).first;
    final players = session.players;
    final hinter = players[0].userId;
    final guesser = players[1].userId;

    _gameService.startEmojiRound(
      widget.gameId,
      word,
      hinter,
      guesser,
    );

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _timeRemaining = 30;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        setState(() {
          _timeRemaining--;
        });
      } else {
        timer.cancel();
        _timeUp();
      }
    });
  }

  void _submitHint() {
    if (_hintController.text.trim().isEmpty) return;
    _gameService.submitHint(widget.gameId, _hintController.text.trim());
    _hintController.clear();
  }

  Future<void> _submitGuess() async {
    if (_guessController.text.trim().isEmpty) return;

    final session = await _gameService.streamGameSession(widget.gameId).first;
    if (session != null) {
      await _gameService.checkGuess(widget.gameId, _guessController.text.trim(), session);
    }

    _guessController.clear();
    _timer?.cancel();
    
    // Next round after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _startRound(session!, session.players[0].userId);
    });
  }

  void _timeUp() {
    // Hinter gets points if time runs out
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Time up!')),
    );
  }
}