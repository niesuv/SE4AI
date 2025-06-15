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
          _medsSection(context, 'Thuốc gợi ý', disease.meds),
        ]),
      ),
    );
  }

  Widget _section(String title, String content) {
    if (content.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(content),
      ]),
    );
  }

  Widget _medsSection(BuildContext context, String title, List<String> meds) {
    if (meds.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: meds.map((m) {
            return ActionChip(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              backgroundColor: Colors.grey[100],
              label: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.4,
                ),
                child: Text(
                  m,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Chi tiết thuốc'),
                    content: Text(m),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Đóng'),
                      ),
                    ],
                  ),
                );
              },
            );
          }).toList(),
        ),
      ]),
    );
  }
}
