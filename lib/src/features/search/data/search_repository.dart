import 'package:dio/dio.dart';
import 'dart:convert';

import '../../../core/network/dio_client.dart';
import '../../../extensions/novel/wtr_novel_source.dart';
import '../../books/data/models/book.dart';

class SearchRepository {
  SearchRepository({DioClient? client}) : _client = client ?? DioClient();
  final DioClient _client;

  Future<List<Book>> search(String query) async {
    if (query.trim().isEmpty) return const <Book>[];
    try {
      final res = await _client.postViaProxy(
        targetUrl: '${WtrConstants.webBaseUrl}${WtrConstants.search}',
        body: <String, dynamic>{'text': query},
      );
      return _parseBooks(res.data);
    } on DioException {
      return const <Book>[];
    } catch (_) {
      return const <Book>[];
    }
  }

  List<Book> _parseBooks(dynamic data) {
    if (data is String) {
      try {
        data = jsonDecode(data);
      } catch (_) {
        return const <Book>[];
      }
    }

    final items = _extractItems(data);

    return items
        .whereType<Map<String, dynamic>>()
        .map(Book.fromJson)
        .toList(growable: false);
  }

  List<dynamic> _extractItems(dynamic value) {
    if (value is String) {
      try {
        value = jsonDecode(value);
      } catch (_) {
        return const <dynamic>[];
      }
    }

    if (value is List) {
      if (value.isEmpty) return const <dynamic>[];
      if (value.every((entry) => entry is Map || entry is String)) {
        return value;
      }

      for (final entry in value) {
        final nested = _extractItems(entry);
        if (nested.isNotEmpty) return nested;
      }
      return const <dynamic>[];
    }

    if (value is Map<String, dynamic>) {
      for (final entry in value.entries) {
        final nested = _extractItems(entry.value);
        if (nested.isNotEmpty) return nested;
      }
    }

    return const <dynamic>[];
  }
}
