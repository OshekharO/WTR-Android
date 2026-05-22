import 'package:flutter/material.dart';

import '../../books/data/models/book.dart';
import '../../reader/data/models/chapter_request.dart';
import '../../reader/presentation/reader_page.dart';
import '../data/chapter_list_repository.dart';
import '../data/models/chapter_item.dart';

class ChapterListPage extends StatefulWidget {
  const ChapterListPage({super.key, required this.book});
  final Book book;
  @override
  State<ChapterListPage> createState() => _ChapterListPageState();
}

class _ChapterListPageState extends State<ChapterListPage> {
  final _repo = ChapterListRepository();
  late Future<List<ChapterItem>> _future = _repo.fetchChapters(widget.book.id);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('${widget.book.title} Chapters')),
        body: FutureBuilder<List<ChapterItem>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            final chapters = snap.data ?? [];
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: chapters.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final c = chapters[i];
                return Card(child: ListTile(leading: CircleAvatar(child: Text('${c.number}')), title: Text(c.title), subtitle: const Text('Tap to read'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReaderPage(request: ChapterRequest(translate: 'ai', language: 'en', rawId: widget.book.id, chapterNo: c.number, retry: false, forceRetry: false, chapterId: c.id)))));
              },
            );
          },
        ),
      );
}
