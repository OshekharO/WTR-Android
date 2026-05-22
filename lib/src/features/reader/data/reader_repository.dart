import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'models/chapter_request.dart';

class ReaderRepository {
  ReaderRepository({DioClient? client}) : _client = client ?? DioClient();
  final DioClient _client;

  Future<String> fetchChapterText(ChapterRequest request) async {
    try {
      final res = await _client.postViaProxy(
        targetUrl: '${ApiConstants.webBaseUrl}${ApiConstants.readerGet}',
        body: request.toJson(),
      );
      return _extractChapterText(res.data);
    } on DioException {
      return _demoText(request);
    } catch (_) {
      return _demoText(request);
    }
  }

  String _extractChapterText(dynamic data) {
    if (data is String) return data;
    if (data is List) {
      final lines = data
          .map(_extractChapterText)
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      if (lines.isNotEmpty) return lines.join('\n\n');
    }
    if (data is Map<String, dynamic>) {
      final preferredKeys = <String>['body', 'content', 'text', 'chapter', 'data', 'result', 'payload', 'response'];
      for (final key in preferredKeys) {
        if (!data.containsKey(key)) continue;
        final extracted = _extractChapterText(data[key]);
        if (extracted.trim().isNotEmpty && extracted != 'No chapter text available.') {
          return extracted;
        }
      }
    }
    return 'No chapter text available.';
  }

  String _demoText(ChapterRequest request) =>
      'Chapter ${request.chapterNo}\n\nThis chapter content is unavailable right now, so the reader is showing demo text.';
}