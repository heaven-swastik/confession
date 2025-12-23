import 'package:flutter/material.dart';
import '../models/room_model.dart';
import 'music_player_panel.dart';
import 'music_search_sheet.dart';

class MusicSection extends StatelessWidget {
  final RoomModel room;
  const MusicSection({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF575799)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '🎵 Music Room',
          style: TextStyle(
            color: Color(0xFF575799),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD3C4FF).withOpacity(0.3),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.search_rounded,
                color: Color(0xFFD3C4FF),
                size: 20,
              ),
            ),
            tooltip: 'Search songs',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => MusicSearchSheet(roomId: room.roomId),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: MusicPlayerPanel(roomId: room.roomId),
    );
  }
}