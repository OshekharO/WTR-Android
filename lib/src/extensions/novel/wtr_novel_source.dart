import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../core/network/dio_client.dart';
import '../models/chapter_item.dart';
import '../models/content_details.dart';
import '../models/content_item.dart';
import '../models/content_source.dart';

/// WTR-Lab novel source — wraps the existing WTR API.
/// All requests go through the CORS proxy via [WtrProxyClient].
class WtrNovelSource implements ContentSource {
  WtrNovelSource({WtrProxyClient? client, Logger? logger})
      : _client = client ?? WtrProxyClient(),
        _log = logger ?? Logger();

  final WtrProxyClient _client;
  final Logger _log;

  // ── ContentSource identity ────────────────────────────────────────────────

  @override
  String get id => 'wtr_novel';

  @override
  String get name => 'WTR Novels';

  @override
  String get description => 'Web novel translations via wtr-lab.com';

  @override
  SourceType get type => SourceType.novel;

  @override
  String get baseUrl => 'https://wtr-lab.com';

  @override
  String? get iconAsset => null;

  // ── Home ──────────────────────────────────────────────────────────────────

  @override
  Future<List<ContentItem>> getHome() async {
    try {
      return getRanking(type: 'weekly', limit: 20);
    } on DioException catch (e) {
      _log.w('WtrNovelSource.getHome failed', error: e);
      return _demoItems;
    } catch (e) {
      _log.e('WtrNovelSource.getHome unexpected error', error: e);
      return _demoItems;
    }
  }

  Future<List<ContentItem>> getLatest({int page = 1, int limit = 10}) async {
    try {
      final res = await _client.get(
        '/_next/data/4VGoIyKJTGgGftVZVdBYc/en/novel-list.json',
        queryParameters: {'page': page, 'locale': 'en'},
      );
      return _parseLatestItemList(res.data, limit: limit);
    } on DioException catch (e) {
      _log.w('WtrNovelSource.getLatest failed', error: e);
      return _demoItems.take(limit).toList(growable: false);
    } catch (e) {
      _log.e('WtrNovelSource.getLatest unexpected error', error: e);
      return _demoItems.take(limit).toList(growable: false);
    }
  }

  Future<List<ContentItem>> getRanking({
    required String type,
    int limit = 10,
  }) async {
    try {
      final res = await _client.get(
        '/api/serie/ranking',
        queryParameters: {'type': type, 'limit': limit},
      );
      return _parseItemList(res.data).take(limit).toList(growable: false);
    } on DioException catch (e) {
      _log.w('WtrNovelSource.getRanking($type) failed', error: e);
      return _demoItems.take(limit).toList(growable: false);
    } catch (e) {
      _log.e('WtrNovelSource.getRanking($type) unexpected error', error: e);
      return _demoItems.take(limit).toList(growable: false);
    }
  }

  // ── Search ────────────────────────────────────────────────────────────────

  @override
  Future<List<ContentItem>> search(String query) async {
    if (query.trim().isEmpty) return const [];
    try {
      final res = await _client.post(
        path: '/api/search',
        body: {'text': query},
      );
      return _parseItemList(res.data);
    } on DioException catch (e) {
      _log.w('WtrNovelSource.search failed', error: e);
      return const [];
    } catch (e) {
      _log.e('WtrNovelSource.search unexpected error', error: e);
      return const [];
    }
  }

  // ── Details ───────────────────────────────────────────────────────────────

  @override
  Future<ContentDetails> getDetails(ContentItem item) async {
    try {
      final rawId = item.rawId ?? item.id;
      final slug = item.slug ?? _slugify(item.title);
      final res = await _client.get(
        '/en/novel/$rawId/$slug',
        responseType: ResponseType.plain,
      );
      final html = res.data is String ? res.data as String : '${res.data}';
      return _parseHtmlDetails(html, item);
    } on DioException catch (e) {
      _log.w('WtrNovelSource.getDetails failed', error: e);
      return ContentDetails.fromItem(item);
    } catch (e) {
      _log.e('WtrNovelSource.getDetails unexpected error', error: e);
      return ContentDetails.fromItem(item);
    }
  }

  // ── Chapters ──────────────────────────────────────────────────────────────

  @override
  Future<List<ChapterItem>> getChapters(ContentItem item) async {
    final bookId = item.rawId ?? item.id;
    final end = item.chapterCount ?? 61;
    try {
      final res = await _client.get(
        '/api/chapters/$bookId',
        queryParameters: {'start': 1, 'end': end},
      );
      final data = res.data;
      final list = data is List
          ? data
          : (data['data'] ?? data['chapters'] ?? []) as List;
      return list
          .map((e) => ChapterItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      _log.w('WtrNovelSource.getChapters failed', error: e);
      return _demoChapters(bookId);
    } catch (e) {
      _log.e('WtrNovelSource.getChapters unexpected error', error: e);
      return _demoChapters(bookId);
    }
  }

  // ── Chapter content ───────────────────────────────────────────────────────

  @override
  Future<String> getChapterContent({
    required ContentItem item,
    required int chapterId,
    required int chapterNo,
  }) async {
    try {
      final res = await _client.post(
        path: '/api/reader/get',
        body: {
          'translate': 'ai',
          'language': 'en',
          'raw_id': item.rawId ?? item.id,
          'chapter_no': chapterNo,
          'retry': false,
          'force_retry': false,
          'chapter_id': chapterId,
        },
      );
      return _extractText(res.data);
    } on DioException catch (e) {
      _log.w('WtrNovelSource.getChapterContent failed', error: e);
      return 'Chapter $chapterNo\n\nContent unavailable right now.';
    } catch (e) {
      _log.e('WtrNovelSource.getChapterContent unexpected error', error: e);
      return 'Chapter $chapterNo\n\nContent unavailable right now.';
    }
  }

  // ── Manga images / Anime episode (not applicable for novels) ─────────────

  @override
  Future<List<String>> getChapterImages({
    required ContentItem item,
    required int chapterId,
    required int chapterNo,
  }) async =>
      const [];

  @override
  Future<String?> getEpisodeUrl({
    required ContentItem item,
    required int episodeId,
    required int episodeNo,
  }) async =>
      null;

  // ── Parsers ───────────────────────────────────────────────────────────────

  List<ContentItem> _parseItemList(dynamic data) {
    dynamic resolved = data;
    if (resolved is String) {
      try {
        resolved = jsonDecode(resolved);
      } catch (_) {
        return const [];
      }
    }

    final items = _extractList(resolved);
    return items
        .whereType<Map<String, dynamic>>()
        .map(_itemFromJson)
        .toList(growable: false);
  }

  List<ContentItem> _parseLatestItemList(dynamic data, {int limit = 10}) {
    dynamic resolved = data;
    if (resolved is String) {
      try {
        resolved = jsonDecode(resolved);
      } catch (_) {
        return const [];
      }
    }

    final series = _dig(resolved, ['pageProps', 'series']);
    final items = series is List
      ? series
      : series is Map<String, dynamic>
        ? (series['data'] ?? series['items'] ?? series['series'])
        : null;

    if (items is! List) return const [];

    return items
      .whereType<Map<String, dynamic>>()
      .map(_itemFromJson)
      .take(limit)
      .toList(growable: false);
  }

  dynamic _dig(dynamic value, List<String> keys) {
    dynamic current = value;
    for (final key in keys) {
      if (current is Map<String, dynamic>) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current;
  }

  List<dynamic> _extractList(dynamic value) {
    if (value is List) return value;
    if (value is Map<String, dynamic>) {
      for (final key in ['data', 'books', 'results', 'items', 'series']) {
        if (value.containsKey(key) && value[key] is List) {
          return value[key] as List;
        }
      }
      for (final v in value.values) {
        final nested = _extractList(v);
        if (nested.isNotEmpty) return nested;
      }
    }
    return const [];
  }

  ContentItem _itemFromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final payload = data is Map<String, dynamic> ? data : <String, dynamic>{};
    final resolvedRawId = int.tryParse(
            '${json['raw_id'] ?? payload['raw_id'] ?? json['id'] ?? payload['id'] ?? 0}') ??
        0;
    final slugValue = json['slug'] ?? payload['slug'];

    return ContentItem(
      id: int.tryParse('${json['id'] ?? payload['id'] ?? resolvedRawId}') ?? 0,
      rawId: resolvedRawId == 0 ? null : resolvedRawId,
      slug: slugValue == null || '$slugValue'.trim().isEmpty
          ? null
          : '$slugValue',
      title:
          '${payload['title'] ?? json['title'] ?? json['name'] ?? 'Untitled'}',
      author: '${payload['author'] ?? json['author'] ?? 'Unknown'}',
      description:
          '${payload['description'] ?? json['description'] ?? json['desc'] ?? 'No description available.'}',
        coverUrl: _maybeProxyUrl(json['image']?.toString() ??
          payload['image']?.toString() ??
          json['cover']?.toString() ??
          json['cover_url']?.toString()),
      chapterCount: int.tryParse(
              '${json['chapter_count'] ?? json['raw_chapter_count'] ?? payload['chapter_count'] ?? payload['raw_chapter_count'] ?? 0}') ??
          0,
      sourceId: id,
    );
  }

  /// If running on web, rewrite `url` to route through the CORS proxy so
  /// browser image requests aren't blocked by remote CDN CORS policies.
  /// On native platforms the original URL is returned unchanged.
  String? _maybeProxyUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    if (!kIsWeb) return url;
    // Use the same proxy host as the API client. The proxy expects a `url`
    // query parameter for GET passthrough (works with the deployed proxy).
    final proxied = 'https://cors-bypasser-pro.vercel.app/proxy?url=${Uri.encodeComponent(url)}';
    return proxied;
  }

  ContentDetails _parseHtmlDetails(String html, ContentItem fallback) {
    final match = RegExp(
      r'<script id="__NEXT_DATA__" type="application/json">(.*?)</script>',
      dotAll: true,
    ).firstMatch(html);
    if (match == null) return ContentDetails.fromItem(fallback);

    try {
      final payload = jsonDecode(match.group(1)!) as Map<String, dynamic>;
      final serieData =
          _dig(payload, ['props', 'pageProps', 'serie', 'serie_data']);
      if (serieData is Map<String, dynamic>) {
        return _detailsFromSerieData(serieData, fallback);
      }
    } catch (_) {}
    return ContentDetails.fromItem(fallback);
  }

  ContentDetails _detailsFromSerieData(
      Map<String, dynamic> d, ContentItem fallback) {
    final dataMap = _asMap(d['data']);
    final raw = _asMap(dataMap['raw']);
    final ranks = _asMap(d['ranks']);

    final item = _itemFromJson(d).copyWith(sourceId: id);

    final tags = (d['tags'] is List ? d['tags'] as List : const [])
        .whereType<Map<String, dynamic>>()
        .map((t) => '${t['title'] ?? ''}')
        .where((t) => t.trim().isNotEmpty)
        .toList(growable: false);

    final latestChapters =
        (d['last_chapters'] is List ? d['last_chapters'] as List : const [])
            .whereType<Map<String, dynamic>>()
            .map((c) => ChapterItem(
                  id: int.tryParse('${c['id'] ?? 0}') ?? 0,
                  number: int.tryParse('${c['order'] ?? 0}') ?? 0,
                  title: '${c['title'] ?? ''}',
                  updatedAt: DateTime.tryParse('${c['updated_at'] ?? ''}'),
                ))
            .toList(growable: false);

    final rankParts = <String>[];
    if (ranks['week'] != null) rankParts.add('Week #${ranks['week']}');
    if (ranks['month'] != null) rankParts.add('Month #${ranks['month']}');
    if (ranks['all'] != null) rankParts.add('All #${ranks['all']}');

    return ContentDetails(
      item: item,
      description: '${dataMap['description'] ?? fallback.description}',
      rawTitle: '${raw['title'] ?? item.title}',
      rawAuthor: '${raw['author'] ?? item.author}',
      rawDescription: '${raw['description'] ?? ''}',
      chapterCount:
          int.tryParse('${d['raw_chapter_count'] ?? item.chapterCount ?? 0}') ??
              0,
      viewCount: int.tryParse('${d['view'] ?? 0}') ?? 0,
      rating: double.tryParse('${d['rating'] ?? 0}') ?? 0,
      tags: tags,
      latestChapters: latestChapters,
      extraFields: {
        if (rankParts.isNotEmpty) 'Ranks': rankParts.join(' • '),
        if (d['raw_verified'] != null) 'Verified': '${d['raw_verified']}',
      },
    );
  }

  String _extractText(dynamic data) {
    // The proxy may return the payload as a JSON string — decode it first.
    dynamic root = data;
    if (root is String) {
      try {
        root = jsonDecode(root);
      } catch (_) {
        return root as String;
      }
    }

    // The proxy itself wraps the response: { "body": <actual response> }
    // Unwrap one level if needed.
    if (root is Map<String, dynamic> && root.containsKey('body')) {
      final inner = root['body'];
      if (inner is String) {
        try {
          root = jsonDecode(inner);
        } catch (_) {
          root = inner;
        }
      } else {
        root = inner;
      }
    }

    // Re-decode if still a string after proxy unwrap.
    if (root is String) {
      try {
        root = jsonDecode(root);
      } catch (_) {
        return root as String;
      }
    }

    if (root is! Map<String, dynamic>) {
      return 'No chapter text available.';
    }

    // ── Extract glossary terms: glossary_data.terms = [[en, zh], ...]
    final glossaryData = root['glossary_data'];
    final terms = <int, String>{};
    if (glossaryData is Map<String, dynamic>) {
      final termsList = glossaryData['terms'];
      if (termsList is List) {
        for (var i = 0; i < termsList.length; i++) {
          final entry = termsList[i];
          if (entry is List && entry.isNotEmpty) {
            terms[i] = '${entry[0]}'; // English term at index 0
          }
        }
      }
    }

    // ── Navigate to body: root.data.data.body
    final outerData = root['data'];
    if (outerData is! Map<String, dynamic>) {
      return 'No chapter text available.';
    }
    final innerData = outerData['data'];
    if (innerData is! Map<String, dynamic>) {
      return 'No chapter text available.';
    }
    final body = innerData['body'];
    if (body is! List || body.isEmpty) {
      return 'No chapter text available.';
    }

    // ── Join lines and resolve glossary placeholders
    final lines = body
        .map((line) => _resolveGlossary('$line', terms))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    return lines.isEmpty ? 'No chapter text available.' : lines.join('\n\n');
  }

  /// Replaces ※N⛬ and ※N〓 placeholders with the English term at index N
  /// from the glossary. Unknown indices are left as-is.
  String _resolveGlossary(String line, Map<int, String> terms) {
    if (terms.isEmpty) return line;
    return line.replaceAllMapped(
      RegExp(r'※(\d+)[⛬〓]'),
      (match) {
        final index = int.tryParse(match.group(1) ?? '');
        if (index == null) return match.group(0)!;
        return terms[index] ?? match.group(0)!;
      },
    );
  }

  Map<String, dynamic> _asMap(dynamic value) =>
      value is Map<String, dynamic> ? value : const <String, dynamic>{};

  String _slugify(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');

  // ── Demo fallbacks ────────────────────────────────────────────────────────

  static final _demoItems = <ContentItem>[
    const ContentItem(
      id: 70381,
      title: 'Future Daughters Show Up',
      author: 'WTR',
      description: 'A translated web novel available for reader testing.',
      sourceId: 'wtr_novel',
    ),
    const ContentItem(
      id: 1002,
      title: 'Solo Leveling',
      author: 'Chugong',
      description: 'Action fantasy novel placeholder entry.',
      sourceId: 'wtr_novel',
    ),
    const ContentItem(
      id: 1003,
      title: 'Omniscient Reader',
      author: 'Sing Shong',
      description: 'Apocalypse fantasy placeholder entry.',
      sourceId: 'wtr_novel',
    ),
    const ContentItem(
      id: 1004,
      title: 'The Beginning After The End',
      author: 'TurtleMe',
      description: 'Fantasy adventure placeholder entry.',
      sourceId: 'wtr_novel',
    ),
  ];

  List<ChapterItem> _demoChapters(int bookId) => List.generate(
        20,
        (i) => ChapterItem(
          id: bookId == 70381 ? 39133649 + i : bookId * 1000 + i,
          number: i + 1,
          title: 'Chapter ${i + 1}',
        ),
      );
}
