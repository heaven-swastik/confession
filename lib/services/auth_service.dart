import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../utils/helpers.dart';
import 'firestore_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  UserModel? _userModel;

  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isAuthenticated => _user != null;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('first_launch') ?? true;
  }

  Future<void> completeFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_launch', false);
  }

  Future<UserModel?> signInAnonymously() async {
    try {
      final UserCredential userCredential = await _auth.signInAnonymously();
      _user = userCredential.user;

      if (_user != null) {
        // Check if user document exists
        final firestoreService = FirestoreService();
        UserModel? existingUser = await firestoreService.getUser(_user!.uid);

        if (existingUser == null) {
          // Create new user with random username and avatar
          _userModel = UserModel(
            uid: _user!.uid,
            username: Helpers.generateRandomUsername(),
            avatarEmoji: Helpers.getRandomEmoji(),
            createdAt: DateTime.now(),
          );
          await firestoreService.createUser(_userModel!);
        } else {
          _userModel = existingUser;
        }

        notifyListeners();
        return _userModel;
      }
      return null;
    } catch (e) {
      debugPrint('Error signing in anonymously: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
      _userModel = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  Future<void> deleteAccount() async {
    try {
      if (_user != null) {
        final firestoreService = FirestoreService();
        await firestoreService.deleteUser(_user!.uid);
        await _user!.delete();
        _user = null;
        _userModel = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error deleting account: $e');
    }
  }
}
