import '../models/chapter_item.dart';
import '../models/content_details.dart';
import '../models/content_item.dart';
import '../models/content_source.dart';

/// Placeholder anime source. Replace the stub methods with real API calls
/// once an anime API / scraper is integrated.
class AnimeSource implements ContentSource {
  const AnimeSource();

  @override
  String get id => 'anime';

  @override
  String get name => 'Anime';

  @override
  String get description => 'Anime source — coming soon';

  @override
  SourceType get type => SourceType.anime;

  @override
  String get baseUrl => '';

  @override
  String? get iconAsset => null;

  @override
  @override
  Future<List<ContentItem>> getHome() async => const [
        ContentItem(
          id: 9001,
          rawId: 9001,
          slug: 'demo-anime',
          title: 'Demo Anime',
          author: 'Studio Test',
          description: 'A demo anime entry for testing the video player.',
          coverUrl: 'https://placekitten.com/400/600',
          chapterCount: 1,
          sourceId: 'anime',
        ),
      ];

  @override
  Future<List<ContentItem>> search(String query) async => const [];

  @override
  Future<ContentDetails> getDetails(ContentItem item) async =>
      ContentDetails.fromItem(item);

  @override
  Future<List<ChapterItem>> getChapters(ContentItem item) async =>
      const [ChapterItem(id: 1, number: 1, title: 'Episode 1')];

  @override
  Future<String> getChapterContent({
    required ContentItem item,
    required int chapterId,
    required int chapterNo,
  }) async =>
      'Anime player coming soon.';

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
      // Demo HLS stream so the player is testable without a real API.
      'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8';
}
