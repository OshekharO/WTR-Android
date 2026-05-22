class ChapterRequest {
  const ChapterRequest({
    required this.translate,
    required this.language,
    required this.rawId,
    required this.chapterNo,
    required this.retry,
    required this.forceRetry,
    required this.chapterId,
  });

  final String translate;
  final String language;
  final int rawId;
  final int chapterNo;
  final bool retry;
  final bool forceRetry;
  final int chapterId;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'translate': translate,
        'language': language,
        'raw_id': rawId,
        'chapter_no': chapterNo,
        'retry': retry,
        'force_retry': forceRetry,
        'chapter_id': chapterId,
      };
}