import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../../../extensions/models/chapter_item.dart';
import '../../../extensions/models/content_item.dart';
import '../../../extensions/registry/source_registry.dart';

enum _MangaFitMode { width, contain, cover, none }

extension on _MangaFitMode {
  String get label => switch (this) {
        _MangaFitMode.width => 'Fit width',
        _MangaFitMode.contain => 'Contain',
        _MangaFitMode.cover => 'Cover',
        _MangaFitMode.none => 'Original',
      };

  BoxFit get fit => switch (this) {
        _MangaFitMode.width => BoxFit.fitWidth,
        _MangaFitMode.contain => BoxFit.contain,
        _MangaFitMode.cover => BoxFit.cover,
        _MangaFitMode.none => BoxFit.none,
      };
}

/// Full-screen manga chapter viewer built on [PhotoViewGallery].
/// Supports vertical webtoon-style scrolling through chapter images.
class MangaReaderPage extends StatefulWidget {
  const MangaReaderPage({
    super.key,
    required this.item,
    required this.chapterId,
    required this.chapterNo,
    required this.chapterTitle,
    required this.previousChapter,
    required this.nextChapter,
    required this.onPrevious,
    required this.onNext,
  });

  final ContentItem item;
  final int chapterId;
  final int chapterNo;
  final String chapterTitle;
  final ChapterItem? previousChapter;
  final ChapterItem? nextChapter;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  State<MangaReaderPage> createState() => _MangaReaderPageState();
}

class _MangaReaderPageState extends State<MangaReaderPage> {
  late final Future<List<String>> _future;
  bool _showUi = true;
  _MangaFitMode _fitMode = _MangaFitMode.width;
  double _zoom = 1.0;

  static const _minZoom = 0.75;
  static const _maxZoom = 2.5;
  static const _zoomStep = 0.15;

  @override
  void initState() {
    super.initState();
    _future = SourceRegistry.instance.active
        .getChapterImages(
          item: widget.item,
          chapterId: widget.chapterId,
          chapterNo: widget.chapterNo,
        )
        .then((pages) async {
      // Prefetch first few images into the cache for faster display.
      const prefetchCount = 3;
      final toPrefetch = min(prefetchCount, pages.length);
      final cache = DefaultCacheManager();
      for (var i = 0; i < toPrefetch; i++) {
        try {
          await cache.getSingleFile(pages[i]);
        } catch (_) {
          // ignore prefetch errors
        }
      }

      // Prefetch the first few pages of the next chapter asynchronously.
      if (widget.nextChapter != null) {
        SourceRegistry.instance.active
            .getChapterImages(
              item: widget.item,
              chapterId: widget.nextChapter!.id,
              chapterNo: widget.nextChapter!.number,
            )
            .then((nextPages) async {
          final nextCount = min(prefetchCount, nextPages.length);
          for (var i = 0; i < nextCount; i++) {
            try {
              await cache.getSingleFile(nextPages[i]);
            } catch (_) {}
          }
        }).catchError((_) {});
      }

      return pages;
    });
    // Enter immersive mode for reading.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // Restore system UI when leaving the reader.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleUi() => setState(() => _showUi = !_showUi);

  void _zoomIn() {
    setState(() {
      _zoom = (_zoom + _zoomStep).clamp(_minZoom, _maxZoom);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoom = (_zoom - _zoomStep).clamp(_minZoom, _maxZoom);
    });
  }

  void _resetView() {
    setState(() {
      _zoom = 1.0;
      _fitMode = _MangaFitMode.width;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final pages = snap.data ?? const [];

        if (pages.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text('Chapter ${widget.chapterNo}')),
            body: const Center(
                child: Text('No pages available for this chapter.')),
          );
        }

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // ── Webtoon scroll ───────────────────────────────────────────
              GestureDetector(
                onTap: _toggleUi,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.zero,
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => LayoutBuilder(
                            builder: (context, constraints) {
                              final imageWidth = constraints.maxWidth * _zoom;
                              return Align(
                                alignment: Alignment.topCenter,
                                child: Image.network(
                                  pages[index],
                                  width: imageWidth,
                                  fit: _fitMode.fit,
                                  alignment: Alignment.topCenter,
                                  gaplessPlayback: true,
                                  loadingBuilder: (context, child, event) {
                                    if (event == null) return child;
                                    return const SizedBox(
                                      height: 320,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (_, __, ___) => const SizedBox(
                                    height: 320,
                                    child: Center(
                                      child: Icon(
                                        Icons.broken_image_rounded,
                                        color: Colors.white54,
                                        size: 64,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          childCount: pages.length,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Top bar ────────────────────────────────────────────────────
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                top: _showUi ? 0 : -120,
                left: 0,
                right: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_rounded,
                                  color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Chapter ${widget.chapterNo}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (widget.chapterTitle.isNotEmpty)
                                    Text(
                                      widget.chapterTitle,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: widget.previousChapter == null
                                  ? 'No previous chapter'
                                  : 'Previous chapter',
                              onPressed: widget.onPrevious,
                              icon: const Icon(Icons.skip_previous_rounded,
                                  color: Colors.white),
                            ),
                            IconButton(
                              tooltip: widget.nextChapter == null
                                  ? 'No next chapter'
                                  : 'Next chapter',
                              onPressed: widget.onNext,
                              icon: const Icon(Icons.skip_next_rounded,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              PopupMenuButton<_MangaFitMode>(
                                tooltip: 'Fit options',
                                icon: const Icon(
                                  Icons.photo_size_select_large_rounded,
                                  color: Colors.white,
                                ),
                                onSelected: (mode) => setState(() => _fitMode = mode),
                                itemBuilder: (context) => [
                                  for (final mode in _MangaFitMode.values)
                                    PopupMenuItem(
                                      value: mode,
                                      child: Text(mode.label),
                                    ),
                                ],
                              ),
                              IconButton(
                                tooltip: 'Zoom out',
                                onPressed: _zoom > _minZoom ? _zoomOut : null,
                                icon: const Icon(Icons.zoom_out_rounded,
                                    color: Colors.white),
                              ),
                              IconButton(
                                tooltip: 'Zoom in',
                                onPressed: _zoom < _maxZoom ? _zoomIn : null,
                                icon: const Icon(Icons.zoom_in_rounded,
                                    color: Colors.white),
                              ),
                              IconButton(
                                tooltip: 'Reset view',
                                onPressed: _zoom == 1.0 && _fitMode == _MangaFitMode.width
                                    ? null
                                    : _resetView,
                                icon: const Icon(Icons.restart_alt_rounded,
                                    color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Bottom bar ────────────────────────────────────────────────
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                bottom: _showUi ? 0 : -120,
                left: 0,
                right: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.swipe_vertical_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Webtoon scroll • ${pages.length} pages • ${_fitMode.label} • ${(_zoom * 100).round()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
