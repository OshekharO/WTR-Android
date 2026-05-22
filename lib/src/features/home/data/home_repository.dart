import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/data/demo_books.dart';
import '../../../core/network/dio_client.dart';
import '../../books/data/models/book.dart';

class HomeRepository {
  HomeRepository({DioClient? client}) : _client = client ?? DioClient();
  final DioClient _client;

  Future<List<Book>> fetchHomeBooks() async {
    try {
      final res = await _client.dio.get(ApiConstants.home);
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
