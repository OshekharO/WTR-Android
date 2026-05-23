import 'package:flutter/material.dart';

import '../../../extensions/models/chapter_item.dart';
import '../../../extensions/models/content_item.dart';
import '../../../extensions/models/content_source.dart';
import '../../../extensions/registry/source_registry.dart';
import 'anime_player_page.dart';
import 'manga_reader_page.dart';

/// Entry point for all content viewing.
/// Routes to the correct viewer based on the active source type:
///   - [SourceType.novel]  → scrollable text reader
///   - [SourceType.manga]  → vertical webtoon reader
///   - [SourceType.anime]  → Chewie video player
class ReaderPage extends StatefulWidget {
  const ReaderPage({
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
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  late final Future<List<ChapterItem>> _chaptersFuture =
      SourceRegistry.instance.active.getChapters(widget.item);

  void _goToChapter(ChapterItem chapter) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ReaderPage(
          item: widget.item,
          chapterId: chapter.id,
          chapterNo: chapter.number,
          chapterTitle: chapter.title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sourceType = SourceRegistry.instance.active.type;

    return FutureBuilder<List<ChapterItem>>(
      future: _chaptersFuture,
      builder: (context, snap) {
        final chapters = snap.data ?? const <ChapterItem>[];
        final currentIndex = chapters.indexWhere(
          (chapter) =>
              chapter.id == widget.chapterId ||
              chapter.number == widget.chapterNo,
        );

        final previousChapter = currentIndex > 0 ? chapters[currentIndex - 1] : null;
        final nextChapter = currentIndex >= 0 && currentIndex < chapters.length - 1
            ? chapters[currentIndex + 1]
            : null;

        return switch (sourceType) {
          SourceType.manga => MangaReaderPage(
              key: ValueKey('manga-${widget.chapterId}-${widget.chapterNo}'),
              item: widget.item,
              chapterId: widget.chapterId,
              chapterNo: widget.chapterNo,
              chapterTitle: widget.chapterTitle,
              previousChapter: previousChapter,
              nextChapter: nextChapter,
              onPrevious: previousChapter == null ? null : () => _goToChapter(previousChapter),
              onNext: nextChapter == null ? null : () => _goToChapter(nextChapter),
            ),
          SourceType.anime => AnimePlayerPage(
              key: ValueKey('anime-${widget.chapterId}-${widget.chapterNo}'),
              item: widget.item,
              episodeId: widget.chapterId,
              episodeNo: widget.chapterNo,
              episodeTitle: widget.chapterTitle,
              previousChapter: previousChapter,
              nextChapter: nextChapter,
              onPrevious: previousChapter == null ? null : () => _goToChapter(previousChapter),
              onNext: nextChapter == null ? null : () => _goToChapter(nextChapter),
            ),
          _ => _NovelReaderPage(
              key: ValueKey('novel-${widget.chapterId}-${widget.chapterNo}'),
              item: widget.item,
              chapterId: widget.chapterId,
              chapterNo: widget.chapterNo,
              chapterTitle: widget.chapterTitle,
              previousChapter: previousChapter,
              nextChapter: nextChapter,
              onPrevious: previousChapter == null ? null : () => _goToChapter(previousChapter),
              onNext: nextChapter == null ? null : () => _goToChapter(nextChapter),
            ),
        };
      },
    );
  }
}

// ── Novel text reader ──────────────────────────────────────────────────────────

class _NovelReaderPage extends StatefulWidget {
  const _NovelReaderPage({
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
  State<_NovelReaderPage> createState() => _NovelReaderPageState();
}

class _NovelReaderPageState extends State<_NovelReaderPage> {
  late final Future<String> _future =
      SourceRegistry.instance.active.getChapterContent(
    item: widget.item,
    chapterId: widget.chapterId,
    chapterNo: widget.chapterNo,
  );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chapter ${widget.chapterNo}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (widget.chapterTitle.isNotEmpty)
                Text(
                  widget.chapterTitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: widget.previousChapter == null
                  ? 'No previous chapter'
                  : 'Previous chapter',
              onPressed: widget.onPrevious,
              icon: const Icon(Icons.skip_previous_rounded),
            ),
            IconButton(
              tooltip: widget.nextChapter == null
                  ? 'No next chapter'
                  : 'Next chapter',
              onPressed: widget.onNext,
              icon: const Icon(Icons.skip_next_rounded),
            ),
          ],
        ),
        body: FutureBuilder<String>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final content = snap.data?.trim().isNotEmpty == true
                ? snap.data!.trim()
                : 'No chapter text available.';

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                Text(
                  'Chapter ${widget.chapterNo}',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (widget.chapterTitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.chapterTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
                const SizedBox(height: 20),
                SelectableText(
                  content,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(height: 1.7),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onPrevious,
                        icon: const Icon(Icons.skip_previous_rounded),
                        label: const Text('Prev'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: widget.onNext,
                        icon: const Icon(Icons.skip_next_rounded),
                        label: const Text('Next'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
}
