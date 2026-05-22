import 'package:flutter/material.dart';

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
            return Column(children: books.map((b) => Card(child: ListTile(leading: const Icon(Icons.menu_book), title: Text(b.title), subtitle: Text(b.author), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsPage(book: b)))))).toList());
          },
        )
      ]);
}
