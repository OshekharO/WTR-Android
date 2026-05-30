import 'package:dio/dio.dart';

import '../../../core/data/demo_books.dart';
import '../../../core/network/dio_client.dart';
import '../../../extensions/novel/wtr_novel_source.dart';
import '../../books/data/models/book.dart';

class HomeRepository {
  HomeRepository({DioClient? client}) : _client = client ?? DioClient();
  final DioClient _client;

  Future<List<Book>> fetchHomeBooks({String type = 'weekly', int limit = 5}) async {
    try {
      final res = await _client.dio.get(
        '${WtrConstants.webBaseUrl}${WtrConstants.serieRanking}',
        queryParameters: {'type': type, 'limit': limit},
      );
      final data = res.data;
      final list = data is List ? data : (data['data'] ?? data['books'] ?? []) as List;
      return list.map((e) => Book.fromJson(Map<String, dynamic>.from(e))).toList();
    } on DioException {
      return demoBooks;
    } catch (_) {
      return demoBooks;
    }
  }
}
