import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'music_sync_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MusicSearchSheet extends StatefulWidget {
  final String roomId;
  const MusicSearchSheet({super.key, required this.roomId});

  @override
  State<MusicSearchSheet> createState() => _MusicSearchSheetState();
}

class _MusicSearchSheetState extends State<MusicSearchSheet> {
  final _service = MusicSyncService();
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _results = [];

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _results = [];
    });

    try {
      await _searchWithSaavnMe(query);
    } catch (e) {
      setState(() {
        _error = 'Search failed. Please try again.';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _searchWithSaavnMe(String query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = 'https://saavn.me/search/songs?query=$encodedQuery&limit=20';

      final res = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'Mozilla/5.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);

        List songs = [];

        if (body is Map) {
          songs = body['data']?['results'] ??
              body['results'] ??
              body['data']?['songs'] ??
              body['songs'] ??
              [];
        } else if (body is List) {
          songs = body;
        }

        if (songs.isEmpty) {
          await _searchWithJioSaavnAPI(query);
          return;
        }

        final parsedResults = <Map<String, dynamic>>[];

        for (var song in songs) {
          try {
            String audioUrl = '';

            if (song['downloadUrl'] != null) {
              if (song['downloadUrl'] is List) {
                final urls = song['downloadUrl'] as List;
                if (urls.isNotEmpty) {
                  final lastUrl = urls.last;
                  audioUrl = lastUrl['link'] ?? lastUrl['url'] ?? '';
                }
              } else if (song['downloadUrl'] is String) {
                audioUrl = song['downloadUrl'];
              }
            }

            if (audioUrl.isEmpty) {
              audioUrl = song['url'] ?? song['media_url'] ?? song['perma_url'] ?? '';
            }

            if (audioUrl.isEmpty) continue;

            String imageUrl = '';
            if (song['image'] != null) {
              if (song['image'] is List && (song['image'] as List).isNotEmpty) {
                final imgs = song['image'] as List;
                imageUrl = imgs.last['link'] ?? imgs.last['url'] ?? '';
              } else if (song['image'] is String) {
                imageUrl = song['image'];
              }
            }

            String artist = 'Unknown Artist';
            if (song['primaryArtists'] != null) {
              artist = song['primaryArtists'];
            } else if (song['artists'] != null) {
              if (song['artists'] is Map && song['artists']['primary'] != null) {
                final primaryArtists = song['artists']['primary'];
                if (primaryArtists is List && primaryArtists.isNotEmpty) {
                  artist = primaryArtists[0]['name'] ?? 'Unknown Artist';
                }
              } else if (song['artists'] is String) {
                artist = song['artists'];
              }
            } else if (song['artist'] != null) {
              artist = song['artist'];
            }

            parsedResults.add({
              'id': song['id'] ??
                  song['songId'] ??
                  DateTime.now().millisecondsSinceEpoch.toString(),
              'title': song['name'] ?? song['title'] ?? 'Unknown',
              'artist': artist,
              'image': imageUrl,
              'audioUrl': audioUrl,
            });
          } catch (e) {
            print('Error parsing song: $e');
          }
        }

        if (parsedResults.isEmpty) {
          setState(() => _error = 'No playable songs found');
        } else {
          setState(() => _results = parsedResults);
        }
      } else {
        throw Exception('API returned ${res.statusCode}');
      }
    } catch (e) {
      await _searchWithJioSaavnAPI(query);
    }
  }

  Future<void> _searchWithJioSaavnAPI(String query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url =
          'https://jiosaavn-api-privatecvc2.vercel.app/search/songs?query=$encodedQuery&limit=20';

      final res = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);

        List songs = [];
        if (body is Map) {
          songs = body['data']?['results'] ?? body['results'] ?? [];
        } else if (body is List) {
          songs = body;
        }

        if (songs.isEmpty) {
          setState(() => _error = 'No results found for "$query"');
          return;
        }

        final parsedResults = <Map<String, dynamic>>[];

        for (var song in songs) {
          try {
            String audioUrl = '';

            if (song['downloadUrl'] != null) {
              if (song['downloadUrl'] is List) {
                final urls = song['downloadUrl'] as List;
                if (urls.isNotEmpty) {
                  audioUrl = urls.last['link'] ?? '';
                }
              }
            }

            if (audioUrl.isEmpty) continue;

            String imageUrl = '';
            if (song['image'] != null) {
              if (song['image'] is List && (song['image'] as List).isNotEmpty) {
                imageUrl = (song['image'] as List).last['link'] ?? '';
              } else if (song['image'] is String) {
                imageUrl = song['image'];
              }
            }

            parsedResults.add({
              'id': song['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
              'title': song['name'] ?? song['title'] ?? 'Unknown',
              'artist': song['primaryArtists'] ?? 'Unknown Artist',
              'image': imageUrl,
              'audioUrl': audioUrl,
            });
          } catch (e) {
            print('Error parsing song: $e');
          }
        }

        if (parsedResults.isEmpty) {
          setState(() => _error = 'No playable songs found');
        } else {
          setState(() => _results = parsedResults);
        }
      } else {
        throw Exception('Alternative API failed');
      }
    } catch (e) {
      setState(() => _error = 'No results found. Try a different search.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF575799).withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Search field
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Color(0xFF575799)),
                decoration: InputDecoration(
                  hintText: 'Search songs, artists...',
                  hintStyle: TextStyle(
                    color: const Color(0xFF575799).withOpacity(0.5),
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFFD3C4FF),
                  ),
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear_rounded,
                            color: Color(0xFF575799),
                          ),
                          onPressed: () {
                            _controller.clear();
                            setState(() {
                              _results = [];
                              _error = null;
                            });
                          },
                        )
                      : null,
                ),
                onSubmitted: _search,
                onChanged: (value) => setState(() {}),
                textInputAction: TextInputAction.search,
              ),
            ),

            if (_loading)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFFD3C4FF)),
                      SizedBox(height: 16),
                      Text(
                        'Searching...',
                        style: TextStyle(
                          color: Color(0xFF575799),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (_error != null && !_loading)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFFF6B9D),
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: Color(0xFF575799),
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _search(_controller.text),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD3C4FF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),

            if (!_loading && _error == null)
              Expanded(
                child: _results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.music_note_rounded,
                              size: 80,
                              color: const Color(0xFFD3C4FF).withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Search for songs to play together',
                              style: TextStyle(
                                color: const Color(0xFF575799).withOpacity(0.7),
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final item = _results[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFD3C4FF).withOpacity(0.2),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: item['image'].toString().isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        item['image'],
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFD3C4FF)
                                                .withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.music_note_rounded,
                                            color: Color(0xFFD3C4FF),
                                            size: 32,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD3C4FF).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.music_note_rounded,
                                        color: Color(0xFFD3C4FF),
                                        size: 32,
                                      ),
                                    ),
                              title: Text(
                                item['title'],
                                style: const TextStyle(
                                  color: Color(0xFF575799),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                item['artist'],
                                style: TextStyle(
                                  color: const Color(0xFF575799).withOpacity(0.6),
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFFD3C4FF),
                                      Color(0xFF90D5FF),
                                    ],
                                  ),
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              onTap: () async {
                                try {
                                  final currentUser = FirebaseAuth.instance.currentUser;
                                  if (currentUser == null) {
                                    throw Exception('Not authenticated');
                                  }

                                  await _service.changeSong(
                                    roomId: widget.roomId,
                                    songId: item['id'],
                                    title: item['title'],
                                    audioUrl: item['audioUrl'],
                                    uid: currentUser.uid,
                                  );

                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Now playing: ${item['title']}'),
                                        duration: const Duration(seconds: 2),
                                        backgroundColor: const Color(0xFF95E1D3),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Failed to play song'),
                                        backgroundColor: Color(0xFFFF6B9D),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}