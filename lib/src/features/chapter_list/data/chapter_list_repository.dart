import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/data/demo_books.dart';
import '../../../core/network/dio_client.dart';
import 'models/chapter_item.dart';

class ChapterListRepository {
  ChapterListRepository({DioClient? client}) : _client = client ?? DioClient();
  final DioClient _client;

  Future<List<ChapterItem>> fetchChapters(int bookId) async {
    try {
      final res = await _client.dio.get(ApiConstants.chapterList, queryParameters: {'id': bookId, 'raw_id': bookId});
      final data = res.data;
      final list = data is List ? data : (data['data'] ?? data['chapters'] ?? []) as List;
      return list.map((e) => ChapterItem.fromJson(Map<String, dynamic>.from(e))).toList();
    } on DioException {
      return demoChapters(bookId);
    } catch (_) {
      return demoChapters(bookId);
    }
  }
}
