import 'package:flutter/material.dart';

import '../../../extensions/models/content_item.dart';
import '../../../extensions/models/content_source.dart';
import '../../../extensions/registry/source_registry.dart';
import 'anime_player_page.dart';
import 'manga_reader_page.dart';

/// Entry point for all content viewing.
/// Routes to the correct viewer based on the active source type:
///   - [SourceType.novel]  → scrollable text reader
///   - [SourceType.manga]  → [MangaReaderPage] (photo_view gallery)
///   - [SourceType.anime]  → [AnimePlayerPage] (chewie video player)
class ReaderPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final sourceType = SourceRegistry.instance.active.type;

    return switch (sourceType) {
      SourceType.manga => MangaReaderPage(
          item: item,
          chapterId: chapterId,
          chapterNo: chapterNo,
          chapterTitle: chapterTitle,
        ),
      SourceType.anime => AnimePlayerPage(
          item: item,
          episodeId: chapterId,
          episodeNo: chapterNo,
          episodeTitle: chapterTitle,
        ),
      _ => _NovelReaderPage(
          item: item,
          chapterId: chapterId,
          chapterNo: chapterNo,
          chapterTitle: chapterTitle,
        ),
    };
  }
}

// ── Novel text reader ──────────────────────────────────────────────────────────

class _NovelReaderPage extends StatefulWidget {
  const _NovelReaderPage({
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
              ],
            );
          },
        ),
      );
}
