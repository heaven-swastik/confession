import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class EditRoomNameDialog extends StatefulWidget {
  final String roomId;
  final String currentName;

  const EditRoomNameDialog({
    super.key,
    required this.roomId,
    required this.currentName,
  });

  @override
  State<EditRoomNameDialog> createState() => _EditRoomNameDialogState();
}

class _EditRoomNameDialogState extends State<EditRoomNameDialog> {
  late TextEditingController _controller;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveRoomName() async {
    final newName = _controller.text.trim();
    
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Room name cannot be empty')),
      );
      return;
    }

    if (newName == widget.currentName) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      await firestoreService.updateRoomName(
        roomId: widget.roomId,
        newName: newName,
      );

      if (mounted) {
        Navigator.of(context).pop(newName);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Room name updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Room Name'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 30,
        decoration: InputDecoration(
          labelText: 'Room Name',
          hintText: 'Enter room name',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.accent, width: 2),
          ),
        ),
        onSubmitted: (_) => _saveRoomName(),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveRoomName,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// Helper function to show dialog
Future<void> showEditRoomNameDialog(
  BuildContext context,
  String roomId,
  String currentName,
) async {
  await showDialog(
    context: context,
    builder: (context) => EditRoomNameDialog(
      roomId: roomId,
      currentName: currentName,
    ),
  );
}