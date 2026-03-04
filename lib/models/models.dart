import 'dart:ui';

// ─────────────────────────────────────────────
//  SERIES MODEL
// ─────────────────────────────────────────────
class Series {
  final String id;
  final String title;
  final String genre;
  final double rating;
  final int episodeCount;
  final String? thumbnailUrl;      // null → gradient placeholder
  final Color bgColor;
  final bool isFeatured;

  const Series({
    required this.id,
    required this.title,
    required this.genre,
    required this.rating,
    required this.episodeCount,
    this.thumbnailUrl,
    required this.bgColor,
    this.isFeatured = false,
  });

  /// Build from a JSON map returned by your REST API.
  factory Series.fromJson(Map<String, dynamic> json) => Series(
    id:           json['id'] as String,
    title:        json['title'] as String,
    genre:        json['genre'] as String,
    rating:       (json['rating'] as num).toDouble(),
    episodeCount: json['episode_count'] as int,
    thumbnailUrl: json['thumbnail_url'] as String?,
    bgColor:      Color(int.parse(
      (json['bg_color'] as String? ?? 'FF1A0533').replaceFirst('#', 'FF'),
      radix: 16,
    )),
    isFeatured:   json['is_featured'] as bool? ?? false,
  );
}

// ─────────────────────────────────────────────
//  EPISODE MODEL
// ─────────────────────────────────────────────
class Episode {
  final String id;
  final int number;
  final int season;
  final String title;
  final String duration;        // e.g. "24m"
  final String views;           // e.g. "1.4M"
  final String videoUrl;
  final Color bgColor;

  const Episode({
    required this.id,
    required this.number,
    required this.season,
    required this.title,
    required this.duration,
    required this.views,
    required this.videoUrl,
    required this.bgColor,
  });

  factory Episode.fromJson(Map<String, dynamic> json) => Episode(
    id:       json['id'] as String,
    number:   json['number'] as int,
    season:   json['season'] as int,
    title:    json['title'] as String,
    duration: json['duration'] as String,
    views:    json['views'] as String,
    videoUrl: json['video_url'] as String,
    bgColor:  Color(int.parse(
      (json['bg_color'] as String? ?? 'FF1A0533').replaceFirst('#', 'FF'),
      radix: 16,
    )),
  );
}

// ─────────────────────────────────────────────
//  CONTINUE WATCHING MODEL
// ─────────────────────────────────────────────
class ContinueWatchingItem {
  final String seriesId;
  final String seriesTitle;
  final String episodeLabel;    // e.g. "S2 E7"
  final int episodeIndex;       // 0-based index into episode list
  final double progress;        // 0.0 – 1.0
  final Color bgColor;

  const ContinueWatchingItem({
    required this.seriesId,
    required this.seriesTitle,
    required this.episodeLabel,
    required this.episodeIndex,
    required this.progress,
    required this.bgColor,
  });

  factory ContinueWatchingItem.fromJson(Map<String, dynamic> json) =>
      ContinueWatchingItem(
        seriesId:     json['series_id'] as String,
        seriesTitle:  json['series_title'] as String,
        episodeLabel: json['episode_label'] as String,
        episodeIndex: json['episode_index'] as int,
        progress:     (json['progress'] as num).toDouble(),
        bgColor: Color(int.parse(
          (json['bg_color'] as String? ?? 'FF1A0533').replaceFirst('#', 'FF'),
          radix: 16,
        )),
      );
}

// ─────────────────────────────────────────────
//  POINTS PACKAGE MODEL
// ─────────────────────────────────────────────
class PointsPackage {
  final String id;
  final int points;
  final String price;
  final bool isBestValue;

  const PointsPackage({
    required this.id,
    required this.points,
    required this.price,
    this.isBestValue = false,
  });
}

/// Hard-coded store catalogue (swap for API call when ready).
const kPointsPackages = [
  PointsPackage(id: 'p5',  points: 5,  price: r'$0.49'),
  PointsPackage(id: 'p10', points: 10, price: r'$0.99', isBestValue: true),
  PointsPackage(id: 'p25', points: 25, price: r'$1.99'),
  PointsPackage(id: 'p50', points: 50, price: r'$3.49'),
];