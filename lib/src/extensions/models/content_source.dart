import 'content_item.dart';
import 'content_details.dart';
import 'chapter_item.dart';

/// The type of content a source provides.
enum SourceType { novel, manga, anime, other }

/// Every content source (WTR novels, manga, anime, custom extensions) must
/// implement this interface. The UI only ever talks to [ContentSource] — it
/// never knows which concrete source is active.
abstract class ContentSource {
  /// Unique machine-readable identifier, e.g. `'wtr_novel'`.
  String get id;

  /// Human-readable display name shown in the Extensions tab.
  String get name;

  /// Short description shown below the name in the Extensions tab.
  String get description;

  /// The type of content this source provides.
  SourceType get type;

  /// Base URL of the upstream API / website.
  String get baseUrl;

  /// Icon to show in the Extensions tab.
  /// Return null to fall back to a default icon based on [type].
  String? get iconAsset;

  // ── Core API ──────────────────────────────────────────────────────────────

  /// Returns the home feed (trending / ranking / latest).
  Future<List<ContentItem>> getHome();

  /// Returns search results for [query].
  Future<List<ContentItem>> search(String query);

  /// Returns full details for the item identified by [id].
  Future<ContentDetails> getDetails(ContentItem item);

  /// Returns the chapter / episode list for the item identified by [id].
  Future<List<ChapterItem>> getChapters(ContentItem item);

  /// Returns the text / content for a single chapter (novels).
  /// [chapterId] is [ChapterItem.id], [chapterNo] is [ChapterItem.number].
  Future<String> getChapterContent({
    required ContentItem item,
    required int chapterId,
    required int chapterNo,
  });

  /// Returns an ordered list of image URLs for a manga chapter.
  /// Sources that are not manga should return an empty list.
  Future<List<String>> getChapterImages({
    required ContentItem item,
    required int chapterId,
    required int chapterNo,
  });

  /// Returns a streamable video URL for an anime episode.
  /// Sources that are not anime should return null.
  Future<String?> getEpisodeUrl({
    required ContentItem item,
    required int episodeId,
    required int episodeNo,
  });
}
