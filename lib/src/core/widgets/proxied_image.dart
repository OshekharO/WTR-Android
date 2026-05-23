import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../network/dio_client.dart';

/// Displays a network image.
///
/// On Flutter Web, fetches the image bytes through [WtrProxyClient] to bypass
/// CDN CORS restrictions, then renders via [Image.memory].
/// On native, uses [Image.network] directly (no CORS restriction).
class ProxiedImage extends StatelessWidget {
  const ProxiedImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorWidget,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? errorWidget;

  Widget get _fallback =>
      errorWidget ??
      const Center(child: Icon(Icons.broken_image_rounded, size: 32));

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _fallback,
      );
    }

    // On web: fetch bytes through the proxy, render as Image.memory.
    return _WebProxiedImage(
      url: url,
      width: width,
      height: height,
      fit: fit,
      fallback: _fallback,
    );
  }
}

class _WebProxiedImage extends StatefulWidget {
  const _WebProxiedImage({
    required this.url,
    required this.width,
    required this.height,
    required this.fit,
    required this.fallback,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget fallback;

  @override
  State<_WebProxiedImage> createState() => _WebProxiedImageState();
}

class _WebProxiedImageState extends State<_WebProxiedImage> {
  static final _client = WtrProxyClient();
  // Simple in-memory cache: url → bytes
  static final Map<String, List<int>> _cache = {};

  late Future<List<int>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load(widget.url);
  }

  @override
  void didUpdateWidget(_WebProxiedImage old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      _future = _load(widget.url);
    }
  }

  Future<List<int>> _load(String url) async {
    if (_cache.containsKey(url)) return _cache[url]!;
    final res = await _client.getBytes(url);
    _cache[url] = res;
    return res;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<int>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return SizedBox(
              width: widget.width,
              height: widget.height,
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          if (snap.hasError || snap.data == null || snap.data!.isEmpty) {
            return widget.fallback;
          }
          return Image.memory(
            Uint8List.fromList(snap.data!),
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            errorBuilder: (_, __, ___) => widget.fallback,
          );
        },
      );
}
