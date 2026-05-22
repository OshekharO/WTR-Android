import '../../../books/data/models/book.dart';

class NovelDetails {
  const NovelDetails({
    required this.book,
    required this.rawTitle,
    required this.rawAuthor,
    required this.rawDescription,
    required this.rawChapterCount,
    required this.viewCount,
    required this.inLibraryCount,
    required this.totalRate,
    required this.rating,
    required this.rankWeek,
    required this.rankMonth,
    required this.rankAll,
    required this.requestedByName,
    required this.releasedByName,
    required this.rawVerified,
    required this.tags,
    required this.lastChapters,
    required this.rawSources,
  });

  final Book book;
  final String rawTitle;
  final String rawAuthor;
  final String rawDescription;
  final int rawChapterCount;
  final int viewCount;
  final int inLibraryCount;
  final int totalRate;
  final double rating;
  final int? rankWeek;
  final int? rankMonth;
  final int? rankAll;
  final String? requestedByName;
  final String? releasedByName;
  final bool rawVerified;
  final List<String> tags;
  final List<NovelLastChapter> lastChapters;
  final List<NovelRawSource> rawSources;

  factory NovelDetails.fromBook(Book book) => NovelDetails(
        book: book,
        rawTitle: book.title,
        rawAuthor: book.author,
        rawDescription: book.description,
        rawChapterCount: book.chapterCount ?? 0,
        viewCount: 0,
        inLibraryCount: 0,
        totalRate: 0,
        rating: 0,
        rankWeek: null,
        rankMonth: null,
        rankAll: null,
        requestedByName: null,
        releasedByName: null,
        rawVerified: false,
        tags: const [],
        lastChapters: const [],
        rawSources: const [],
      );

  factory NovelDetails.fromSerieData(Map<String, dynamic> serieData) {
    final book = Book.fromJson(serieData);
    final payload = _map(serieData['data']);
    final raw = _map(payload['raw']);
    final releasedUser = _map(serieData['released_user']);
    final ranks = _map(serieData['ranks']);

    return NovelDetails(
      book: book,
      rawTitle: _string(raw['title'], book.title),
      rawAuthor: _string(raw['author'], book.author),
      rawDescription: _string(raw['description'], book.description),
      rawChapterCount: _int(serieData['raw_chapter_count'], book.chapterCount ?? 0),
      viewCount: _int(serieData['view']),
      inLibraryCount: _int(serieData['in_library']),
      totalRate: _int(serieData['total_rate']),
      rating: _double(serieData['rating']),
      rankWeek: _parseNullableInt(ranks['week']),
      rankMonth: _parseNullableInt(ranks['month']),
      rankAll: _parseNullableInt(ranks['all']),
      requestedByName: _nullableString(serieData['requested_by_name']),
      releasedByName: _nullableString(releasedUser['username']),
      rawVerified: _bool(serieData['raw_verified']),
      tags: _list(serieData['tags']).map((entry) => _string(_map(entry)['title'])).where((value) => value.trim().isNotEmpty).toList(growable: false),
      lastChapters: _list(serieData['last_chapters']).whereType<Map<String, dynamic>>().map(NovelLastChapter.fromJson).toList(growable: false),
      rawSources: _list(serieData['raws']).whereType<Map<String, dynamic>>().map(NovelRawSource.fromJson).toList(growable: false),
    );
  }
}

class NovelLastChapter {
  const NovelLastChapter({
    required this.id,
    required this.order,
    required this.title,
    required this.rawName,
    required this.updatedAt,
  });

  final int id;
  final int order;
  final String title;
  final String rawName;
  final DateTime? updatedAt;

  factory NovelLastChapter.fromJson(Map<String, dynamic> json) => NovelLastChapter(
        id: _int(json['id']),
        order: _int(json['order']),
        title: _string(json['title']),
        rawName: _string(json['name']),
        updatedAt: DateTime.tryParse(_string(json['updated_at'])),
      );
}

class NovelRawSource {
  const NovelRawSource({
    required this.id,
    required this.chapterCount,
    required this.viewCount,
    required this.slug,
    required this.verified,
    required this.isDefault,
    required this.createdAt,
  });

  final int id;
  final int chapterCount;
  final int viewCount;
  final String slug;
  final bool verified;
  final bool isDefault;
  final DateTime? createdAt;

  factory NovelRawSource.fromJson(Map<String, dynamic> json) => NovelRawSource(
        id: _int(json['id']),
        chapterCount: _int(json['chapter_count']),
        viewCount: _int(json['view']),
        slug: _string(json['slug']),
        verified: _bool(json['verified']),
        isDefault: _bool(json['default']),
        createdAt: DateTime.tryParse(_string(json['created_at'])),
      );
}

Map<String, dynamic> _map(dynamic value) => value is Map<String, dynamic> ? value : <String, dynamic>{};

List<dynamic> _list(dynamic value) => value is List ? value : const <dynamic>[];

String _string(dynamic value, [String fallback = '']) => value == null ? fallback : '$value';

String? _nullableString(dynamic value) {
  final text = _string(value).trim();
  return text.isEmpty ? null : text;
}

int _int(dynamic value, [int fallback = 0]) => int.tryParse('${value ?? fallback}') ?? fallback;

int? _parseNullableInt(dynamic value) {
  final text = _nullableString(value);
  if (text == null) return null;
  return int.tryParse(text);
}

double _double(dynamic value, [double fallback = 0]) => double.tryParse('${value ?? fallback}') ?? fallback;

bool _bool(dynamic value) {
  if (value is bool) return value;
  final text = _string(value).toLowerCase().trim();
  return text == 'true' || text == '1' || text == 'yes';
}