import 'package:flutter/material.dart';

import '../../reader/data/models/chapter_request.dart';
import '../../reader/presentation/reader_page.dart';

class DetailPage extends StatelessWidget {
  const DetailPage({super.key, required this.book});

  final dynamic book;

  @override
  Widget build(BuildContext context) {
    final title = book.title as String;
    final rawId = book.rawId as int;
    final chapterId = book.chapterId as int;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: const Center(child: Icon(Icons.auto_stories, size: 72)),
          ),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('AI translated web novel reader demo using WTR chapter API. Detail, chapter list, and similar sections are ready for real API mapping.'),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('Read Chapter 1'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReaderPage(
                  request: ChapterRequest(
                    translate: 'ai',
                    language: 'en',
                    rawId: rawId,
                    chapterNo: 1,
                    retry: false,
                    forceRetry: false,
                    chapterId: chapterId,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Chapters', style: Theme.of(context).textTheme.titleLarge),
          Card(child: ListTile(title: const Text('Chapter 1'), subtitle: const Text('Available'), onTap: () {})),
          const SizedBox(height: 24),
          Text('Similar', style: Theme.of(context).textTheme.titleLarge),
          const Card(child: ListTile(leading: Icon(Icons.book), title: Text('Another Super Dad Novel'), subtitle: Text('Similar theme'))),
          const Card(child: ListTile(leading: Icon(Icons.book), title: Text('Future Family System'), subtitle: Text('System + family genre'))),
        ],
      ),
    );
  }
}
