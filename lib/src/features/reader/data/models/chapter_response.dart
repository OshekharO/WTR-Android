class ChapterResponse {
  ChapterResponse({
    required this.success,
    required this.title,
    required this.body,
    required this.glossary,
  });

  final bool success;
  final String title;
  final List<String> body;
  final Map<String, String> glossary;

  factory ChapterResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final nested = data['data'] as Map<String, dynamic>? ?? {};
    final glossaryData = nested['glossary_data'] as Map<String, dynamic>? ?? {};
    final terms = glossaryData['terms'] as List<dynamic>? ?? const [];

    return ChapterResponse(
      success: json['success'] == true,
      title: nested['title']?.toString() ?? json['chapter']?['title']?.toString() ?? 'Untitled Chapter',
      body: (nested['body'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(),
      glossary: {
        for (final item in terms)
          if (item is List && item.length >= 2) item[1].toString(): item[0].toString(),
      },
    );
  }

  String replaceGlossary(String text) {
    var output = text;
    glossary.forEach((source, translated) {
      output = output.replaceAll(source, translated);
    });
    return output;
  }
}
