import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/room_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/voice_note_service.dart';
import '../widgets/chat_bubble.dart';
import 'dart:async';
import '../screens/game_lobby_screen.dart';

class ChatScreen extends StatefulWidget {
  final RoomModel room;

  const ChatScreen({super.key, required this.room});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final VoiceNoteService _voiceNoteService = VoiceNoteService();
  final FocusNode _textFieldFocusNode = FocusNode();

  bool _isRecording = false;
  bool _isUploading = false;
  bool _showEmojiPicker = false;
  int _recordDuration = 0;
  Timer? _timer;
  String? _recordedFilePath;
  MessageModel? _replyToMessage;
  String? _currentUserId;
  
  bool _hasScrolledToBottom = false;

  late AnimationController _recordAnimationController;
  late Animation<double> _recordPulseAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _recordAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _recordPulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _recordAnimationController, curve: Curves.easeInOut),
    );

    _initUser();
  }

  void _initUser() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    _currentUserId = authService.user?.uid;

    if (_currentUserId != null) {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      await firestoreService.setUserOnline(_currentUserId!);
      
      // Mark all messages as read when opening chat
      await firestoreService.markAllMessagesAsRead(
        roomId: widget.room.roomId,
        userId: _currentUserId!,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (_currentUserId == null) return;

    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    if (state == AppLifecycleState.resumed) {
      firestoreService.setUserOnline(_currentUserId!);
      firestoreService.markAllMessagesAsRead(
        roomId: widget.room.roomId,
        userId: _currentUserId!,
      );
    } else if (state == AppLifecycleState.paused) {
      firestoreService.setUserOffline(_currentUserId!);
    }
  }

  @override
  void dispose() {
    if (_currentUserId != null) {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      firestoreService.setUserOffline(_currentUserId!);
    }

    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    _textFieldFocusNode.dispose();
    _timer?.cancel();
    _voiceNoteService.dispose();
    _recordAnimationController.dispose();
    super.dispose();
  }

  // ALWAYS SCROLL TO BOTTOM - FIX
  void _scrollToBottom({bool animate = true}) {
    if (!mounted || !_scrollController.hasClients) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      
      final maxScroll = _scrollController.position.maxScrollExtent;
      if (maxScroll > 0) {
        if (animate) {
          _scrollController.animateTo(
            maxScroll,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(maxScroll);
        }
      }
    });
  }

  void _startTimer() {
    _recordDuration = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isRecording) {
        setState(() {
          _recordDuration++;
        });
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  String _formatDuration(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  Future<void> _startRecording() async {
    final hasPermission = await _voiceNoteService.checkPermission();
    if (!hasPermission) {
      if (mounted) _showSnackBar('🎤 Microphone permission needed');
      return;
    }

    final started = await _voiceNoteService.startRecording();
    if (started && mounted) {
      setState(() {
        _isRecording = true;
        _recordDuration = 0;
      });
      _startTimer();
      _recordAnimationController.repeat(reverse: true);
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    
    final path = await _voiceNoteService.stopRecording();
    _stopTimer();
    _recordAnimationController.stop();
    _recordAnimationController.reset();

    if (mounted) {
      setState(() {
        _isRecording = false;
        _recordedFilePath = path;
      });
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _cancelRecording() async {
    await _voiceNoteService.cancelRecording();
    _stopTimer();
    _recordAnimationController.stop();
    _recordAnimationController.reset();

    if (mounted) {
      setState(() {
        _isRecording = false;
        _recordDuration = 0;
        _recordedFilePath = null;
      });
    }
  }

  Future<void> _sendVoiceNote() async {
    if (_recordedFilePath == null) return;

    // Set uploading state IMMEDIATELY
    setState(() => _isUploading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);

      final userId = authService.user?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Upload voice note
      final result = await _voiceNoteService.uploadVoiceNote(
        filePath: _recordedFilePath!,
        roomId: widget.room.roomId,
        senderId: userId,
      );

      if (result != null && mounted) {
        // Send message
        await firestoreService.sendVoiceNote(
          roomId: widget.room.roomId,
          senderId: userId,
          voiceNoteUrl: result['url'],
          duration: result['duration'],
          replyToMessageId: _replyToMessage?.messageId,
          replyToText: _replyToMessage?.text,
          replyToSenderId: _replyToMessage?.senderId,
          replyToType: _replyToMessage?.type,
        );
        
        if (mounted) {
          _showSnackBar('🎤 Voice note sent!');
          
          // CLEAR STATE IMMEDIATELY after successful send
          setState(() {
            _isUploading = false;
            _recordedFilePath = null;
            _recordDuration = 0;
            _replyToMessage = null;
          });
          
          // Scroll to bottom
          _scrollToBottom();
        }
      } else {
        throw Exception('Upload failed');
      }
    } catch (e) {
      debugPrint('Voice note error: $e');
      if (mounted) {
        _showSnackBar('❌ Failed to send voice note');
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Clear input IMMEDIATELY
    _messageController.clear();

    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    final userId = authService.user?.uid;
    if (userId == null) return;

    try {
      await firestoreService.sendMessage(
        roomId: widget.room.roomId,
        senderId: userId,
        text: text,
        type: MessageType.text,
        replyToMessageId: _replyToMessage?.messageId,
        replyToText: _replyToMessage?.text,
        replyToSenderId: _replyToMessage?.senderId,
        replyToType: _replyToMessage?.type,
      );

      if (mounted) {
        setState(() {
          _replyToMessage = null;
        });
      }
      HapticFeedback.lightImpact();
      _scrollToBottom();
    } catch (e) {
      debugPrint('Send message error: $e');
      if (mounted) {
        _showSnackBar('❌ Failed to send message');
        // Put text back if failed
        _messageController.text = text;
      }
    }
  }

  void _handleReply(MessageModel message) {
    setState(() {
      _replyToMessage = message;
      _showEmojiPicker = false;
    });
    _textFieldFocusNode.requestFocus();
    HapticFeedback.selectionClick();
  }

  void _cancelReply() {
    setState(() {
      _replyToMessage = null;
    });
  }

  Future<void> _handleDelete(MessageModel message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final firestoreService =
          Provider.of<FirestoreService>(context, listen: false);
      try {
        await firestoreService.deleteMessage(
          roomId: widget.room.roomId,
          messageId: message.messageId,
        );
        if (mounted) _showSnackBar('🗑️ Message deleted');
        HapticFeedback.mediumImpact();
      } catch (e) {
        if (mounted) _showSnackBar('❌ Error: $e');
      }
    }
  }

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
      if (_showEmojiPicker) {
        _textFieldFocusNode.unfocus();
      }
    });
    HapticFeedback.selectionClick();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF8B7FD9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showMembersBottomSheet() {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'Members',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B7FD9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.room.participants.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: widget.room.participants.length,
                itemBuilder: (context, index) {
                  final userId = widget.room.participants[index];
                  return StreamBuilder<UserModel?>(
                    stream: firestoreService.streamUser(userId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const ListTile(
                          leading: CircleAvatar(child: Icon(Icons.person)),
                          title: Text('Loading...'),
                        );
                      }

                      final user = snapshot.data!;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFF8B7FD9),
                                child: Text(
                                  user.username[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              if (user.isOnline)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Text(
                            user.username,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            user.getLastSeenText(),
                            style: TextStyle(
                              color: user.isOnline
                                  ? Colors.green
                                  : Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                          trailing: user.uid == _currentUserId
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8B7FD9).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'You',
                                    style: TextStyle(
                                      color: Color(0xFF8B7FD9),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

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
              _buildHeader(),

              // Messages
              Expanded(
                child: StreamBuilder<List<MessageModel>>(
                  stream: firestoreService.getRoomMessages(widget.room.roomId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 3,
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return const Center(
                        child: Text(
                          'Error loading messages',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    final messages = snapshot.data ?? [];
                    if (messages.isEmpty) return _buildEmptyState();

                    // SCROLL TO BOTTOM ON FIRST LOAD
                    if (!_hasScrolledToBottom && messages.isNotEmpty) {
                      _hasScrolledToBottom = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToBottom(animate: false);
                      });
                    }

                    // Mark messages as read
                    if (_currentUserId != null) {
                      for (final message in messages) {
                        if (message.senderId != _currentUserId && 
                            !message.readBy.contains(_currentUserId)) {
                          firestoreService.markMessageAsRead(
                            roomId: widget.room.roomId,
                            messageId: message.messageId,
                            userId: _currentUserId!,
                          );
                        }
                      }
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        return _buildMessageItem(messages[index]);
                      },
                    );
                  },
                ),
              ),

              if (_replyToMessage != null) _buildReplyPreview(),

              _buildInput(),

              if (_showEmojiPicker) _buildSimpleEmojiPicker(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageItem(MessageModel message) {
    final isMyMessage = message.senderId == _currentUserId;

    return GestureDetector(
      onDoubleTap: () async {
        if (_currentUserId == null) return;
        HapticFeedback.mediumImpact();
        final firestoreService = Provider.of<FirestoreService>(context, listen: false);
        
        // Check if user already reacted
        if (message.reactions.containsKey(_currentUserId)) {
          // Remove reaction
          await firestoreService.removeReaction(
            roomId: widget.room.roomId,
            messageId: message.messageId,
            userId: _currentUserId!,
          );
        } else {
          // Add heart reaction
          await firestoreService.addReaction(
            roomId: widget.room.roomId,
            messageId: message.messageId,
            userId: _currentUserId!,
            emoji: '💖',
          );
        }
      },
      onLongPress: () => _showMessageOptions(message, isMyMessage),
      child: Dismissible(
        key: ValueKey(message.messageId),
        direction: isMyMessage
            ? DismissDirection.endToStart
            : DismissDirection.startToEnd,
        confirmDismiss: (direction) async {
          _handleReply(message);
          return false;
        },
        background: Container(
          alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
          padding: EdgeInsets.only(
            left: isMyMessage ? 0 : 20,
            right: isMyMessage ? 20 : 0,
          ),
          child: Icon(
            Icons.reply,
            color: Colors.white.withOpacity(0.7),
            size: 28,
          ),
        ),
        child: ChatBubble(
          message: message,
          roomId: widget.room.roomId,
          currentUserId: _currentUserId ?? '',
          allParticipants: widget.room.participants,
        ),
      ),
    );
  }

  void _showMessageOptions(MessageModel message, bool isMyMessage) {
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.reply, color: Color(0xFF8B7FD9)),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(context);
                  _handleReply(message);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.emoji_emotions, color: Color(0xFF8B7FD9)),
                title: const Text('React'),
                onTap: () {
                  Navigator.pop(context);
                  _showEmojiReactions(message, firestoreService);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy, color: Color(0xFF8B7FD9)),
                title: const Text('Copy'),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: message.text));
                  _showSnackBar('📋 Copied to clipboard!');
                },
              ),
              if (isMyMessage)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title:
                      const Text('Delete', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _handleDelete(message);
                  },
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showEmojiReactions(
      MessageModel message, FirestoreService firestoreService) {
    final reactions = ['💖', '❤️', '👍', '😂', '😮', '😢', '🙏', '🔥', '👏', '🎉', '🚀', '✨'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('React to message'),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: reactions.map((emoji) {
            final hasReacted = message.reactions[_currentUserId] == emoji;
            return GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                if (_currentUserId == null) return;
                
                if (hasReacted) {
                  // Remove reaction
                  await firestoreService.removeReaction(
                    roomId: widget.room.roomId,
                    messageId: message.messageId,
                    userId: _currentUserId!,
                  );
                } else {
                  // Add/change reaction
                  await firestoreService.addReaction(
                    roomId: widget.room.roomId,
                    messageId: message.messageId,
                    userId: _currentUserId!,
                    emoji: emoji,
                  );
                }
                HapticFeedback.lightImpact();
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: hasReacted ? const Color(0xFF8B7FD9).withOpacity(0.2) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(25),
                  border: hasReacted ? Border.all(color: const Color(0xFF8B7FD9), width: 2) : null,
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 28)),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: Color(0xFF8B7FD9), width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Replying to',
                  style: TextStyle(
                    color: Color(0xFF8B7FD9),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _replyToMessage!.text.length > 50
                      ? '${_replyToMessage!.text.substring(0, 50)}...'
                      : _replyToMessage!.text,
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: _cancelReply,
            color: Colors.grey[600],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleEmojiPicker() {
    final emojis = [
      '💖', '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤',
      '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂',
      '🙂', '🙃', '😉', '😊', '😇', '🥰', '😍', '🤩',
      '😘', '😗', '😚', '😙', '😋', '😛', '😜', '🤪',
      '😝', '🤑', '🤗', '🤭', '🤫', '🤔', '🤐', '🤨',
      '😐', '😑', '😶', '😏', '😒', '🙄', '😬', '🤥',
      '😌', '😔', '😪', '🤤', '😴', '😷', '🤒', '🤕',
      '🤢', '🤮', '🤧', '🥵', '🥶', '😵', '🤯', '🤠',
      '🥳', '😎', '🤓', '🧐', '😕', '😟', '🙁', '😮',
      '😯', '😲', '😳', '🥺', '😦', '😧', '😨', '😰',
      '😥', '😢', '😭', '😱', '😖', '😣', '😞', '😓',
      '👍', '👎', '👊', '✊', '🤛', '🤜', '🤞', '✌️',
      '🤟', '🤘', '👌', '🤏', '👈', '👉', '👆', '👇',
      '☝️', '✋', '🤚', '🖐', '🖖', '👋', '🤙', '💪',
      '🔥', '✨', '💫', '⭐', '🌟', '💥', '💯', '💢',
      '🎉', '🎊', '🎈', '🎁', '🏆', '🥇', '🚀', '🦄',
    ];

    return Container(
      height: 250,
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Emojis',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _showEmojiPicker = false),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: emojis.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    _messageController.text += emojis[index];
                    _messageController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _messageController.text.length),
                    );
                    HapticFeedback.selectionClick();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        emojis[index],
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B7FD9), Color(0xFF6B5FB5)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.chat_bubble, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: _showMembersBottomSheet,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.room.roomName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Tap to see ${widget.room.participants.length} members',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF8B7FD9), Color(0xFF6B5FB5)],
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.games, color: Colors.white, size: 20),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameLobbyScreen(room: widget.room),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: Colors.white.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: _buildInputContent(),
    );
  }

  Widget _buildInputContent() {
    // FIXED: No blinking! Static text during upload
    if (_isUploading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B7FD9)),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Uploading voice note...',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
      );
    }

    if (_recordedFilePath != null) {
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8B7FD9), Color(0xFF6B5FB5)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mic, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Voice note (${_formatDuration(_recordDuration)})',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFF333333)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () => setState(() {
              _recordedFilePath = null;
              _recordDuration = 0;
            }),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8B7FD9), Color(0xFF6B5FB5)],
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon:
                  const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              onPressed: _sendVoiceNote,
            ),
          ),
        ],
      );
    }

    // FIXED: Smooth pulsing animation, no terminal spam
    if (_isRecording) {
      return Row(
        children: [
          ScaleTransition(
            scale: _recordPulseAnimation,
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Recording ${_formatDuration(_recordDuration)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: _cancelRecording,
          ),
          Container(
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.stop, color: Colors.white, size: 20),
              onPressed: _stopRecording,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8B7FD9), Color(0xFF6B5FB5)],
            ),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.mic, color: Colors.white, size: 20),
            onPressed: _startRecording,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(
            _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined,
            color: const Color(0xFF8B7FD9),
            size: 24,
          ),
          onPressed: _toggleEmojiPicker,
        ),
        Expanded(
          child: TextField(
            controller: _messageController,
            focusNode: _textFieldFocusNode,
            style: const TextStyle(
              color: Color(0xFF333333),
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: 'Type a message...',
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontWeight: FontWeight.w400,
              ),
              border: InputBorder.none,
            ),
            maxLines: null,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _sendMessage(),
            onTap: () {
              if (_showEmojiPicker) {
                setState(() => _showEmojiPicker = false);
              }
            },
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
            icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            onPressed: _sendMessage,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.25),
              border:
                  Border.all(color: Colors.white.withOpacity(0.3), width: 3),
            ),
            child: const Icon(Icons.chat_bubble_outline,
                size: 60, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Text(
              'Start the conversation! 💬',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}