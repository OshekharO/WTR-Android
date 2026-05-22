import 'package:flutter/material.dart';
import '../data/models/chapter_request.dart';
import '../data/models/chapter_response.dart';
import '../data/reader_repository.dart';

class ReaderPage extends StatefulWidget {
  const ReaderPage({super.key, this.request});
  final ChapterRequest? request;
  @override State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  final _repo = ReaderRepository();
  late Future<ChapterResponse> _future;
  static const _demo = ChapterRequest(translate: 'ai', language: 'en', rawId: 70381, chapterNo: 1, retry: false, forceRetry: false, chapterId: 39133649);
  ChapterRequest get _request => widget.request ?? _demo;
  @override void initState() { super.initState(); _future = _repo.fetchChapter(_request); }
  Future<void> _refresh() async { setState(() => _future = _repo.fetchChapter(_request)); await _future; }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Reader'), actions: [IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh))]), body: FutureBuilder<ChapterResponse>(future: _future, builder: (context, snap) { if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator()); if (snap.hasError) return Center(child: Text(snap.error.toString(), textAlign: TextAlign.center)); final c = snap.data; return RefreshIndicator(onRefresh: _refresh, child: ListView.separated(padding: const EdgeInsets.all(18), itemCount: (c?.body.length ?? 0) + 1, separatorBuilder: (_, __) => const SizedBox(height: 12), itemBuilder: (_, i) => i == 0 ? Text(c?.title ?? 'Chapter', style: Theme.of(context).textTheme.headlineSmall) : Text(c!.body[i - 1], style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6)))); }));
}
