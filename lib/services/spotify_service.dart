import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Simple Spotify service without SDK
/// Opens Spotify in browser/app instead of embedding player
class SpotifyService {
  bool _isConnected = false;
  String? _currentTrackUri;

  bool get isConnected => _isConnected;
  String? get currentTrackUri => _currentTrackUri;

  /// Open Spotify app or web player
  Future<bool> connectSpotify() async {
    try {
      // Try to open Spotify app
      final uri = Uri.parse('spotify://');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        _isConnected = true;
        return true;
      } else {
        // Fall back to web player
        final webUri = Uri.parse('https://open.spotify.com/');
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
        _isConnected = true;
        return true;
      }
    } catch (e) {
      debugPrint('Error opening Spotify: $e');
      return false;
    }
  }

  /// Disconnect (just a state change)
  Future<void> disconnectSpotify() async {
    _isConnected = false;
    _currentTrackUri = null;
    debugPrint('Spotify disconnected');
  }

  /// Get current track - NOT AVAILABLE without SDK
  /// User will need to manually share track links
  Future<Map<String, String>?> getCurrentTrack() async {
    debugPrint('Getting current track not available without Spotify SDK');
    debugPrint('User should manually share Spotify track links');
    return null;
  }

  /// Open a specific track in Spotify
  Future<bool> playTrack(String trackUri) async {
    try {
      // Convert spotify:track:xxx to spotify://track/xxx
      final uri = Uri.parse(trackUri.replaceFirst('spotify:track:', 'spotify://track/'));
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        _currentTrackUri = trackUri;
        return true;
      } else {
        // Fall back to web
        final webUrl = trackUri.replaceFirst('spotify:track:', 'https://open.spotify.com/track/');
        final webUri = Uri.parse(webUrl);
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
        _currentTrackUri = trackUri;
        return true;
      }
    } catch (e) {
      debugPrint('Error playing track: $e');
      return false;
    }
  }

  /// Open Spotify app or web
  Future<void> openSpotifyAppOrWeb() async {
    try {
      final uri = Uri.parse('spotify://');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        final webUri = Uri.parse('https://open.spotify.com/');
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error opening Spotify: $e');
    }
  }

  /// Parse Spotify link and extract track URI
  /// Example: https://open.spotify.com/track/3n3Ppam7vgaVa1iaRUc9Lp?si=xxx
  /// Returns: spotify:track:3n3Ppam7vgaVa1iaRUc9Lp
  String? parseSpotifyLink(String link) {
    try {
      if (link.contains('spotify.com/track/')) {
        final trackId = link.split('/track/')[1].split('?')[0];
        return 'spotify:track:$trackId';
      } else if (link.startsWith('spotify:track:')) {
        return link;
      }
      return null;
    } catch (e) {
      debugPrint('Error parsing Spotify link: $e');
      return null;
    }
  }

  /// Get track name from URI (would need API call in real implementation)
  /// For now, just returns a placeholder
  String getTrackNameFromUri(String trackUri) {
    final trackId = trackUri.replaceFirst('spotify:track:', '');
    return 'Spotify Track ($trackId)';
  }
}