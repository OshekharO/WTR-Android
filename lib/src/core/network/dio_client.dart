import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../constants/api_constants.dart';

class DioClient {
  DioClient({Dio? dio, Logger? logger})
      : logger = logger ?? Logger(),
        dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConstants.apiProxyBaseUrl,
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 30),
                headers: const {
                  'Accept': 'application/json',
                  'Content-Type': 'application/json',
                },
              ),
            ) {
    this.dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              this.logger.i('API ${options.method} ${options.baseUrl}${options.path}');
              this.logger.d('Query: ${options.queryParameters} Body: ${options.data}');
              handler.next(options);
            },
            onResponse: (response, handler) {
              this.logger.i('API ${response.statusCode} ${response.requestOptions.path}');
              handler.next(response);
            },
            onError: (error, handler) {
              this.logger.e('API ERROR ${error.requestOptions.path}', error: error);
              handler.next(error);
            },
          ),
        );
  }

  final Dio dio;
  final Logger logger;

  Future<Response<dynamic>> postViaProxy({
    required String targetUrl,
    required Map<String, dynamic> body,
    Map<String, dynamic>? headers,
  }) {
    return dio.post(
      'https://cors-bypasser-pro.vercel.app/proxy',
      data: <String, dynamic>{
        'url': targetUrl,
        'method': 'POST',
        'headers': <String, dynamic>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          ...?headers,
        },
        'body': body,
      },
    );
  }
}
