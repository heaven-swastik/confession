import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';
import '../models/message_model.dart';
import '../services/auth_service.dart';

class ChatBubble extends StatefulWidget {
  final MessageModel message;
  final String roomId;
  final String currentUserId;
  final List<String> allParticipants;

  const ChatBubble({
    super.key,
    required this.message,
    required this.roomId,
    required this.currentUserId,
    required this.allParticipants,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.message.type == MessageType.voiceNote) {
      _setupAudioPlayer();
    }
  }

  void _setupAudioPlayer() {
    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) {
        setState(() => _duration = d);
      }
    });

    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) {
        setState(() => _position = p);
      }
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          _isLoading = state == PlayerState.playing && _duration == Duration.zero;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (widget.message.voiceNoteUrl == null) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        if (_position == Duration.zero) {
          await _audioPlayer.play(UrlSource(widget.message.voiceNoteUrl!));
        } else {
          await _audioPlayer.resume();
        }
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(timestamp);
    } else if (difference.inDays == 1) {
      return 'Yesterday ${DateFormat('HH:mm').format(timestamp)}';
    } else if (difference.inDays < 7) {
      return DateFormat('EEE HH:mm').format(timestamp);
    } else {
      return DateFormat('MMM dd, HH:mm').format(timestamp);
    }
  }

  // Check if message is read by all other participants
  bool _isReadByAll() {
    final otherParticipants = widget.allParticipants
        .where((id) => id != widget.message.senderId)
        .toList();
    
    if (otherParticipants.isEmpty) return false;
    
    return otherParticipants.every((id) => 
        widget.message.readBy.contains(id)
    );
  }

  // Check if message is delivered to all
  bool _isDeliveredToAll() {
    final otherParticipants = widget.allParticipants
        .where((id) => id != widget.message.senderId)
        .toList();
    
    if (otherParticipants.isEmpty) return false;
    
    return otherParticipants.every((id) => 
        widget.message.deliveredTo.contains(id)
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMyMessage = widget.message.senderId == widget.currentUserId;
    final hasReactions = widget.message.reactions.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment:
            isMyMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Show reply preview if this message is a reply
          if (widget.message.replyToMessageId != null)
            _buildReplyPreview(isMyMessage),

          // Main message bubble
          Row(
            mainAxisAlignment:
                isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMyMessage) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF8B7FD9),
                  child: Text(
                    widget.message.senderId[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isMyMessage
                        ? const LinearGradient(
                            colors: [Color(0xFF8B7FD9), Color(0xFF6B5FB5)],
                          )
                        : null,
                    color: isMyMessage ? null : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isMyMessage ? 20 : 4),
                      bottomRight: Radius.circular(isMyMessage ? 4 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMessageContent(isMyMessage),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTimestamp(widget.message.timestamp),
                            style: TextStyle(
                              fontSize: 11,
                              color: isMyMessage
                                  ? Colors.white.withOpacity(0.7)
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          // BLUE TICK (Read Receipt) - Only show for sent messages
                          if (isMyMessage) ...[
                            const SizedBox(width: 4),
                            Icon(
                              _isReadByAll() 
                                  ? Icons.done_all 
                                  : _isDeliveredToAll()
                                      ? Icons.done_all
                                      : Icons.done,
                              size: 16,
                              color: _isReadByAll() 
                                  ? Colors.blue 
                                  : Colors.white.withOpacity(0.7),
                            ),
                          ],
                        ],
                      ),
                      
                      // REACTIONS - Display below message
                      if (hasReactions) _buildReactions(isMyMessage),
                    ],
                  ),
                ),
              ),
              if (isMyMessage) const SizedBox(width: 8),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReactions(bool isMyMessage) {
    final reactions = widget.message.reactions;
    if (reactions.isEmpty) return const SizedBox();

    // Group reactions by emoji
    final Map<String, List<String>> groupedReactions = {};
    reactions.forEach((userId, emoji) {
      if (!groupedReactions.containsKey(emoji)) {
        groupedReactions[emoji] = [];
      }
      groupedReactions[emoji]!.add(userId);
    });

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: groupedReactions.entries.map((entry) {
          final emoji = entry.key;
          final users = entry.value;
          final count = users.length;
          final hasCurrentUser = users.contains(widget.currentUserId);
          
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: hasCurrentUser 
                  ? (isMyMessage ? Colors.white.withOpacity(0.3) : const Color(0xFF8B7FD9).withOpacity(0.2))
                  : (isMyMessage ? Colors.white.withOpacity(0.15) : Colors.grey.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(12),
              border: hasCurrentUser 
                  ? Border.all(
                      color: isMyMessage ? Colors.white.withOpacity(0.5) : const Color(0xFF8B7FD9),
                      width: 1.5,
                    )
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 14),
                ),
                if (count > 1) ...[
                  const SizedBox(width: 4),
                  Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isMyMessage 
                          ? Colors.white 
                          : const Color(0xFF8B7FD9),
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReplyPreview(bool isMyMessage) {
    return Container(
      margin: EdgeInsets.only(
        left: isMyMessage ? 60 : 40,
        right: isMyMessage ? 40 : 60,
        bottom: 4,
      ),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isMyMessage
            ? Colors.white.withOpacity(0.2)
            : Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: isMyMessage ? Colors.white : const Color(0xFF8B7FD9),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.reply,
                size: 12,
                color: isMyMessage ? Colors.white : const Color(0xFF8B7FD9),
              ),
              const SizedBox(width: 4),
              Text(
                'Replying to',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isMyMessage ? Colors.white : const Color(0xFF8B7FD9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            widget.message.replyToText ?? '',
            style: TextStyle(
              fontSize: 12,
              color: isMyMessage
                  ? Colors.white.withOpacity(0.9)
                  : Colors.grey[700],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(bool isMyMessage) {
    switch (widget.message.type) {
      case MessageType.voiceNote:
        return _buildVoiceNotePlayer(isMyMessage);

      case MessageType.spotifyTrack:
        return _buildSpotifyTrack(isMyMessage);

      default:
        return Text(
          widget.message.text,
          style: TextStyle(
            fontSize: 15,
            color: isMyMessage ? Colors.white : const Color(0xFF333333),
            fontWeight: FontWeight.w500,
          ),
        );
    }
  }

  Widget _buildVoiceNotePlayer(bool isMyMessage) {
    final totalDuration = widget.message.voiceNoteDuration ?? 0;
    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    return SizedBox(
      width: 200,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause button
          GestureDetector(
            onTap: _togglePlayPause,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isMyMessage
                    ? Colors.white.withOpacity(0.2)
                    : const Color(0xFF8B7FD9).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: _isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isMyMessage ? Colors.white : const Color(0xFF8B7FD9),
                        ),
                      ),
                    )
                  : Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: isMyMessage ? Colors.white : const Color(0xFF8B7FD9),
                      size: 24,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Progress and duration
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: isMyMessage
                        ? Colors.white.withOpacity(0.3)
                        : Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isMyMessage ? Colors.white : const Color(0xFF8B7FD9),
                    ),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 4),
                
                // Time display
                Text(
                  _isPlaying || _position.inSeconds > 0
                      ? '${_formatDuration(_position)} / ${_formatDuration(_duration.inSeconds > 0 ? _duration : Duration(seconds: totalDuration))}'
                      : _formatDuration(Duration(seconds: totalDuration)),
                  style: TextStyle(
                    fontSize: 12,
                    color: isMyMessage
                        ? Colors.white.withOpacity(0.8)
                        : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpotifyTrack(bool isMyMessage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.music_note,
              color: isMyMessage ? Colors.white : Colors.green,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                widget.message.spotifyTrackName ?? 'Spotify Track',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isMyMessage ? Colors.white : const Color(0xFF333333),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (widget.message.spotifyArtistName != null) ...[
          const SizedBox(height: 2),
          Text(
            widget.message.spotifyArtistName!,
            style: TextStyle(
              fontSize: 12,
              color: isMyMessage
                  ? Colors.white.withOpacity(0.8)
                  : Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}