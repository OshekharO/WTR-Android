import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  double _fontSize = 16.0;
  static const _prefsKey = 'reader_font_size';
  static const _prefsKeyLineHeight = 'reader_line_height';
  
  double _lineHeight = 1.7;
  

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      final v = prefs.getDouble(_prefsKey);
      if (v != null && mounted) {
        setState(() => _fontSize = v);
      }
      final lh = prefs.getDouble(_prefsKeyLineHeight);
      if (mounted) {
        setState(() {
          if (lh != null) _lineHeight = lh;
        });
      }
      
    });
  }

  Future<void> _saveFontSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_prefsKey, _fontSize);
    } catch (_) {}
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_prefsKey, _fontSize);
      await prefs.setDouble(_prefsKeyLineHeight, _lineHeight);
      
    } catch (_) {}
  }

  Future<void> _increaseFont() async {
    setState(() {
      _fontSize = (_fontSize + 2).clamp(10.0, 40.0).toDouble();
    });
    await _saveSettings();
  }

  Future<void> _decreaseFont() async {
    setState(() {
      _fontSize = (_fontSize - 2).clamp(10.0, 40.0).toDouble();
    });
    await _saveSettings();
  }

  void _resetSettings() {
    setState(() {
      _fontSize = 16.0;
      _lineHeight = 1.7;
    });
    _saveSettings();
  }

  void _showDisplaySettings() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          String _lineHeightLabel() {
            final lh = _lineHeight;
            if (lh == null) return 'Default';
            try {
              // Avoid calling double -> toString directly to prevent JS interop issues.
              final v10 = (lh * 10).round();
              if (v10 == 17) return 'Default';
              final whole = v10 ~/ 10;
              final frac = v10 % 10;
              return frac == 0 ? '$whole' : '$whole.$frac';
            } catch (_) {
              return 'Default';
            }
          }
          void changeLineHeight(double delta) {
            setModalState(() => _lineHeight = (_lineHeight + delta).clamp(1.0, 2.5).toDouble());
            setState(() {});
            _saveSettings();
          }

          

          // reset is handled via a shared method below

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                const Text('FONT SIZE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          await _decreaseFont();
                          setModalState(() {});
                        },
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8), minimumSize: const Size(0, 36)),
                        child: const Text('A-', style: TextStyle(fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Center(child: Text('${_fontSize.toInt()}', style: const TextStyle(fontSize: 14))),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          await _increaseFont();
                          setModalState(() {});
                        },
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8), minimumSize: const Size(0, 36)),
                        child: const Text('A+', style: TextStyle(fontSize: 13)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Text('LINE HEIGHT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => changeLineHeight(-0.1),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8), minimumSize: const Size(0, 36)),
                        child: const Text('Height -', style: TextStyle(fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Center(child: Text(_lineHeightLabel(), style: const TextStyle(fontSize: 14))),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => changeLineHeight(0.1),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8), minimumSize: const Size(0, 36)),
                        child: const Text('Height +', style: TextStyle(fontSize: 13)),
                      ),
                    ),
                  ],
                ),

                

                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // Reset to defaults
                          setModalState(() {
                            _fontSize = 16.0;
                            _lineHeight = 1.7;
                          });
                          setState(() {});
                          _saveSettings();
                        },
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10), minimumSize: const Size(0, 40)),
                        child: const Text('Reset', style: TextStyle(fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10), minimumSize: const Size(0, 40)),
                        child: const Text('Done', style: TextStyle(fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

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
              tooltip: 'Display settings',
              onPressed: _showDisplaySettings,
              icon: const Icon(Icons.text_fields),
            ),
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
                  style: _effectiveTextStyle(context, _lineHeight, _fontSize),
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

TextStyle? _effectiveTextStyle(BuildContext context, double lineHeight, double fontSize) {
  return Theme.of(context).textTheme.bodyLarge?.copyWith(
        height: lineHeight,
        fontSize: fontSize,
      );
}
