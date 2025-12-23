import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/room_model.dart';
import '../models/message_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/voice_note_service.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_bubble.dart';
import 'dart:async';
import '../screens/game_lobby_screen.dart';

class ChatScreen extends StatefulWidget {
  final RoomModel room;

  const ChatScreen({super.key, required this.room});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final VoiceNoteService _voiceNoteService = VoiceNoteService();
  
  bool _isRecording = false;
  bool _isUploading = false;
  int _recordDuration = 0;
  Timer? _timer;
  String? _recordedFilePath;
  
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _timer?.cancel();
    _voiceNoteService.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _startTimer() {
    _recordDuration = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordDuration++;
      });
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
    if (started) {
      setState(() => _isRecording = true);
      _startTimer();
      _fabAnimationController.repeat(reverse: true);
    }
  }

  Future<void> _stopRecording() async {
    final path = await _voiceNoteService.stopRecording();
    _stopTimer();
    _fabAnimationController.stop();
    _fabAnimationController.reset();
    
    setState(() {
      _isRecording = false;
      _recordedFilePath = path;
    });
  }

  Future<void> _cancelRecording() async {
    await _voiceNoteService.cancelRecording();
    _stopTimer();
    _fabAnimationController.stop();
    _fabAnimationController.reset();
    
    setState(() {
      _isRecording = false;
      _recordDuration = 0;
      _recordedFilePath = null;
    });
  }

  Future<void> _sendVoiceNote() async {
    if (_recordedFilePath == null) return;

    setState(() => _isUploading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      
      final userId = authService.user?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final result = await _voiceNoteService.uploadVoiceNote(
        filePath: _recordedFilePath!,
        roomId: widget.room.roomId,
        senderId: userId,
      );

      if (result != null) {
        await firestoreService.sendVoiceNote(
          roomId: widget.room.roomId,
          senderId: userId,
          voiceNoteUrl: result['url'],
          duration: result['duration'],
        );
        if (mounted) _showSnackBar('🎤 Voice note sent!');
      } else {
        throw Exception('Upload failed');
      }
    } catch (e) {
      if (mounted) _showSnackBar('❌ Error: $e');
    } finally {
      setState(() {
        _isUploading = false;
        _recordedFilePath = null;
        _recordDuration = 0;
      });
      _scrollToBottom();
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

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
      );
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) _showSnackBar('❌ Error: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF8B7FD9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

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
              // IMPROVED HEADER
              _buildHeader(),

              // Messages
              Expanded(
                child: StreamBuilder<List<MessageModel>>(
                  stream: firestoreService.getRoomMessages(widget.room.roomId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 3,
                        ),
                      );
                    }

                    final messages = snapshot.data ?? [];
                    if (messages.isEmpty) return _buildEmptyState();

                    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) => ChatBubble(
                        message: messages[index],
                        roomId: widget.room.roomId,
                      ),
                    );
                  },
                ),
              ),

              // Input area
              _buildInput(),
            ],
          ),
        ),
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
        // Back button
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF8B7FD9), Color(0xFF6B5FB5)],
            ),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        const SizedBox(width: 10),

        // Chat bubble icon
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

        // Room info
        Expanded(
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
              ),
              Text(
                '${widget.room.participants.length} members',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // -------------------- New Games Button --------------------
        IconButton(
          icon: const Icon(Icons.games, color: Color(0xFF8B7FD9)),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GameLobbyScreen(room: widget.room),
              ),
            );
          },
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
    if (_isUploading) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Uploading...', style: TextStyle(fontWeight: FontWeight.w600)),
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
              'Voice (${_formatDuration(_recordDuration)})',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF333333)),
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
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              onPressed: _sendVoiceNote,
            ),
          ),
        ],
      );
    }

    if (_isRecording) {
      return Row(
        children: [
          ScaleTransition(
            scale: _fabScaleAnimation,
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
        Expanded(
          child: TextField(
            controller: _messageController,
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
            onSubmitted: (_) => _sendMessage(),
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
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
            ),
            child: const Icon(Icons.chat_bubble_outline, size: 60, color: Colors.white),
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
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}