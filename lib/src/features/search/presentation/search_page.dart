import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final results = ['Future Daughters Show Up', 'Super Dad System', 'Douluo Fanfic']
        .where((e) => e.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SearchBar(
            hintText: 'Search novels...',
            leading: const Icon(Icons.search),
            onChanged: (value) => setState(() => query = value),
          ),
          const SizedBox(height: 16),
          for (final item in results)
            Card(child: ListTile(leading: const Icon(Icons.menu_book), title: Text(item), subtitle: const Text('Demo search result'))),
        ],
      ),
    );
  }
}
