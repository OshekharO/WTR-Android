import 'package:flutter/material.dart';

import '../../../extensions/models/chapter_item.dart';
import '../../../extensions/models/content_item.dart';
import '../../../extensions/models/content_source.dart';
import '../../../extensions/registry/source_registry.dart';
import '../../reader/presentation/reader_page.dart';

class ChapterListPage extends StatefulWidget {
  const ChapterListPage({super.key, required this.item});

  final ContentItem item;

  @override
  State<ChapterListPage> createState() => _ChapterListPageState();
}

class _ChapterListPageState extends State<ChapterListPage> {
  final _source = SourceRegistry.instance.active;
  late final Future<List<ChapterItem>> _future =
      _source.getChapters(widget.item);

  bool get _isAnime => _source.type == SourceType.anime;

  String get _unitLabel => _isAnime ? 'Episode' : 'Chapter';
  String get _listLabel => _isAnime ? 'Episodes' : 'Chapters';

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('${widget.item.title} — $_listLabel'),
        ),
        body: FutureBuilder<List<ChapterItem>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final chapters = snap.data ?? const [];
            if (chapters.isEmpty) {
              return Center(
                child: Text('No $_listLabel available.'),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: chapters.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final c = chapters[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${c.number}')),
                    title: Text(c.title.isNotEmpty
                        ? c.title
                        : '$_unitLabel ${c.number}'),
                    subtitle: c.updatedAt != null
                        ? Text(MaterialLocalizations.of(context)
                            .formatShortDate(c.updatedAt!))
                        : Text('Tap to ${_isAnime ? 'watch' : 'read'}'),
                    trailing: Icon(
                      _isAnime
                          ? Icons.play_circle_outline_rounded
                          : Icons.menu_book_outlined,
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReaderPage(
                          item: widget.item,
                          chapterId: c.id,
                          chapterNo: c.number,
                          chapterTitle: c.title,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
}
