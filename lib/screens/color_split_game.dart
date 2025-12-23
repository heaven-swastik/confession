import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/room_model.dart';
import '../models/game_session.dart';
import '../services/game_service.dart';
import '../services/auth_service.dart';

class ColorSplitGame extends StatefulWidget {
  final String gameId;
  final RoomModel room;

  const ColorSplitGame({super.key, required this.gameId, required this.room});

  @override
  State<ColorSplitGame> createState() => _ColorSplitGameState();
}

class _ColorSplitGameState extends State<ColorSplitGame> {
  final GameService _gameService = GameService();
  final List<DrawPoint> _currentStroke = [];
  Color _selectedColor = Colors.red;
  bool _isDrawing = false;
  GameSession? _session;
  int? _myPlayerNumber;

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

              _session = snapshot.data!;
              _myPlayerNumber = _gameService.getPlayerNumber(_session!, userId);

              return Column(
                children: [
                  _buildHeader(),
                  _buildScoreboard(),
                  Expanded(child: _buildCanvas()),
                  _buildColorPicker(),
                  _buildControls(),
                ],
              );
            },
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
              gradient: LinearGradient(colors: [Color(0xFF8B7FD9), Color(0xFF6B5FB5)]),
            ),
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 20),
              onPressed: () => _showExitDialog(),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🎨 Color Split',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                ),
                Text(
                  'Color your half faster!',
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
              'Player $_myPlayerNumber',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF333333)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreboard() {
    final player1Score = _session?.scores[_session?.players[0].userId] ?? 0;
    final player2Score = _session?.scores[_session?.players[1].userId] ?? 0;

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
          _buildPlayerScore('Player 1', player1Score, Colors.blue),
          Container(width: 2, height: 30, color: Colors.grey[300]),
          _buildPlayerScore('Player 2', player2Score, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildPlayerScore(String name, int score, Color color) {
    return Column(
      children: [
        Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text('$score%', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCanvas() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: GestureDetector(
          onPanStart: (details) => _onPanStart(details),
          onPanUpdate: (details) => _onPanUpdate(details),
          onPanEnd: (details) => _onPanEnd(details),
          child: CustomPaint(
            painter: ColorSplitPainter(
              session: _session,
              myPlayerNumber: _myPlayerNumber,
            ),
            child: Container(),
          ),
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.brown,
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: colors.map((color) {
          return GestureDetector(
            onTap: () => setState(() => _selectedColor = color),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _selectedColor == color ? Colors.black : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _clearMyHalf,
              icon: const Icon(Icons.clear, color: Colors.white),
              label: const Text('Clear My Half', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _finishGame,
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text('Finish', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B7FD9),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    if (_myPlayerNumber == null) return;
    setState(() {
      _isDrawing = true;
      _currentStroke.clear();
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDrawing || _myPlayerNumber == null) return;
    
    final point = DrawPoint(
      x: details.localPosition.dx,
      y: details.localPosition.dy,
      color: '#${_selectedColor.value.toRadixString(16).substring(2)}',
    );
    
    setState(() {
      _currentStroke.add(point);
    });
  }

  void _onPanEnd(DragEndDetails details) async {
    if (_myPlayerNumber == null || _currentStroke.isEmpty) return;

    await _gameService.addDrawStroke(
      widget.gameId,
      'player$_myPlayerNumber',
      _currentStroke,
    );

    setState(() {
      _isDrawing = false;
      _currentStroke.clear();
    });
  }

  Future<void> _clearMyHalf() async {
    // Implementation to clear player's half
  }

  Future<void> _finishGame() async {
    await _gameService.updateGameState(widget.gameId, GameState.finished);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Game finished!')),
      );
    }
  }

  Future<void> _showExitDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Game?'),
        content: const Text('Are you sure you want to leave?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Exit'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      Navigator.pop(context);
    }
  }
}

class ColorSplitPainter extends CustomPainter {
  final GameSession? session;
  final int? myPlayerNumber;

  ColorSplitPainter({this.session, this.myPlayerNumber});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw dividing line
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );

    // Draw strokes from session
    if (session?.gameData != null) {
      final colorData = ColorSplitData.fromJson(session!.gameData!);
      
      for (var entry in colorData.strokes.entries) {
        final points = entry.value;
        for (var point in points) {
          final pointPaint = Paint()
            ..color = Color(int.parse('FF${point.color}', radix: 16))
            ..strokeWidth = point.strokeWidth
            ..strokeCap = StrokeCap.round;
          
          canvas.drawCircle(
            Offset(point.x, point.y),
            point.strokeWidth / 2,
            pointPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}