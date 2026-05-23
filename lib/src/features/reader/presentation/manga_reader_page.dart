import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../../extensions/models/content_item.dart';
import '../../../extensions/registry/source_registry.dart';

/// Full-screen manga chapter viewer built on [PhotoViewGallery].
/// Supports pinch-to-zoom, swipe between pages, and a page indicator.
class MangaReaderPage extends StatefulWidget {
  const MangaReaderPage({
    super.key,
    required this.item,
    required this.chapterId,
    required this.chapterNo,
    required this.chapterTitle,
  });

  final ContentItem item;
  final int chapterId;
  final int chapterNo;
  final String chapterTitle;

  @override
  State<MangaReaderPage> createState() => _MangaReaderPageState();
}

class _MangaReaderPageState extends State<MangaReaderPage> {
  late final Future<List<String>> _future;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _showUi = true;

  @override
  void initState() {
    super.initState();
    _future = SourceRegistry.instance.active.getChapterImages(
      item: widget.item,
      chapterId: widget.chapterId,
      chapterNo: widget.chapterNo,
    );
    // Enter immersive mode for reading.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Restore system UI when leaving the reader.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleUi() => setState(() => _showUi = !_showUi);

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
              // ── Gallery ────────────────────────────────────────────────────
              GestureDetector(
                onTap: _toggleUi,
                child: PhotoViewGallery.builder(
                  pageController: _pageController,
                  itemCount: pages.length,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  scrollPhysics: const BouncingScrollPhysics(),
                  builder: (context, index) => PhotoViewGalleryPageOptions(
                    imageProvider: NetworkImage(pages[index]),
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 3,
                    heroAttributes: PhotoViewHeroAttributes(
                      tag: 'manga_page_${widget.chapterId}_$index',
                    ),
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image_rounded,
                          color: Colors.white54, size: 64),
                    ),
                  ),
                  loadingBuilder: (_, event) => Center(
                    child: CircularProgressIndicator(
                      value: event == null
                          ? null
                          : event.cumulativeBytesLoaded /
                              (event.expectedTotalBytes ?? 1),
                      color: Colors.white,
                    ),
                  ),
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
                    child: Row(
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
                      ],
                    ),
                  ),
                ),
              ),

              // ── Bottom bar — page indicator + navigation ───────────────────
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
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          // Prev page
                          IconButton(
                            icon: const Icon(Icons.chevron_left_rounded,
                                color: Colors.white, size: 32),
                            onPressed: _currentPage > 0
                                ? () => _pageController.previousPage(
                                      duration:
                                          const Duration(milliseconds: 250),
                                      curve: Curves.easeOut,
                                    )
                                : null,
                          ),

                          // Slider
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Page ${_currentPage + 1} / ${pages.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: Colors.white,
                                    inactiveTrackColor: Colors.white30,
                                    thumbColor: Colors.white,
                                    overlayColor: Colors.white24,
                                    trackHeight: 3,
                                    thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 7),
                                  ),
                                  child: Slider(
                                    value: _currentPage.toDouble(),
                                    min: 0,
                                    max: (pages.length - 1).toDouble(),
                                    divisions:
                                        pages.length > 1 ? pages.length - 1 : 1,
                                    onChanged: (v) {
                                      final page = v.round();
                                      _pageController.jumpToPage(page);
                                      setState(() => _currentPage = page);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Next page
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded,
                                color: Colors.white, size: 32),
                            onPressed: _currentPage < pages.length - 1
                                ? () => _pageController.nextPage(
                                      duration:
                                          const Duration(milliseconds: 250),
                                      curve: Curves.easeOut,
                                    )
                                : null,
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
