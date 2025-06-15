import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agri_helper/provider/disease_provider.dart';
import '../models/disease.dart';
import 'disease_detail_screen.dart';

class DiseaseWikiScreen extends ConsumerWidget {
  const DiseaseWikiScreen({Key? key}) : super(key: key);

  static const Map<String, String> _keyAliases = {
    'mango': 'Mango_Fruit',
  };

  static const Map<String, String> _plantNames = {
    'Apple': 'Táo',
    'Banana': 'Chuối',
    'Corn_(maize)': 'Ngô',
    'Durian': 'Sầu riêng',
    'Grape': 'Nho',
    'Mango_Fruit': 'Xoài',
    'Orange': 'Cam',
    'Peach': 'Đào',
    'Pepper_bell': 'Ớt chuông',
    'Potato': 'Khoai tây',
    'Rice': 'Lúa',
    'Strawberry': 'Dâu tây',
    'Tomato': 'Cà chua',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(diseasesProvider);

    return Scaffold(
      body: SafeArea(
        child: asyncList.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Lỗi: $e')),
          data: (all) {
            final Map<String, List<Disease>> grouped = {};
            for (final d in all) {
              final rawKey = d.id.split('___').first;
              final normKey = _keyAliases[rawKey] ?? rawKey;
              grouped.putIfAbsent(normKey, () => []).add(d);
            }

            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: grouped.entries.map((entry) {
                final key = entry.key;
                final displayName = _plantNames[key] ?? key.replaceAll('_', ' ');
                final assetPath = 'assets/plants/$key.png';

                return ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: SizedBox(
                    width: 32,
                    height: 32,
                    child: Image.asset(
                      assetPath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.local_florist),
                    ),
                  ),
                  title: Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  childrenPadding: const EdgeInsets.only(left: 56),
                  children: entry.value.map((d) {
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      leading: d.imageBase64.isNotEmpty
                          ? Image.memory(
                        d.imageBytes,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      )
                          : const Icon(Icons.local_florist),
                      title: Text(d.name),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DiseaseDetailScreen(disease: d),
                        ),
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
