import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:logger/logger.dart';

// ApiConstants removed — WTR-specific constants moved to the novel extension.
import 'dns_service.dart';

// ── Generic client (for non-WTR sources) ──────────────────────────────────────

/// Generic HTTP client. Direct requests to whatever baseUrl is configured.
/// Only callers that explicitly need CORS bypass call [postViaProxy].
class DioClient {
  DioClient({Dio? dio, Logger? logger})
      : logger = logger ?? Logger(),
        dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: '',
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 45),
                sendTimeout: const Duration(seconds: 30),
                headers: const {
                  'Accept': 'application/json, text/html, */*',
                  'User-Agent':
                      'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 '
                          '(KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36',
                },
              ),
            ) {
    _addLoggingInterceptor();
    if (!kIsWeb) _addDnsInterceptor();
  }

  final Dio dio;
  final Logger logger;

  void _addLoggingInterceptor() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          logger.i('→ ${options.method} ${options.uri}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          logger.i('← ${response.statusCode} ${response.requestOptions.path}');
          handler.next(response);
        },
        onError: (error, handler) {
          logger.e('⛔ API ERROR ${error.requestOptions.path}', error: error);
          handler.next(error);
        },
      ),
    );
  }

  void _addDnsInterceptor() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            if (DnsService.instance.client != null) {
              final host = options.uri.host;
              if (host.isNotEmpty) {
                final resolved = await DnsService.instance.resolve(host);
                if (resolved != null) {
                  final newUri = options.uri.replace(host: resolved);
                  options.path = newUri.toString();
                  options.headers['Host'] = host;
                  logger.d('DNS $host → $resolved');
                }
              }
            }
          } catch (e) {
            logger.w('DNS interceptor error', error: e);
          }
          handler.next(options);
        },
      ),
    );
  }

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    ResponseType responseType = ResponseType.json,
  }) =>
      dio.get(path,
          queryParameters: queryParameters,
          options: Options(responseType: responseType));

  Future<Response<dynamic>> postViaProxy({
    required String targetUrl,
    required Map<String, dynamic> body,
    Map<String, dynamic>? headers,
  }) =>
      _proxyPost(
          targetUrl: targetUrl, method: 'POST', body: body, headers: headers);
}

// ── WTR-specific proxy client ──────────────────────────────────────────────────

/// Every request to wtr-lab.com goes through cors-bypasser-pro — both GETs
/// (ranking, chapters, detail HTML) and POSTs (search, reader).
///
/// This is the only client [WtrNovelSource] should use.
class WtrProxyClient {
  WtrProxyClient({Logger? logger}) : _log = logger ?? Logger();

  final Logger _log;

  static const _proxyBase = 'https://cors-bypasser-pro.vercel.app';
  // Keep the WTR base literal here to avoid an import cycle; the canonical
  // WTR constants live in the novel extension.
  static const _wtrBase = 'https://wtr-lab.com';

  Dio _buildProxyDio() => Dio(
        BaseOptions(
          baseUrl: _proxyBase,
          connectTimeout: const Duration(seconds: 45),
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 30),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      )..interceptors.add(
          InterceptorsWrapper(
            onRequest: (o, h) {
              _log.i('→ WTR proxy ${o.method} ${o.uri}');
              h.next(o);
            },
            onResponse: (r, h) {
              _log.i('← ${r.statusCode} ${r.requestOptions.path}');
              h.next(r);
            },
            onError: (e, h) {
              _log.e('⛔ WTR proxy error ${e.requestOptions.path}', error: e);
              h.next(e);
            },
          ),
        );

  /// GET [path] on wtr-lab.com via the proxy.
  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    ResponseType responseType = ResponseType.json,
  }) {
    final targetUri = Uri.parse('$_wtrBase$path').replace(
      queryParameters:
          queryParameters?.map((k, v) => MapEntry(k, v.toString())),
    );
    return _proxyPost(
      targetUrl: targetUri.toString(),
      method: 'GET',
      body: const {},
      headers: {
        'Accept': responseType == ResponseType.plain
            ? 'text/html,application/xhtml+xml,*/*'
            : 'application/json',
        'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36',
      },
    );
  }

  /// POST to [targetUrl] on wtr-lab.com via the proxy.
  Future<Response<dynamic>> post({
    required String path,
    required Map<String, dynamic> body,
    Map<String, dynamic>? headers,
  }) =>
      _proxyPost(
        targetUrl: '$_wtrBase$path',
        method: 'POST',
        body: body,
        headers: headers,
      );

  /// Fetch raw bytes for [imageUrl] through the proxy.
  /// Used by [ProxiedImage] on Flutter Web to bypass CDN CORS restrictions.
  Future<List<int>> getBytes(String imageUrl) async {
    final dio = _buildProxyDio();
    final res = await dio.post<List<int>>(
      '/proxy',
      data: <String, dynamic>{
        'url': imageUrl,
        'method': 'GET',
        'headers': <String, dynamic>{
          'Accept': 'image/*,*/*',
        },
        'responseType': 'arraybuffer',
      },
      options: Options(responseType: ResponseType.bytes),
    );
    return res.data ?? const [];
  }

  Future<Response<dynamic>> _proxyPost({
    required String targetUrl,
    required String method,
    required Map<String, dynamic> body,
    Map<String, dynamic>? headers,
  }) {
    final dio = _buildProxyDio();
    return dio.post(
      '/proxy',
      data: <String, dynamic>{
        'url': targetUrl,
        'method': method,
        'headers': <String, dynamic>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          ...?headers,
        },
        if (method != 'GET') 'body': body,
      },
    );
  }
}

// ── Shared proxy helper (used by DioClient.postViaProxy) ──────────────────────

Future<Response<dynamic>> _proxyPost({
  required String targetUrl,
  required String method,
  required Map<String, dynamic> body,
  Map<String, dynamic>? headers,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://cors-bypasser-pro.vercel.app',
      connectTimeout: const Duration(seconds: 45),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 30),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );
  return dio.post(
    '/proxy',
    data: <String, dynamic>{
      'url': targetUrl,
      'method': method,
      'headers': <String, dynamic>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        ...?headers,
      },
      if (method != 'GET') 'body': body,
    },
  );
}
