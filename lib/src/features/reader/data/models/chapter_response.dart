class ChapterResponse {
  ChapterResponse({required this.success, required this.title, required this.body});
  final bool success;
  final String title;
  final List<String> body;
  factory ChapterResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final nested = data['data'] as Map<String, dynamic>? ?? data;
    return ChapterResponse(success: json['success'] == true, title: nested['title']?.toString() ?? 'Untitled Chapter', body: (nested['body'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList());
  }
}
