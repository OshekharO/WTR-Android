import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:cryptography/cryptography.dart';
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

  static const _aesKey = 'IJAFUUxjM25hyzL2AZrn0wl7cESED6Ru';
  static const _googleTranslateApiKey =
      'AIzaSyATBXajvzQLTDHEQbcpq0Ihe0vWDHmO520';

  final WtrProxyClient _client;
  final Logger _log;

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
          'translate': 'web',
          'language': 'en',
          'raw_id': item.rawId ?? item.id,
          'chapter_no': chapterNo,
          'retry': false,
          'force_retry': false,
          'chapter_id': chapterId,
        },
      );

      final lines = await _extractChapterLines(res.data);
      if (lines.isEmpty) {
        return 'Chapter $chapterNo\n\nNo chapter text available.';
      }

      final translated = await _translateHtmlLines(lines);
      return (translated.isNotEmpty ? translated : lines).join('\n\n');
    } catch (e, st) {
      _log.e('WtrNovelSource.getChapterContent failed',
          error: e, stackTrace: st);
      return 'Chapter $chapterNo\n\nContent unavailable right now.';
    }
  }

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

  String? _maybeProxyUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    if (!kIsWeb) return url;
    return 'https://cors-bypasser-pro.vercel.app/proxy?url=${Uri.encodeComponent(url)}';
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

  Future<List<String>> _extractChapterLines(dynamic data) async {
    dynamic root = _decodeMaybeJson(data);

    if (root is Map<String, dynamic> && root.containsKey('body')) {
      root = _decodeMaybeJson(root['body']);
    }

    if (root is! Map<String, dynamic>) return const [];

    dynamic body = root['data']?['data']?['content'] ??
        root['data']?['data']?['body'] ??
        root['data']?['content'] ??
        root['data']?['body'] ??
        root['content'] ??
        root['body'];

    if (body is String && RegExp(r'^(arr|str):').hasMatch(body)) {
      body = await _decryptWtrBody(body);
    }

    return _htmlToLines(body);
  }

  dynamic _decodeMaybeJson(dynamic value) {
    if (value is! String) return value;
    try {
      return jsonDecode(value);
    } catch (_) {
      return value;
    }
  }

  Future<dynamic> _decryptWtrBody(String body) async {
    final match = RegExp(r'^(arr|str):([^:]+):([^:]+):(.+)$').firstMatch(body);
    if (match == null) {
      throw Exception('Invalid WTR encrypted body format');
    }

    final type = match.group(1)!;
    final nonce = base64Decode(match.group(2)!);
    final tag = base64Decode(match.group(3)!);
    final cipherText = base64Decode(match.group(4)!);

    final clearBytes = await AesGcm.with256bits().decrypt(
      SecretBox(cipherText, nonce: nonce, mac: Mac(tag)),
      secretKey: SecretKey(utf8.encode(_aesKey)),
    );

    final decoded = utf8.decode(clearBytes);
    return type == 'arr' ? jsonDecode(decoded) : decoded;
  }

  List<String> _htmlToLines(dynamic value) {
    if (value == null) return const [];

    if (value is List) {
      return value
          .map((e) => _clean('$e'))
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
    }

    return '$value'
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</div>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .split('\n')
        .map(_clean)
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  Future<List<String>> _translateHtmlLines(
    List<String> lines, {
    String from = 'zh-CN',
    String to = 'en',
  }) async {
    if (lines.isEmpty) return const [];

    final wrapped = List.generate(
      lines.length,
      (i) => '<a i=$i>${_escapeHtml(lines[i])}</a>',
    );

    final res = await Dio().post(
      'https://translate-pa.googleapis.com/v1/translateHtml',
      data: [
        [wrapped, from, to],
        'te_lib',
      ],
      options: Options(
        headers: {
          'Content-Type': 'application/json+protobuf',
          'Accept': 'application/json+protobuf',
          'X-Goog-API-Key': _googleTranslateApiKey,
        },
        responseType: ResponseType.json,
      ),
    );

    final data = res.data;
    if (data is! List || data.isEmpty || data.first is! List) return const [];

    return (data.first as List)
        .map((e) => _stripTranslateTag('$e'))
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  String _escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  String _stripTranslateTag(String value) {
    return _clean(
      value
          .replaceFirst(RegExp(r'^<a\s+i=\d+>', caseSensitive: false), '')
          .replaceFirst(RegExp(r'</a>$', caseSensitive: false), ''),
    );
  }

  String _clean(String value) {
    return value
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('\u200b', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Map<String, dynamic> _asMap(dynamic value) =>
      value is Map<String, dynamic> ? value : const <String, dynamic>{};

  String _slugify(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');

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
