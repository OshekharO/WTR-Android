class Book {
  const Book({required this.id, required this.title, required this.author, required this.description, this.coverUrl});

  final int id;
  final String title;
  final String author;
  final String description;
  final String? coverUrl;

  factory Book.fromJson(Map<String, dynamic> json) => Book(
        id: int.tryParse('${json['id'] ?? json['raw_id'] ?? 0}') ?? 0,
        title: '${json['title'] ?? json['name'] ?? 'Untitled'}',
        author: '${json['author'] ?? 'Unknown'}',
        description: '${json['description'] ?? json['desc'] ?? 'No description available.'}',
        coverUrl: json['cover']?.toString() ?? json['cover_url']?.toString(),
      );
}
