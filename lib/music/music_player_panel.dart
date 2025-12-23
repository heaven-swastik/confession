import 'package:flutter/material.dart';
import 'music_sync_service.dart';
import 'music_state_model.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';
import 'dart:math' as math;

class MusicPlayerPanel extends StatefulWidget {
  final String roomId;
  const MusicPlayerPanel({super.key, required this.roomId});

  @override
  State<MusicPlayerPanel> createState() => _MusicPlayerPanelState();
}

class _MusicPlayerPanelState extends State<MusicPlayerPanel>
    with TickerProviderStateMixin {
  final service = MusicSyncService();
  MusicStateModel? currentSong;
  final player = AudioPlayer();
  StreamSubscription? _musicSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerStateSubscription;

  bool _isBuffering = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isSeeking = false;
  String? _currentSongId;

  late AnimationController _pulseController;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _setupPlayer();
    _listenToMusicUpdates();
  }

  void _setupPlayer() {
    _positionSubscription = player.positionStream.listen((position) {
      if (!_isSeeking && mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });

    player.durationStream.listen((duration) {
      if (mounted && duration != null) {
        setState(() {
          _totalDuration = duration;
        });
      }
    });

    _playerStateSubscription = player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isBuffering = state.processingState == ProcessingState.loading ||
              state.processingState == ProcessingState.buffering;
        });

        if (state.playing) {
          _pulseController.repeat(reverse: true);
          _waveController.repeat(reverse: true);
        } else {
          _pulseController.stop();
          _waveController.stop();
        }
      }
    });

    player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed && mounted) {
        player.seek(Duration.zero);
        player.pause();
      }
    });
  }

  void _listenToMusicUpdates() {
    _musicSubscription = service.stream(widget.roomId).listen((data) async {
      if (data == null || !mounted) return;

      try {
        final song = MusicStateModel.fromMap(data);
        final songChanged = _currentSongId != song.songId;

        setState(() {
          currentSong = song;
        });

        if (songChanged) {
          _currentSongId = song.songId;
          await player.stop();

          if (song.audioUrl.isEmpty) return;

          try {
            await player.setUrl(song.audioUrl);

            if (song.isPlaying) {
              await player.play();
            }

            if (song.position > 0) {
              await player.seek(Duration(seconds: song.position.toInt()));
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to load song'),
                  backgroundColor: Color(0xFFFF6B9D),
                ),
              );
            }
          }
        } else {
          if (song.isPlaying && !player.playing) {
            await player.play();
          } else if (!song.isPlaying && player.playing) {
            await player.pause();
          }

          final currentPos = _currentPosition.inSeconds;
          final targetPos = song.position.toInt();

          if ((currentPos - targetPos).abs() > 3) {
            await player.seek(Duration(seconds: targetPos));
          }
        }
      } catch (e) {
        print('Playback error: $e');
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _musicSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _pulseController.dispose();
    _waveController.dispose();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (currentSong == null) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE6E6FA), // background
              Color(0xFFCCCCFF), // secondary
              Color(0xFFD3C4FF), // accent
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD3C4FF).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.music_note_rounded,
                  size: 60,
                  color: Color(0xFFD3C4FF),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No song playing',
                style: TextStyle(
                  color: Color(0xFF575799),
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap search to add music',
                style: TextStyle(
                  color: const Color(0xFF575799).withOpacity(0.6),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE6E6FA),
            Color(0xFFCCCCFF),
            Color(0xFFD3C4FF),
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
            child: Column(
              children: [
                // Song Title
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    currentSong!.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF575799),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const Spacer(),

                // Circular Album Art
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer pulse rings
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 280 + (_pulseController.value * 40),
                          height: 280 + (_pulseController.value * 40),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFF90D5FF).withOpacity(0.3 * (1 - _pulseController.value)),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // Main circle
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFD3C4FF),
                            Color(0xFF90D5FF),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD3C4FF).withOpacity(0.4),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: const Icon(
                          Icons.music_note_rounded,
                          color: Color(0xFFD3C4FF),
                          size: 80,
                        ),
                      ),
                    ),

                    // Progress circle
                    CustomPaint(
                      size: const Size(270, 270),
                      painter: CircularProgressPainter(
                        progress: _totalDuration.inSeconds > 0
                            ? _currentPosition.inSeconds / _totalDuration.inSeconds
                            : 0,
                        color: const Color(0xFF575799),
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Time Display
                Text(
                  _formatDuration(_currentPosition),
                  style: const TextStyle(
                    color: Color(0xFF575799),
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                // Progress Slider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFFD3C4FF),
                          inactiveTrackColor: const Color(0xFFCCCCFF),
                          thumbColor: const Color(0xFF90D5FF),
                          overlayColor: const Color(0xFF90D5FF).withOpacity(0.2),
                          trackHeight: 6,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                        ),
                        child: Slider(
                          value: _currentPosition.inSeconds.toDouble().clamp(
                            0.0,
                            _totalDuration.inSeconds.toDouble() > 0
                                ? _totalDuration.inSeconds.toDouble()
                                : 1.0,
                          ),
                          max: _totalDuration.inSeconds.toDouble() > 0
                              ? _totalDuration.inSeconds.toDouble()
                              : 1.0,
                          onChangeStart: (_) => _isSeeking = true,
                          onChanged: (value) {
                            setState(() {
                              _currentPosition = Duration(seconds: value.toInt());
                            });
                          },
                          onChangeEnd: (value) async {
                            _isSeeking = false;
                            await player.seek(Duration(seconds: value.toInt()));
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(_currentPosition),
                              style: TextStyle(
                                color: const Color(0xFF575799).withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _formatDuration(_totalDuration),
                              style: TextStyle(
                                color: const Color(0xFF575799).withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Control Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlButton(
                        icon: Icons.skip_previous_rounded,
                        size: 36,
                        onTap: () async {
                          final newPosition = _currentPosition - const Duration(seconds: 10);
                          await player.seek(
                              newPosition < Duration.zero ? Duration.zero : newPosition);
                        },
                      ),
                      _buildPlayButton(),
                      _buildControlButton(
                        icon: Icons.skip_next_rounded,
                        size: 36,
                        onTap: () async {
                          final newPosition = _currentPosition + const Duration(seconds: 10);
                          await player.seek(
                              newPosition > _totalDuration ? _totalDuration : newPosition);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    double size = 28,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD3C4FF).withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: const Color(0xFF575799),
          size: size,
        ),
      ),
    );
  }

  Widget _buildPlayButton() {
    if (_isBuffering) {
      return Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD3C4FF).withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 3,
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFD3C4FF),
            strokeWidth: 3,
          ),
        ),
      );
    }

    return InkWell(
      onTap: () {
        service.playPause(
          widget.roomId,
          !currentSong!.isPlaying,
        );
      },
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFD3C4FF),
              Color(0xFF90D5FF),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD3C4FF).withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Icon(
          currentSong!.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: 36,
        ),
      ),
    );
  }
}

// Custom Painter for Circular Progress
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  CircularProgressPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Background circle
    canvas.drawCircle(center, radius, paint);

    // Progress arc
    paint.color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );

    // Progress dot
    final angle = -math.pi / 2 + (2 * math.pi * progress);
    final dotX = center.dx + radius * math.cos(angle);
    final dotY = center.dy + radius * math.sin(angle);

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(dotX, dotY), 7, dotPaint);
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) =>
      progress != oldDelegate.progress;
}