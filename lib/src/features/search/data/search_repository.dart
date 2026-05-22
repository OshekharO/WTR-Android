import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/data/demo_books.dart';
import '../../../core/network/dio_client.dart';
import '../../books/data/models/book.dart';

class SearchRepository {
  SearchRepository({DioClient? client}) : _client = client ?? DioClient();
  final DioClient _client;

  Future<List<Book>> search(String query) async {
    if (query.trim().isEmpty) return demoBooks;
    try {
      final res = await _client.dio.get(ApiConstants.search, queryParameters: {'q': query, 'query': query});
      final data = res.data;
      final list = data is List ? data : (data['data'] ?? data['results'] ?? []) as List;
      return list.map((e) => Book.fromJson(Map<String, dynamic>.from(e))).toList();
    } on DioException {
      return demoBooks.where((b) => b.title.toLowerCase().contains(query.toLowerCase())).toList();
    } catch (_) {
      return demoBooks.where((b) => b.title.toLowerCase().contains(query.toLowerCase())).toList();
    }
  }
}
