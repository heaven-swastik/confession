import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/message_model.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/emoji_picker.dart';
import '../widgets/sticker_panel.dart';
import '../utils/constants.dart';

class ChatScreen extends StatefulWidget {
  final String roomId;

  const ChatScreen({super.key, required this.roomId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showEmojiPicker = false;
  bool _showStickerPanel = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final userId = authService.user?.uid;

    if (userId == null) return;

    await firestoreService.sendMessage(
      roomId: widget.roomId,
      senderId: userId,
      text: text,
      type: MessageType.text,
    );

    _messageController.clear();
    _scrollToBottom();
  }

  Future<void> _sendSticker(String stickerUrl) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final userId = authService.user?.uid;

    if (userId == null) return;

    await firestoreService.sendMessage(
      roomId: widget.roomId,
      senderId: userId,
      text: '',
      type: MessageType.sticker,
      stickerUrl: stickerUrl,
    );

    setState(() {
      _showStickerPanel = false;
    });
    _scrollToBottom();
  }

  Future<void> _sendIcebreaker(String question) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final userId = authService.user?.uid;

    if (userId == null) return;

    await firestoreService.sendMessage(
      roomId: widget.roomId,
      senderId: userId,
      text: question,
      type: MessageType.icebreaker,
    );

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showIcebreakerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text('Icebreaker Questions'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: Constants.icebreakerQuestions.length,
            itemBuilder: (context, index) {
              final question = Constants.icebreakerQuestions[index];
              return ListTile(
                title: Text(question),
                onTap: () {
                  Navigator.of(context).pop();
                  _sendIcebreaker(question);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final firestoreService = Provider.of<FirestoreService>(context);
    final userId = authService.user?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Column(
          children: [
            Text('Room ${widget.roomId.substring(0, 6).toUpperCase()}'),
            const SizedBox(height: 2),
            const Text(
              '🔒 Screenshots blocked',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            onPressed: _showIcebreakerDialog,
            tooltip: 'Icebreaker questions',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: firestoreService.getRoomMessages(widget.roomId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accent),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '💬',
                            style: TextStyle(fontSize: 64),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Start the conversation',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Say hello or share what\'s on your mind',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textColor.withOpacity(0.6),
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final messages = snapshot.data!;
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == userId;
                    return ChatBubble(
                      message: message,
                      isMe: isMe,
                      onReaction: (emoji) {
                        firestoreService.addReaction(
                          roomId: widget.roomId,
                          messageId: message.messageId,
                          emoji: emoji,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          if (_showStickerPanel)
            StickerPanel(
              onStickerSelected: _sendSticker,
              onClose: () {
                setState(() {
                  _showStickerPanel = false;
                });
              },
            ),
          if (_showEmojiPicker)
            EmojiPickerWidget(
              onEmojiSelected: (emoji) {
                _messageController.text += emoji;
              },
              onClose: () {
                setState(() {
                  _showEmojiPicker = false;
                });
              },
            ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppTheme.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                _showStickerPanel ? Icons.keyboard : Icons.emoji_emotions_outlined,
                color: AppTheme.accent,
              ),
              onPressed: () {
                setState(() {
                  _showStickerPanel = !_showStickerPanel;
                  _showEmojiPicker = false;
                });
              },
            ),
            IconButton(
              icon: Icon(
                _showEmojiPicker ? Icons.keyboard : Icons.insert_emoticon_outlined,
                color: AppTheme.accent2,
              ),
              onPressed: () {
                setState(() {
                  _showEmojiPicker = !_showEmojiPicker;
                  _showStickerPanel = false;
                });
              },
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppTheme.background,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: AppTheme.accent,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: AppTheme.white),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
