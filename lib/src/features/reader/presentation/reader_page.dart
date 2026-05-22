import 'package:flutter/material.dart';

import '../data/models/chapter_request.dart';
import '../data/models/reader_chapter_content.dart';
import '../data/reader_repository.dart';

class ReaderPage extends StatefulWidget {
  const ReaderPage({super.key, required this.request});

  final ChapterRequest request;

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  final _repo = ReaderRepository();
  late Future<ReaderChapterContent> _future = _repo.fetchChapterContent(widget.request);
  bool _showRaw = false;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('Chapter ${widget.request.chapterNo}')),
        body: FutureBuilder<ReaderChapterContent>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final contentData = snap.data;
            final hasRaw = contentData?.hasRaw == true;
            final content = _showRaw && hasRaw
                ? contentData!.raw!.trim()
                : contentData?.translated.trim().isNotEmpty == true
                    ? contentData!.translated.trim()
                    : 'No chapter text available.';
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (hasRaw) ...[
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(value: false, label: Text('Translated'), icon: Icon(Icons.translate)),
                      ButtonSegment<bool>(value: true, label: Text('Raw'), icon: Icon(Icons.code)),
                    ],
                    selected: <bool>{_showRaw},
                    onSelectionChanged: (selection) {
                      setState(() => _showRaw = selection.first);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
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