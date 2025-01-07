import 'package:flutter/material.dart';

class SearchResultsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> results;

  const SearchResultsScreen({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Search Results")),
      body: results.isEmpty
          ? const Center(child: Text("No matching locations found."))
          : ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                final location = results[index];
                return ListTile(
                  title: Text(location['locationName']),
                  subtitle: Text(location['description']),
                  trailing: Image.network(location['imageURL']),
                );
              },
            ),
    );
  }
}
