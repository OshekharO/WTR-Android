class ReaderChapterContent {
  const ReaderChapterContent({required this.translated, required this.raw});

  final String translated;
  final String? raw;

  bool get hasRaw => raw != null && raw!.trim().isNotEmpty && raw!.trim() != translated.trim();
}