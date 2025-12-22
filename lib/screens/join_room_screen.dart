import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/custom_button.dart';
import '../utils/validators.dart';
import 'chat_screen.dart';

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roomIdController = TextEditingController();
  final _secretWordController = TextEditingController();
  bool _isJoining = false;

  @override
  void dispose() {
    _roomIdController.dispose();
    _secretWordController.dispose();
    super.dispose();
  }

  Future<void> _joinRoom() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isJoining = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final userId = authService.user?.uid;

    if (userId == null) {
      _showError('Please sign in first');
      setState(() {
        _isJoining = false;
      });
      return;
    }

    final roomId = _roomIdController.text.trim().toLowerCase();
    final secretWord = _secretWordController.text.trim();

    final room = await firestoreService.joinRoom(
      roomId: roomId,
      secretWord: secretWord,
      userId: userId,
    );

    setState(() {
      _isJoining = false;
    });

    if (room != null && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ChatScreen(roomId: roomId),
        ),
      );
    } else {
      _showError('Unable to join room. Please check:\n• Room ID is correct\n• Secret word matches exactly\n• Room exists');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Join Room'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.accent2.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.login, color: AppTheme.accent2),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Enter the room details shared with you',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Room ID',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'The unique room identifier',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _roomIdController,
                decoration: const InputDecoration(
                  hintText: 'Enter room ID',
                  prefixIcon: Icon(Icons.tag),
                ),
                validator: Validators.validateRoomId,
                autocorrect: false,
                enableSuggestions: false,
              ),
              const SizedBox(height: 24),
              Text(
                'Secret Word',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'The password for this room',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _secretWordController,
                decoration: const InputDecoration(
                  hintText: 'Enter secret word',
                  prefixIcon: Icon(Icons.key),
                ),
                validator: Validators.validateSecretWord,
                obscureText: true,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: _isJoining ? 'Joining...' : 'Join Room',
                  icon: Icons.login,
                  backgroundColor: AppTheme.accent2,
                  onPressed: _isJoining ? null : _joinRoom,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  '🔒 Your identity stays anonymous',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textColor.withOpacity(0.6),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}