import 'package:flutter/material.dart';
import '../models/room_model.dart';
import '../music/music_section.dart';
import 'color_split_game.dart';
import 'emoji_hint_guess_game.dart';

class GameLobbyScreen extends StatelessWidget {
  final RoomModel room;

  const GameLobbyScreen({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
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
              _buildHeader(context),
              Expanded(child: _buildGamesList(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
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
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Game Lobby',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                Text(
                  '${room.participants.length} players online',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Text('🎮', style: TextStyle(fontSize: 30)),
        ],
      ),
    );
  }

  Widget _buildGamesList(BuildContext context) {
    final games = [
      {
        'name': 'Music Room',
        'emoji': '🎵',
        'description': 'Listen to YouTube together',
        'players': '2+ Players',
        'color1': const Color(0xFFF093B0),
        'color2': const Color(0xFFE76A8F),
      },
      {
        'name': 'Color Split',
        'emoji': '🎨',
        'description': 'Collaborative coloring game',
        'players': '2 Players',
        'color1': const Color(0xFFB794F6),
        'color2': const Color(0xFF9F7AEA),
      },
      {
        'name': 'Emoji Guess',
        'emoji': '🤔',
        'description': 'Guess from hints & emojis',
        'players': '2 Players',
        'color1': const Color(0xFF7EC8E3),
        'color2': const Color(0xFF4A9FBF),
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        return _buildGameCard(
          context,
          game['name'] as String,
          game['emoji'] as String,
          game['description'] as String,
          game['players'] as String,
          game['color1'] as Color,
          game['color2'] as Color,
        );
      },
    );
  }

  Widget _buildGameCard(
    BuildContext context,
    String name,
    String emoji,
    String description,
    String players,
    Color color1,
    Color color2,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color1, color2],
        ),
        boxShadow: [
          BoxShadow(
            color: color1.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _startGame(context, name),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 36)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          players,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startGame(BuildContext context, String gameName) {
    if (gameName == 'Music Room') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MusicSection(room: room),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$gameName coming soon!'),
          backgroundColor: const Color(0xFF8B7FD9),
        ),
      );
    }
  }
}