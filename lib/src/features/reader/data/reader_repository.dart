import 'package:dio/dio.dart';
import 'dart:convert';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'models/chapter_request.dart';
import 'models/reader_chapter_content.dart';

class ReaderRepository {
  ReaderRepository({DioClient? client}) : _client = client ?? DioClient();
  final DioClient _client;

  Future<ReaderChapterContent> fetchChapterContent(ChapterRequest request) async {
    try {
      final res = await _client.postViaProxy(
        targetUrl: '${ApiConstants.webBaseUrl}${ApiConstants.readerGet}',
        body: request.toJson(),
      );
      return _extractChapterContent(res.data);
    } on DioException {
      return _demoContent(request);
    } catch (_) {
      return _demoContent(request);
    }
  }

  Future<String> fetchChapterText(ChapterRequest request) async => (await fetchChapterContent(request)).translated;

  ReaderChapterContent _extractChapterContent(dynamic data) {
    if (data is String) {
      try {
        data = jsonDecode(data);
      } catch (_) {
        return ReaderChapterContent(translated: 'No chapter text available.', raw: null);
      }
    }

    final translated = _extractTranslatedText(data);
    final raw = _extractRawText(data);
    return ReaderChapterContent(translated: translated, raw: raw);
  }

  String _extractTranslatedText(dynamic data) {
    if (data is String) return data;
    if (data is List) {
      final lines = data
          .map(_extractTranslatedText)
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      if (lines.isNotEmpty) return lines.join('\n\n');
    }
    if (data is Map<String, dynamic>) {
      final preferredKeys = <String>['body', 'content', 'text', 'chapter', 'data', 'result', 'payload', 'response'];
      for (final key in preferredKeys) {
        if (!data.containsKey(key)) continue;
        final extracted = _extractTranslatedText(data[key]);
        if (extracted.trim().isNotEmpty && extracted != 'No chapter text available.') {
          return extracted;
        }
      }
    }
    return 'No chapter text available.';
  }

  String? _extractRawText(dynamic data) {
    final taskText = _extractTaskLines(data);
    if (taskText != null && taskText.trim().isNotEmpty) return taskText;

    if (data is Map<String, dynamic>) {
      for (final entry in data.values) {
        final nested = _extractRawText(entry);
        if (nested != null && nested.trim().isNotEmpty) return nested;
      }
    }

    if (data is List) {
      for (final entry in data) {
        final nested = _extractRawText(entry);
        if (nested != null && nested.trim().isNotEmpty) return nested;
      }
    }

    return null;
  }

  String? _extractTaskLines(dynamic data) {
    if (data is Map<String, dynamic>) {
      final steps = data['data'];
      final nested = _extractTaskLines(steps);
      if (nested != null) return nested;

      final translate = data['translate'];
      final translatedNested = _extractTaskLines(translate);
      if (translatedNested != null) return translatedNested;

      final lines = data['lines'];
      if (lines is List && lines.every((entry) => entry is String)) {
        return lines.cast<String>().join('\n\n');
      }

      final parts = data['parts'];
      if (parts is List) {
        for (final part in parts) {
          final partText = _extractTaskLines(part);
          if (partText != null && partText.trim().isNotEmpty) return partText;
        }
      }

      final payload = data['steps'];
      if (payload is Map<String, dynamic>) {
        final translateSteps = payload['translate'];
        if (translateSteps is Map<String, dynamic>) {
          final partsValue = translateSteps['parts'];
          if (partsValue is List) {
            for (final part in partsValue) {
              if (part is Map<String, dynamic>) {
                final linesValue = part['lines'];
                if (linesValue is List && linesValue.every((entry) => entry is String)) {
                  return linesValue.cast<String>().join('\n\n');
                }
              }
            }
          }
        }
      }
    }

    if (data is List) {
      for (final entry in data) {
        final nested = _extractTaskLines(entry);
        if (nested != null && nested.trim().isNotEmpty) return nested;
      }
    }

    return null;
  }

  ReaderChapterContent _demoContent(ChapterRequest request) => ReaderChapterContent(
        translated: 'Chapter ${request.chapterNo}\n\nThis chapter content is unavailable right now, so the reader is showing demo text.',
        raw: null,
      );
}