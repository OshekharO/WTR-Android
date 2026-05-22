import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../constants/api_constants.dart';

class DioClient {
  DioClient({Dio? dio, Logger? logger}) : logger = logger ?? Logger(), dio = dio ?? Dio(BaseOptions(baseUrl: ApiConstants.baseUrl, connectTimeout: const Duration(seconds: 20), receiveTimeout: const Duration(seconds: 30), headers: const {'Accept': 'application/json', 'Content-Type': 'application/json'})) {
    this.dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: false));
  }
  final Dio dio;
  final Logger logger;
}
