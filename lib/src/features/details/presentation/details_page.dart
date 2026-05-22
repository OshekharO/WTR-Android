import 'package:flutter/material.dart';
import '../../chapter_list/presentation/chapter_list_page.dart';

class DetailsPage extends StatelessWidget {
  const DetailsPage({super.key, required this.title, this.author = 'Unknown', this.description = 'Novel details and chapter information.'});
  final String title, author, description;
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(title)), body: ListView(padding: const EdgeInsets.all(16), children: [Container(height: 180, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(24)), child: const Icon(Icons.auto_stories, size: 72)), const SizedBox(height: 16), Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)), Text('by $author'), const SizedBox(height: 12), Text(description), const SizedBox(height: 20), FilledButton.icon(icon: const Icon(Icons.list), label: const Text('View Chapters'), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChapterListPage(bookTitle: title))))]));
}
