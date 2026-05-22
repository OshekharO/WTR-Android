import 'package:flutter/material.dart';

import '../data/models/chapter_request.dart';
import '../data/reader_repository.dart';

class ReaderPage extends StatefulWidget {
  const ReaderPage({super.key, required this.request});

  final ChapterRequest request;

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  final _repo = ReaderRepository();
  late Future<String> _future = _repo.fetchChapterText(widget.request);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('Chapter ${widget.request.chapterNo}')),
        body: FutureBuilder<String>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final content = snap.data?.trim().isNotEmpty == true ? snap.data!.trim() : 'No chapter text available.';
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Chapter ${widget.request.chapterNo}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(content, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6)),
              ],
            );
          },
        ),
      );
}