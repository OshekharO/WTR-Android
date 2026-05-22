import 'package:flutter/material.dart';
import '../../details/presentation/details_page.dart';

class SearchPage extends StatefulWidget { const SearchPage({super.key}); @override State<SearchPage> createState() => _SearchPageState(); }
class _SearchPageState extends State<SearchPage> {
  String query = '';
  final books = const ['Future Daughters Show Up', 'Solo Leveling', 'Omniscient Reader', 'The Beginning After The End'];
  @override Widget build(BuildContext context) { final results = books.where((b) => b.toLowerCase().contains(query.toLowerCase())).toList(); return ListView(padding: const EdgeInsets.all(16), children: [SearchBar(hintText: 'Search novels...', leading: const Icon(Icons.search), onChanged: (v) => setState(() => query = v)), const SizedBox(height: 16), for (final b in results) Card(child: ListTile(leading: const Icon(Icons.menu_book), title: Text(b), subtitle: const Text('Search result'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsPage(title: b))))) ]); }
}
