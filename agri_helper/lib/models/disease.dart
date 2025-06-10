import 'dart:convert';
import 'dart:typed_data';

class Disease {
  final String id;
  final String name;
  final String info;
  final String harm;
  final String cause;
  final List<String> meds;
  final String imageBase64;

  Disease({
    required this.id,
    required this.name,
    required this.info,
    required this.harm,
    required this.cause,
    required this.meds,
    required this.imageBase64,
  });

  factory Disease.fromJson(String id, Map<String, dynamic> json) {
    return Disease(
      id: id,
      name: json['ten_benh'] ?? '',
      info: json['thong_tin_benh'] ?? '',
      harm: json['tac_hai'] ?? '',
      cause: json['nguyen_nhan_gay_benh'] ?? '',
      meds: List<String>.from(json['danh_sach_thuoc_goi_y'] ?? []),
      imageBase64: json['imageBase64'] ?? '',
    );
  }

  Uint8List get imageBytes => base64Decode(imageBase64);
}
