import 'package:dio/dio.dart';
import 'dart:convert';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../books/data/models/book.dart';

class DetailsRepository {
  DetailsRepository({DioClient? client}) : _client = client ?? DioClient();
  final DioClient _client;

  Future<Book> fetchDetails(Book fallback) async {
    try {
      final rawId = fallback.rawId ?? fallback.id;
      final slug = fallback.slug ?? _slugify(fallback.title);
      final res = await _client.dio.get(
        '/en/novel/$rawId/$slug',
        options: Options(responseType: ResponseType.plain),
      );
      final html = res.data is String ? res.data as String : '${res.data}';
      return _parsePageBook(html, fallback);
    } on DioException {
      return fallback;
    } catch (_) {
      return fallback;
    }
  }

  Book _parsePageBook(String html, Book fallback) {
    final match = RegExp(r'<script id="__NEXT_DATA__" type="application/json">(.*?)</script>', dotAll: true).firstMatch(html);
    if (match == null) return fallback;

    try {
      final payload = jsonDecode(match.group(1)!) as Map<String, dynamic>;
      final serieData = payload['props'] is Map<String, dynamic>
          ? (payload['props'] as Map<String, dynamic>)['pageProps'] is Map<String, dynamic>
              ? ((payload['props'] as Map<String, dynamic>)['pageProps'] as Map<String, dynamic>)['serie'] is Map<String, dynamic>
                  ? (((payload['props'] as Map<String, dynamic>)['pageProps'] as Map<String, dynamic>)['serie'] as Map<String, dynamic>)['serie_data']
                  : null
              : null
          : null;

      if (serieData is Map<String, dynamic>) {
        return Book.fromJson(serieData);
      }
    } catch (_) {
      return fallback;
    }

    return fallback;
  }

  String _slugify(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}
