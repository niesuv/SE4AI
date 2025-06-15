import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/disease.dart';

final diseasesProvider = FutureProvider<List<Disease>>((ref) async {
  final raw = await rootBundle.loadString('assets/final_2_with_thumbs.json');
  final Map<String, dynamic> map = json.decode(raw);
  return map.entries
      .map((e) => Disease.fromJson(e.key, e.value as Map<String, dynamic>))
      .toList();
});
