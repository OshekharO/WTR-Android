import 'package:flutter/material.dart';
import 'package:flutter_cors_image/flutter_cors_image.dart';

import '../../books/data/models/book.dart';
import '../../details/presentation/details_page.dart';
import '../data/search_repository.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _repo = SearchRepository();
  late Future<List<Book>> _future = _repo.search('');

  void _onSearch(String q) => setState(() => _future = _repo.search(q));

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
        SearchBar(hintText: 'Search novels...', leading: const Icon(Icons.search), onChanged: _onSearch),
        const SizedBox(height: 16),
        FutureBuilder<List<Book>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            final books = snap.data ?? [];
            return Column(
              children: books
                  .map(
                    (b) => Card(
                      child: ListTile(
                        leading: _CoverThumb(url: b.coverUrl),
                        title: Text(b.title),
                        subtitle: Text(b.author),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsPage(book: b))),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        )
      ]);
}

class _CoverThumb extends StatelessWidget {
  const _CoverThumb({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.trim().isEmpty) {
      return const CircleAvatar(child: Icon(Icons.menu_book));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 48,
        height: 48,
        child: CustomNetworkImage(
          url: url!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorWidget: const CircleAvatar(child: Icon(Icons.menu_book)),
        ),
      ),
    );
  }
}
