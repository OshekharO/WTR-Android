import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:logger/logger.dart';

import '../models/chapter_item.dart';
import '../models/content_details.dart';
import '../models/content_item.dart';
import '../models/content_source.dart';

/// AsuraScans-backed manga / manhwa source.
class MangaSource implements ContentSource {
  MangaSource({Dio? dio, Logger? logger})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: _baseUrl,
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 45),
                sendTimeout: const Duration(seconds: 30),
                headers: const {
                  'Accept': 'application/json, text/html, */*',
                  'User-Agent':
                      'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 '
                          '(KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36',
                },
              ),
            ),
        _log = logger ?? Logger() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          _log.i('→ Manga ${options.method} ${options.uri}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          _log.i('← ${response.statusCode} ${response.requestOptions.path}');
          handler.next(response);
        },
        onError: (error, handler) {
          _log.w('⛔ Manga API error ${error.requestOptions.path}', error: error);
          handler.next(error);
        },
      ),
    );
  }

  static const _baseUrl = 'https://api.asurascans.com';

  final Dio _dio;
  final Logger _log;
  final Map<int, String> _publicRouteById = {};
  final Map<String, String> _publicRouteBySlug = {};

  @override
  String get id => 'asura_manga';

  @override
  String get name => 'AsuraScans Manga';

  @override
  String get description => 'AsuraScans manga source';

  @override
  SourceType get type => SourceType.manga;

  @override
  String get baseUrl => _baseUrl;

  @override
  String? get iconAsset => null;

  @override
  Future<List<ContentItem>> getHome() async => getPopular(limit: 20);

  Future<List<ContentItem>> getPopular({int limit = 20}) async {
    try {
      final res = await _dio.get(
        '/api/series',
        queryParameters: {
          'sort': 'popular',
          'order': 'desc',
          'limit': limit,
          'offset': 0,
        },
      );
      return _parseSeriesList(res.data, limit: limit);
    } on DioException catch (e) {
      _log.w('MangaSource.getPopular failed', error: e);
      return const [];
    } catch (e) {
      _log.e('MangaSource.getPopular unexpected error', error: e);
      return const [];
    }
  }

  Future<List<ContentItem>> getTrending({
    required String period,
    int limit = 10,
  }) async {
    try {
      final res = await _dio.get(
        '/api/trending/$period',
        queryParameters: {'limit': limit},
      );
      return _parseSeriesList(res.data, limit: limit);
    } on DioException catch (e) {
      _log.w('MangaSource.getTrending($period) failed', error: e);
      return const [];
    } catch (e) {
      _log.e('MangaSource.getTrending($period) unexpected error', error: e);
      return const [];
    }
  }

  @override
  Future<List<ContentItem>> search(String query) async {
    if (query.trim().isEmpty) return const [];
    try {
      final res = await _dio.get(
        '/api/search',
        queryParameters: {'q': query.trim()},
      );
      return _parseSeriesList(res.data, limit: 20);
    } on DioException catch (e) {
      _log.w('MangaSource.search failed', error: e);
      return const [];
    } catch (e) {
      _log.e('MangaSource.search unexpected error', error: e);
      return const [];
    }
  }

  @override
  Future<ContentDetails> getDetails(ContentItem item) async {
    try {
      final slug = item.slug ?? _slugify(item.title);
      final res = await _dio.get('/api/series/$slug');
      final payload = _decode(res.data);
      final series = _asMap(payload['series']);
      if (series.isEmpty) return ContentDetails.fromItem(item);
      return _detailsFromSeries(series, item);
    } on DioException catch (e) {
      _log.w('MangaSource.getDetails failed', error: e);
      return ContentDetails.fromItem(item);
    } catch (e) {
      _log.e('MangaSource.getDetails unexpected error', error: e);
      return ContentDetails.fromItem(item);
    }
  }

  @override
  Future<List<ChapterItem>> getChapters(ContentItem item) async {
    try {
      final slug = item.slug ?? _slugify(item.title);
      final res = await _dio.get('/api/series/$slug/chapters');
      final chapters = _extractList(_decode(res.data));
      return chapters
          .whereType<Map<String, dynamic>>()
          .map((chapter) => ChapterItem(
                id: int.tryParse('${chapter['id'] ?? 0}') ?? 0,
                number: int.tryParse('${chapter['number'] ?? 1}') ?? 1,
                title: 'Chapter ${chapter['number'] ?? 1}',
                updatedAt: DateTime.tryParse('${chapter['published_at'] ?? ''}'),
              ))
          .toList(growable: false);
    } on DioException catch (e) {
      _log.w('MangaSource.getChapters failed', error: e);
      return const [];
    } catch (e) {
      _log.e('MangaSource.getChapters unexpected error', error: e);
      return const [];
    }
  }

  @override
  Future<String> getChapterContent({
    required ContentItem item,
    required int chapterId,
    required int chapterNo,
  }) async =>
      'Manga chapters are rendered as images.';

  @override
  Future<List<String>> getChapterImages({
    required ContentItem item,
    required int chapterId,
    required int chapterNo,
  }) async {
    try {
      final slug = item.slug ?? _slugify(item.title);
      final res = await _dio.get(
        '/api/series/$slug/chapters/$chapterNo',
      );
      final payload = _decode(res.data);
      final chapter = _asMap(_asMap(payload)['data'])['chapter'];
      final pages = _asMap(chapter)['pages'];
      if (pages is! List) return const [];

      return pages
          .whereType<Map<String, dynamic>>()
          .map((page) => _proxiedImageUrl('${page['url'] ?? ''}'.trim()))
          .where((url) => url.isNotEmpty)
          .toList(growable: false);
    } on DioException catch (e) {
      _log.w('MangaSource.getChapterImages failed', error: e);
      return const [];
    } catch (e) {
      _log.e('MangaSource.getChapterImages unexpected error', error: e);
      return const [];
    }
  }

  @override
  Future<String?> getEpisodeUrl({
    required ContentItem item,
    required int episodeId,
    required int episodeNo,
  }) async =>
      null;

  List<ContentItem> _parseSeriesList(dynamic data, {int limit = 20}) {
    final items = _extractList(_decode(data));
    return items
        .whereType<Map<String, dynamic>>()
        .map(_itemFromSeries)
        .take(limit)
        .toList(growable: false);
  }

  ContentItem _itemFromSeries(Map<String, dynamic> json) {
    _cacheRoute(json);
    final description = _stripHtml('${json['description'] ?? ''}');
    final author = '${json['author'] ?? json['artist'] ?? 'Unknown'}';
    final rating = json['rating'];
    final chapters = json['chapter_count'] ?? json['chapterCount'];
    final status = '${json['status'] ?? ''}';
    final type = '${json['type'] ?? ''}';

    return ContentItem(
      id: int.tryParse('${json['id'] ?? 0}') ?? 0,
      rawId: int.tryParse('${json['id'] ?? 0}'),
      slug: '${json['slug'] ?? ''}'.trim().isEmpty ? null : '${json['slug']}',
      title: '${json['title'] ?? 'Untitled'}',
      author: author,
      description: description.isEmpty
          ? '$type $status${rating == null ? '' : ' • Rating $rating'}'
          : description,
      coverUrl: json['cover_url']?.toString() ?? json['cover']?.toString(),
      chapterCount: int.tryParse('${chapters ?? 0}') ?? 0,
      sourceId: id,
    );
  }

  ContentDetails _detailsFromSeries(Map<String, dynamic> series, ContentItem fallback) {
    _cacheRoute(series);
    final item = _itemFromSeries(series).copyWith(sourceId: id);
    final latestChapters =
        (series['latest_chapters'] is List ? series['latest_chapters'] as List : const [])
            .whereType<Map<String, dynamic>>()
            .map(
              (chapter) => ChapterItem(
                id: int.tryParse('${chapter['id'] ?? 0}') ?? 0,
                number: int.tryParse('${chapter['number'] ?? 0}') ?? 0,
                title: 'Chapter ${chapter['number'] ?? 0}',
                updatedAt: DateTime.tryParse('${chapter['published_at'] ?? ''}'),
              ),
            )
            .toList(growable: false);

    final genres = (series['genres'] is List ? series['genres'] as List : const [])
        .whereType<Map<String, dynamic>>()
        .map((genre) => '${genre['name'] ?? ''}')
        .where((genre) => genre.trim().isNotEmpty)
        .toList(growable: false);

    return ContentDetails(
      item: item,
      description: _stripHtml('${series['description'] ?? fallback.description}'),
      rawTitle: '${series['title'] ?? item.title}',
      rawAuthor: '${series['author'] ?? item.author}',
      rawDescription: _stripHtml('${series['description'] ?? ''}'),
      chapterCount: int.tryParse('${series['chapter_count'] ?? 0}') ?? 0,
      viewCount: int.tryParse('${series['bookmark_count'] ?? 0}') ?? 0,
      rating: double.tryParse('${series['rating'] ?? 0}') ?? 0,
      tags: genres,
      latestChapters: latestChapters,
      extraFields: {
        if (series['status'] != null) 'Status': '${series['status']}',
        if (series['type'] != null) 'Type': '${series['type']}',
        if (series['popularity_rank'] != null) 'Popular Rank': '#${series['popularity_rank']}',
      },
    );
  }

  String _proxiedImageUrl(String url) {
    if (url.isEmpty || !kIsWeb) return url;
    return 'https://wsrv.nl/?url=${Uri.encodeComponent(url)}';
  }

  String? _publicRouteFor(ContentItem item) {
    return _publicRouteById[item.id] ??
        (item.slug == null ? null : _publicRouteBySlug[item.slug!]);
  }

  void _cacheRoute(Map<String, dynamic> json) {
    final id = int.tryParse('${json['id'] ?? 0}') ?? 0;
    final slug = '${json['slug'] ?? ''}'.trim();
    final publicUrl = '${json['public_url'] ?? ''}'.trim();
    final route = publicUrl.contains('/comics/')
        ? publicUrl.split('/comics/').last.replaceAll(RegExp(r'^/+|/+$'), '')
        : '';

    if (id != 0 && route.isNotEmpty) {
      _publicRouteById[id] = route;
    }
    if (slug.isNotEmpty && route.isNotEmpty) {
      _publicRouteBySlug[slug] = route;
    }
  }

  dynamic _decode(dynamic data) {
    if (data is String) {
      try {
        return jsonDecode(data);
      } catch (_) {
        return data;
      }
    }
    return data;
  }

  List<dynamic> _extractList(dynamic value) {
    if (value is List) return value;
    if (value is Map<String, dynamic>) {
      for (final key in ['data', 'results', 'series', 'recommended_series']) {
        if (value[key] is List) return value[key] as List;
      }
      for (final nested in value.values) {
        final list = _extractList(nested);
        if (list.isNotEmpty) return list;
      }
    }
    return const [];
  }

  Map<String, dynamic> _asMap(dynamic value) =>
      value is Map<String, dynamic> ? value : const <String, dynamic>{};

  String _stripHtml(String value) =>
      value.replaceAll(RegExp(r'<[^>]+>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  String _slugify(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}
