import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';

// ─────────────────────────────────────────────
//  CONFIG  ← change baseUrl to your server
// ─────────────────────────────────────────────
class ApiConfig {
  static const baseUrl = 'https://api.yourapp.com/v1';  // ← replace
  static const timeout = Duration(seconds: 15);
}

// ─────────────────────────────────────────────
//  API SERVICE
// ─────────────────────────────────────────────
class ApiService {
  ApiService._();
  static final instance = ApiService._();

  final _client = http.Client();

  // ── Headers (add auth token here) ─────────
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    // 'Authorization': 'Bearer $token',   // ← uncomment when auth is ready
  };

  // ── Generic GET helper ────────────────────
  Future<dynamic> _get(String path) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final res  = await _client.get(uri, headers: _headers).timeout(ApiConfig.timeout);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw ApiException(res.statusCode, res.body);
  }

  // ──────────────────────────────────────────
  //  SERIES ENDPOINTS
  // ──────────────────────────────────────────

  /// Fetch the featured series for the hero banner.
  Future<Series> fetchFeaturedSeries() async {
    // TODO: uncomment when API is live:
    // final data = await _get('/series/featured');
    // return Series.fromJson(data as Map<String, dynamic>);

    // ← mock fallback while API is not connected
    await Future.delayed(const Duration(milliseconds: 600));
    return const Series(
      id: 'series_1',
      title: 'Neon Abyss',
      genre: 'Sci-Fi',
      rating: 9.4,
      episodeCount: 24,
      bgColor: Color(0xFF1A0533),
      isFeatured: true,
    );
  }

  /// Fetch top 10 series list.
  Future<List<Series>> fetchTop10() async {
    // TODO: final data = await _get('/series/top10');
    // return (data as List).map((e) => Series.fromJson(e)).toList();
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockSeriesList;
  }

  /// Fetch new releases.
  Future<List<Series>> fetchNewReleases() async {
    // TODO: final data = await _get('/series/new');
    // return (data as List).map((e) => Series.fromJson(e)).toList();
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockSeriesList.reversed.toList();
  }

  /// Fetch series by category/genre.
  Future<List<Series>> fetchByCategory(String category) async {
    // TODO: final data = await _get('/series?genre=${Uri.encodeComponent(category)}');
    // return (data as List).map((e) => Series.fromJson(e)).toList();
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockSeriesList;
  }

  // ──────────────────────────────────────────
  //  EPISODE ENDPOINTS
  // ──────────────────────────────────────────

  /// Fetch all episodes for a series.
  Future<List<Episode>> fetchEpisodes(String seriesId) async {
    // TODO: final data = await _get('/series/$seriesId/episodes');
    // return (data as List).map((e) => Episode.fromJson(e)).toList();
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockEpisodes;
  }

  // ──────────────────────────────────────────
  //  USER / WATCHLIST ENDPOINTS
  // ──────────────────────────────────────────

  /// Fetch the user's continue-watching list.
  Future<List<ContinueWatchingItem>> fetchContinueWatching() async {
    // TODO: final data = await _get('/user/continue-watching');
    // return (data as List).map((e) => ContinueWatchingItem.fromJson(e)).toList();
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockContinueWatching;
  }

  /// Fetch the user's watchlist (bookmarked series).
  Future<List<Series>> fetchWatchlist() async {
    // TODO: final data = await _get('/user/watchlist');
    // return (data as List).map((e) => Series.fromJson(e)).toList();
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockSeriesList.take(3).toList();
  }

  /// Add a series to the watchlist.
  Future<void> addToWatchlist(String seriesId) async {
    // TODO: await _client.post(Uri.parse('${ApiConfig.baseUrl}/user/watchlist'),
    //   headers: _headers, body: jsonEncode({'series_id': seriesId}));
    await Future.delayed(const Duration(milliseconds: 200));
  }

  /// Remove a series from the watchlist.
  Future<void> removeFromWatchlist(String seriesId) async {
    // TODO: await _client.delete(Uri.parse('${ApiConfig.baseUrl}/user/watchlist/$seriesId'),
    //   headers: _headers);
    await Future.delayed(const Duration(milliseconds: 200));
  }

  /// Search for series by query string.
  Future<List<Series>> search(String query) async {
    // TODO: final data = await _get('/search?q=${Uri.encodeComponent(query)}');
    // return (data as List).map((e) => Series.fromJson(e)).toList();
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockSeriesList
        .where((s) => s.title.toLowerCase().contains(query.toLowerCase()) ||
        s.genre.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}

// ─────────────────────────────────────────────
//  API EXCEPTION
// ─────────────────────────────────────────────
class ApiException implements Exception {
  final int statusCode;
  final String body;
  ApiException(this.statusCode, this.body);

  @override
  String toString() => 'ApiException($statusCode): $body';
}

// ─────────────────────────────────────────────
//  MOCK DATA  (delete when API is live)
// ─────────────────────────────────────────────
final _mockSeriesList = [
  const Series(id: 'series_1', title: 'Neon Abyss',   genre: 'Sci-Fi',   rating: 9.4, episodeCount: 24, bgColor: Color(0xFF1A0533)),
  const Series(id: 'series_2', title: 'Iron Veil',    genre: 'Action',   rating: 9.1, episodeCount: 18, bgColor: Color(0xFF1A1500)),
  const Series(id: 'series_3', title: 'Crimson Hour', genre: 'Thriller', rating: 8.9, episodeCount: 12, bgColor: Color(0xFF1A0000)),
  const Series(id: 'series_4', title: 'Silent Shore', genre: 'Drama',    rating: 8.7, episodeCount: 30, bgColor: Color(0xFF001A1A)),
  const Series(id: 'series_5', title: 'Phantom Gate', genre: 'Horror',   rating: 8.5, episodeCount: 10, bgColor: Color(0xFF0D001A)),
];

final _mockContinueWatching = [
  const ContinueWatchingItem(seriesId: 'series_1', seriesTitle: 'Neon Abyss',   episodeLabel: 'S2 E7',  episodeIndex: 6,  progress: 0.65, bgColor: Color(0xFF1A0533)),
  const ContinueWatchingItem(seriesId: 'series_2', seriesTitle: 'Iron Veil',    episodeLabel: 'S1 E4',  episodeIndex: 3,  progress: 0.30, bgColor: Color(0xFF1A1500)),
  const ContinueWatchingItem(seriesId: 'series_3', seriesTitle: 'Crimson Hour', episodeLabel: 'S1 E11', episodeIndex: 10, progress: 0.85, bgColor: Color(0xFF1A0000)),
];

const _sampleUrls = [
  'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
  'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
  'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
  'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
  'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackOnStreetAndDirt.mp4',
];

final _mockEpisodes = List.generate(10, (i) {
  const titles = [
    'Into the Void', 'Dark Frequencies', 'Neon Shadows',
    'The Last Signal', 'Static Dreams', 'Broken Protocol',
    'Zero Hour', 'Phantom Circuit', 'The Forgotten Layer', 'Terminal Drift',
  ];
  const colors = [
    Color(0xFF1A0533), Color(0xFF0D1A05), Color(0xFF1A0000),
    Color(0xFF001A18), Color(0xFF1A1000),
  ];
  return Episode(
    id:       'ep_${i + 1}',
    number:   i + 1,
    season:   1,
    title:    titles[i % titles.length],
    duration: '${22 + (i % 8)}m',
    views:    '${(1.2 + i * 0.3).toStringAsFixed(1)}M',
    videoUrl: _sampleUrls[i % _sampleUrls.length],
    bgColor:  colors[i % colors.length],
  );
});