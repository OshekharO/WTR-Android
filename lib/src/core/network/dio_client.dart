import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../constants/api_constants.dart';

class DioClient {
  DioClient({Dio? dio, Logger? logger})
      : _logger = logger ?? Logger(),
        dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConstants.baseUrl,
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 30),
                sendTimeout: const Duration(seconds: 20),
                headers: const {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    this.dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              _logger.i('${options.method} ${options.uri}');
              _logger.d(options.data);
              handler.next(options);
            },
            onResponse: (response, handler) {
              _logger.i('Response ${response.statusCode} ${response.requestOptions.uri}');
              handler.next(response);
            },
            onError: (error, handler) {
              _logger.e('Dio error: ${error.message}', error: error);
              handler.next(error);
            },
          ),
        );
  }

  final Dio dio;
  final Logger _logger;
}
