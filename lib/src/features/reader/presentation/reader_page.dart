import 'package:flutter/material.dart';

import '../data/models/chapter_request.dart';
import '../data/models/chapter_response.dart';
import '../data/reader_repository.dart';

class ReaderPage extends StatefulWidget {
  const ReaderPage({super.key});

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  final ReaderRepository _repository = ReaderRepository();
  late Future<ChapterResponse> _future;

  static const _demoRequest = ChapterRequest(
    translate: 'ai',
    language: 'en',
    rawId: 70381,
    chapterNo: 1,
    retry: false,
    forceRetry: false,
    chapterId: 39133649,
  );

  @override
  void initState() {
    super.initState();
    _future = _repository.fetchChapter(_demoRequest);
  }

  Future<void> _refresh() async {
    setState(() => _future = _repository.fetchChapter(_demoRequest));
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WTR Reader'),
        actions: [
          IconButton(
            tooltip: 'Reload',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<ChapterResponse>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorView(message: snapshot.error.toString(), onRetry: _refresh);
          }
          final chapter = snapshot.data;
          if (chapter == null || chapter.body.isEmpty) {
            return _ErrorView(message: 'No chapter content found.', onRetry: _refresh);
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
              itemCount: chapter.body.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Text(
                    chapter.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  );
                }
                return Text(
                  chapter.body[index - 1],
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.55),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 42),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
