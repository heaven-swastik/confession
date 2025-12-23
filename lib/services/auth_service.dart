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

  // Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final firestoreService = FirestoreService();
      return await firestoreService.isUsernameAvailable(username);
    } catch (e) {
      debugPrint('Error checking username: $e');
      return false;
    }
  }

  // Create user with custom username
  Future<UserModel?> createUserWithUsername({
    required String username,
    required String avatarEmoji,
  }) async {
    try {
      // Check if username is available
      final available = await isUsernameAvailable(username);
      if (!available) {
        debugPrint('Username not available: $username');
        return null;
      }

      // Create anonymous user
      final UserCredential userCredential = await _auth.signInAnonymously();
      _user = userCredential.user;

      if (_user != null) {
        _userModel = UserModel(
          uid: _user!.uid,
          username: username,
          avatarEmoji: avatarEmoji,
          createdAt: DateTime.now(),
        );

        final firestoreService = FirestoreService();
        await firestoreService.createUser(_userModel!);
        await firestoreService.reserveUsername(
          username: username,
          uid: _user!.uid,
        );

        notifyListeners();
        return _userModel;
      }
      return null;
    } catch (e) {
      debugPrint('Error creating user with username: $e');
      return null;
    }
  }

  // Sign in anonymously with random username (fallback)
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

  // Update username
  Future<bool> updateUsername(String newUsername) async {
    try {
      if (_user == null || _userModel == null) return false;

      // Check if new username is available
      if (_userModel!.username != newUsername) {
        final available = await isUsernameAvailable(newUsername);
        if (!available) {
          debugPrint('Username not available: $newUsername');
          return false;
        }
      }

      final firestoreService = FirestoreService();
      
      // Release old username
      await firestoreService.releaseUsername(_userModel!.username);
      
      // Update user model
      _userModel = _userModel!.copyWith(username: newUsername);
      await firestoreService.updateUser(_userModel!);
      
      // Reserve new username
      await firestoreService.reserveUsername(
        username: newUsername,
        uid: _user!.uid,
      );

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating username: $e');
      return false;
    }
  }

  // Update Spotify tokens
  Future<void> updateSpotifyTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      if (_user == null || _userModel == null) return;

      final firestoreService = FirestoreService();
      await firestoreService.updateUserSpotifyTokens(
        uid: _user!.uid,
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      _userModel = _userModel!.copyWith(
        spotifyAccessToken: accessToken,
        spotifyRefreshToken: refreshToken,
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating Spotify tokens: $e');
    }
  }

  // Update current track
  Future<void> updateCurrentTrack(String? trackUri) async {
    try {
      if (_user == null || _userModel == null) return;

      final firestoreService = FirestoreService();
      await firestoreService.updateCurrentTrack(
        uid: _user!.uid,
        trackUri: trackUri,
      );

      _userModel = _userModel!.copyWith(currentTrackUri: trackUri);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating current track: $e');
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
      if (_user != null && _userModel != null) {
        final firestoreService = FirestoreService();
        
        // Release username
        await firestoreService.releaseUsername(_userModel!.username);
        
        // Delete user document
        await firestoreService.deleteUser(_user!.uid);
        
        // Delete auth user
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