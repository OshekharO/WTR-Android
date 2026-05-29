/// A single chapter / episode entry returned by [ContentSource.getChapters].
class ChapterItem {
  const ChapterItem({
    required this.id,
    required this.number,
    required this.title,
    this.updatedAt,
  });

  final int id;
  final int number;
  final String title;
  final DateTime? updatedAt;

  factory ChapterItem.fromJson(Map<String, dynamic> json) => ChapterItem(
        id: int.tryParse('${json['id'] ?? json['chapter_id'] ?? 0}') ?? 0,
        number: int.tryParse(
                '${json['number'] ?? json['chapter_no'] ?? json['no'] ?? json['order'] ?? 1}') ??
            1,
        title:
            '${json['title'] ?? 'Chapter ${json['chapter_no'] ?? json['number'] ?? json['order'] ?? ''}'}',
        updatedAt: DateTime.tryParse('${json['updated_at'] ?? ''}'),
      );
}
