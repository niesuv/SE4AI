import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../models/disease.dart';
import '../provider/disease_provider.dart';
import 'disease_detail_screen.dart';

class DiseaseWikiScreen extends ConsumerWidget {
  const DiseaseWikiScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(diseasesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Wiki Bệnh Cây Trồng')),
      body: asyncList.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (all) => Padding(
          padding: const EdgeInsets.all(16),
          child: TypeAheadField<Disease>(
            textFieldConfiguration: const TextFieldConfiguration(
              decoration: InputDecoration(
                hintText: 'Nhập tên bệnh...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            suggestionsCallback: (p) => all
                .where((d) =>
                d.name.toLowerCase().contains(p.toLowerCase()))
                .toList(),
            itemBuilder: (_, d) => ListTile(
              leading: d.imageBase64.isNotEmpty
                  ? Image.memory(d.imageBytes,
                  width: 50, height: 50, fit: BoxFit.cover)
                  : const Icon(Icons.local_florist),
              title: Text(d.name),
            ),
            onSuggestionSelected: (d) => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DiseaseDetailScreen(disease: d),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
