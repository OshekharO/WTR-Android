import '../models/chapter_item.dart';
import '../models/content_details.dart';
import '../models/content_item.dart';
import '../models/content_source.dart';

/// Placeholder manga source. Replace the stub methods with real API calls
/// once a manga API / scraper is integrated.
class MangaSource implements ContentSource {
  const MangaSource();

  @override
  String get id => 'manga_stub';

  @override
  String get name => 'Manga';

  @override
  String get description => 'Manga source — coming soon';

  @override
  SourceType get type => SourceType.manga;

  @override
  String get baseUrl => '';

  @override
  String? get iconAsset => null;

  @override
  Future<List<ContentItem>> getHome() async => const [];

  @override
  Future<List<ContentItem>> search(String query) async => const [];

  @override
  Future<ContentDetails> getDetails(ContentItem item) async =>
      ContentDetails.fromItem(item);

  @override
  Future<List<ChapterItem>> getChapters(ContentItem item) async => const [];

  @override
  Future<String> getChapterContent({
    required ContentItem item,
    required int chapterId,
    required int chapterNo,
  }) async =>
      'Manga reader coming soon.';

  @override
  Future<List<String>> getChapterImages({
    required ContentItem item,
    required int chapterId,
    required int chapterNo,
  }) async =>
      // Demo pages so the viewer is testable without a real API.
      List.generate(
        5,
        (i) => 'https://picsum.photos/seed/${chapterId + i}/800/1200',
      );

  @override
  Future<String?> getEpisodeUrl({
    required ContentItem item,
    required int episodeId,
    required int episodeNo,
  }) async =>
      null;
}
