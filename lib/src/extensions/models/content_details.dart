import 'content_item.dart';
import 'chapter_item.dart';

/// Rich details for a single content item, returned by [ContentSource.getDetails].
class ContentDetails {
  const ContentDetails({
    required this.item,
    required this.description,
    this.rawTitle,
    this.rawAuthor,
    this.rawDescription,
    this.chapterCount = 0,
    this.viewCount = 0,
    this.rating = 0,
    this.tags = const [],
    this.latestChapters = const [],
    this.extraFields = const {},
  });

  final ContentItem item;

  /// Localised / translated description shown in the UI.
  final String description;

  // Optional raw-language metadata (novels only for now).
  final String? rawTitle;
  final String? rawAuthor;
  final String? rawDescription;

  final int chapterCount;
  final int viewCount;
  final double rating;
  final List<String> tags;
  final List<ChapterItem> latestChapters;

  /// Source-specific extra data (e.g. episode count, studio, etc.).
  final Map<String, String> extraFields;

  factory ContentDetails.fromItem(ContentItem item) => ContentDetails(
        item: item,
        description: item.description,
        chapterCount: item.chapterCount ?? 0,
      );
}
