import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Displays a network image.
///
/// On Flutter Web, rewrites the URL through `wsrv.nl` so the browser can load
/// the image directly without a CORS-blocked origin.
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
      return CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        placeholder: (_, __) => const Center(
          child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (_, __, ___) => _fallback,
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
  late String _imageUrl;

  @override
  void initState() {
    super.initState();
    _imageUrl = _wsrvUrl(widget.url);
  }

  @override
  void didUpdateWidget(_WebProxiedImage old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      _imageUrl = _wsrvUrl(widget.url);
    }
  }

  String _wsrvUrl(String url) =>
      'https://wsrv.nl/?url=${Uri.encodeComponent(url)}';

  @override
  Widget build(BuildContext context) => Image.network(
        _imageUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
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
        },
        errorBuilder: (_, __, ___) => widget.fallback,
      );
}
