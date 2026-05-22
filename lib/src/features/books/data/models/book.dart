class Book {
  const Book({required this.id, required this.title, required this.author, required this.description, this.rawId, this.slug, this.coverUrl, this.chapterCount});

  final int id;
  final int? rawId;
  final String? slug;
  final String title;
  final String author;
  final String description;
  final String? coverUrl;
  final int? chapterCount;

  factory Book.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final payload = data is Map<String, dynamic> ? data : <String, dynamic>{};
    final resolvedRawId = int.tryParse('${json['raw_id'] ?? payload['raw_id'] ?? json['id'] ?? payload['id'] ?? 0}') ?? 0;
    final slugValue = json['slug'] ?? payload['slug'];

    return Book(
      id: int.tryParse('${json['id'] ?? payload['id'] ?? resolvedRawId}') ?? 0,
      rawId: resolvedRawId == 0 ? null : resolvedRawId,
      slug: slugValue == null || '$slugValue'.trim().isEmpty ? null : '$slugValue',
      title: '${payload['title'] ?? json['title'] ?? json['name'] ?? 'Untitled'}',
      author: '${payload['author'] ?? json['author'] ?? 'Unknown'}',
      description: '${payload['description'] ?? json['description'] ?? json['desc'] ?? 'No description available.'}',
      coverUrl: json['image']?.toString() ?? payload['image']?.toString() ?? json['cover']?.toString() ?? json['cover_url']?.toString(),
      chapterCount: int.tryParse('${json['chapter_count'] ?? json['raw_chapter_count'] ?? payload['chapter_count'] ?? payload['raw_chapter_count'] ?? 0}') ?? 0,
    );
  }
}
