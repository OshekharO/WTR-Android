import 'package:flutter/material.dart';

import '../../books/data/models/book.dart';
import '../../chapter_list/presentation/chapter_list_page.dart';
import '../data/details_repository.dart';

class DetailsPage extends StatefulWidget {
  const DetailsPage({super.key, required this.book});
  final Book book;
  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  final _repo = DetailsRepository();
  late Future<Book> _future = _repo.fetchDetails(widget.book.id, widget.book);

  @override
  Widget build(BuildContext context) => FutureBuilder<Book>(
        future: _future,
        builder: (context, snap) {
          final book = snap.data ?? widget.book;
          return Scaffold(
            appBar: AppBar(title: Text(book.title)),
            body: ListView(padding: const EdgeInsets.all(16), children: [
              Container(height: 180, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(24)), child: const Icon(Icons.auto_stories, size: 72)),
              const SizedBox(height: 16),
              Text(book.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              Text('by ${book.author}'),
              const SizedBox(height: 12),
              Text(book.description),
              const SizedBox(height: 20),
              FilledButton.icon(icon: const Icon(Icons.list), label: const Text('View Chapters'), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChapterListPage(book: book))))
            ]),
          );
        },
      );
}
