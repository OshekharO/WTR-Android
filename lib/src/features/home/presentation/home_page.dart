import 'package:flutter/material.dart';

import '../../detail/presentation/detail_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _books = [
    _Book('Future Daughters Show Up', 'Super dad system • Chapter 1 ready', 70381, 39133649),
    _Book('Popular Translated Novel', 'Demo detail and similar section', 70381, 39133649),
    _Book('Recently Updated', 'Continue reading from latest chapter', 70381, 39133649),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WTR Home')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Featured', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          for (final book in _books)
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.menu_book)),
                title: Text(book.title),
                subtitle: Text(book.subtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailPage(book: book))),
              ),
            ),
        ],
      ),
    );
  }
}

class _Book {
  const _Book(this.title, this.subtitle, this.rawId, this.chapterId);
  final String title;
  final String subtitle;
  final int rawId;
  final int chapterId;
}
