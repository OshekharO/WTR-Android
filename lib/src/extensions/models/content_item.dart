/// A generic content item returned by any source (novel, manga, anime, etc.).
class ContentItem {
  const ContentItem({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    this.rawId,
    this.slug,
    this.coverUrl,
    this.chapterCount,
    this.sourceId,
  });

  final int id;
  final int? rawId;
  final String? slug;
  final String title;
  final String author;
  final String description;
  final String? coverUrl;
  final int? chapterCount;

  /// The id of the [ContentSource] that produced this item.
  final String? sourceId;

  ContentItem copyWith({String? sourceId}) => ContentItem(
        id: id,
        rawId: rawId,
        slug: slug,
        title: title,
        author: author,
        description: description,
        coverUrl: coverUrl,
        chapterCount: chapterCount,
        sourceId: sourceId ?? this.sourceId,
      );
}
