import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../extensions/models/content_item.dart';
import '../../../extensions/registry/source_registry.dart';

/// Full-screen manga chapter viewer built on [PhotoViewGallery].
/// Supports vertical webtoon-style scrolling through chapter images.
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
                          (context, index) => Image.network(
                            pages[index],
                            width: double.infinity,
                            fit: BoxFit.fitWidth,
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
                              'Webtoon scroll • ${pages.length} pages',
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
