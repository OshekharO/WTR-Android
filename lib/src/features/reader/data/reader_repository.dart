import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'models/chapter_request.dart';
import 'models/chapter_response.dart';

class ReaderRepository {
  ReaderRepository({DioClient? client}) : _client = client ?? DioClient();
  final DioClient _client;
  Future<ChapterResponse> fetchChapter(ChapterRequest request) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(ApiConstants.readerGet, data: request.toJson());
      return ChapterResponse.fromJson(res.data ?? {});
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? e.message);
    }
  }
}
