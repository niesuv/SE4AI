import 'package:flutter/material.dart';
import '../models/disease.dart';

class DiseaseDetailScreen extends StatelessWidget {
  final Disease disease;
  const DiseaseDetailScreen({required this.disease, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(disease.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: disease.imageBase64.isNotEmpty
                ? Image.memory(disease.imageBytes,
                height: 200, width: double.infinity, fit: BoxFit.cover)
                : Container(
              height: 200,
              color: Colors.grey[200],
              child: const Icon(Icons.local_florist, size: 100),
            ),
          ),
          const SizedBox(height: 16),
          _section('Mô tả', disease.info),
          _section('Tác hại', disease.harm),
          _section('Nguyên nhân', disease.cause),
          _medsSection('Thuốc gợi ý', disease.meds),
        ]),
      ),
    );
  }

  Widget _section(String t, String c) =>
      c.isEmpty ? const SizedBox.shrink() : Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(c),
        ]),
      );

  Widget _medsSection(String t, List<String> meds) =>
      meds.isEmpty ? const SizedBox.shrink() : Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 4, children: meds.map((m) => Chip(label: Text(m))).toList()),
        ]),
      );
}
