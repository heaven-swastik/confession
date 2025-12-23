import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_model.dart';
import '../models/room_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

class GamePlayScreen extends StatefulWidget {
  final RoomModel room;
  final GameModel game;

  const GamePlayScreen({
    super.key,
    required this.room,
    required this.game,
  });

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen> {
  final TextEditingController _inputController = TextEditingController();
  GameSession? _session;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  void _loadSession() {
    if (widget.room.activeGame != null) {
      setState(() {
        _session = GameSession.fromJson(widget.room.activeGame!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUserId = authService.user?.uid ?? '';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF8B7FD9),
              Color(0xFFB8A5E8),
              Color(0xFFD4C4F7),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildGameInfo(),
              Expanded(child: _buildGameHistory()),
              if (_session?.currentPlayer == currentUserId)
                _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
              gradient: LinearGradient(
                colors: [Color(0xFF8B7FD9), Color(0xFF6B5FB5)],
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('End Game?'),
                    content: const Text('Are you sure?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('End'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  final firestoreService =
                      Provider.of<FirestoreService>(context, listen: false);
                  await firestoreService.endGame(widget.room.roomId);
                  if (mounted) Navigator.pop(context);
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.game.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                Text(
                  'Round ${_session?.currentRound ?? 1}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(widget.game.emoji, style: const TextStyle(fontSize: 30)),
        ],
      ),
    );
  }

  Widget _buildGameInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF8B7FD9).withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Current Turn: Player ${(_session?.players.indexOf(_session?.currentPlayer ?? '') ?? 0) + 1}',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildGameHistory() {
    if (_session == null || _session!.history.isEmpty) {
      return const Center(
        child: Text(
          'Game started! Make your move!',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _session!.history.length,
      itemBuilder: (context, index) {
        final turn = _session!.history[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Player ${_session!.players.indexOf(turn.playerId) + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B7FD9),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                turn.content,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              decoration: const InputDecoration(
                hintText: 'Your turn...',
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _submitTurn(),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8B7FD9), Color(0xFF6B5FB5)],
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _submitTurn,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitTurn() async {
    if (_inputController.text.trim().isEmpty || _session == null) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final currentUserId = authService.user?.uid ?? '';

    final turn = GameTurn(
      playerId: currentUserId,
      playerName: 'Player ${_session!.players.indexOf(currentUserId) + 1}',
      content: _inputController.text.trim(),
      round: _session!.currentRound,
    );

    final updatedHistory = [..._session!.history, turn];
    final nextPlayerIndex =
        (_session!.currentPlayerIndex + 1) % _session!.players.length;
    final nextRound = nextPlayerIndex == 0
        ? _session!.currentRound + 1
        : _session!.currentRound;

    final updatedSession = _session!.copyWith(
      currentPlayerIndex: nextPlayerIndex,
      currentRound: nextRound,
      history: updatedHistory,
    );

await firestoreService.updateGameStateSession(
  roomId: widget.room.roomId,
  gameSession: updatedSession,
);


    _inputController.clear();
    setState(() {
      _session = updatedSession;
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }
}