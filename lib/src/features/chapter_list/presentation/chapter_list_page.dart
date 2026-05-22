import 'package:flutter/material.dart';
import '../../reader/data/models/chapter_request.dart';
import '../../reader/presentation/reader_page.dart';

class ChapterListPage extends StatelessWidget {
  const ChapterListPage({super.key, required this.bookTitle});
  final String bookTitle;
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('$bookTitle Chapters')), body: ListView.separated(padding: const EdgeInsets.all(16), itemCount: 20, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (context, i) { final no = i + 1; return Card(child: ListTile(leading: CircleAvatar(child: Text('$no')), title: Text('Chapter $no'), subtitle: const Text('Tap to read'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReaderPage(request: ChapterRequest(translate: 'ai', language: 'en', rawId: 70381, chapterNo: no, retry: false, forceRetry: false, chapterId: 39133649))))); }));
}
