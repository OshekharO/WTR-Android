import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/data/demo_books.dart';
import '../../../core/network/dio_client.dart';
import '../../books/data/models/book.dart';

class DetailsRepository {
  DetailsRepository({DioClient? client}) : _client = client ?? DioClient();
  final DioClient _client;

  Future<Book> fetchDetails(int id, Book fallback) async {
    try {
      final res = await _client.dio.get(ApiConstants.novelDetails, queryParameters: {'id': id, 'raw_id': id});
      final data = res.data['data'] ?? res.data;
      return Book.fromJson(Map<String, dynamic>.from(data));
    } on DioException {
      return demoBooks.firstWhere((b) => b.id == id, orElse: () => fallback);
    } catch (_) {
      return fallback;
    }
  }
}
