import 'dart:io';
import 'dart:convert';
import 'package:image/image.dart';
import 'package:path/path.dart' as p;

void main() async {
  // Đọc JSON gốc
  final rawJson = await File('assets/final_2.json').readAsString();
  final Map<String, dynamic> diseases = json.decode(rawJson);

  // Duyệt thư mục ảnh
  final imagesDir = Directory('assets/anh_benh');
  final Map<String, String> b64map = {};

  await for (var f in imagesDir.list()) {
    if (f is File && (f.path.endsWith('.png') || f.path.endsWith('.jpg') || f.path.endsWith('.jpeg'))) {
      final bytes = await f.readAsBytes();
      final img = decodeImage(bytes);
      if (img == null) continue;

      // Resize về 200×200
      final thumb = copyResize(img, width: 200, height: 200);

      // Encode lại PNG (hoặc JPEG) rồi Base64
      final thumbBytes = encodePng(thumb);
      final b64 = base64Encode(thumbBytes);

      // Lấy tên file trùng id trong JSON
      final name = p.basenameWithoutExtension(f.path);
      b64map[name] = b64;
    }
  }

  // Nhúng Base64 vào JSON
  final Map<String, dynamic> out = {};
  diseases.forEach((id, data) {
    final map = Map<String, dynamic>.from(data);
    map['imageBase64'] = b64map[id] ?? '';
    out[id] = map;
  });

  // Ghi file mới
  final outFile = File('assets/final_2_with_thumbs.json');
  await outFile.writeAsString(JsonEncoder.withIndent('  ').convert(out));
  print('✅ Tạo assets/final_2_with_thumbs.json với ${out.length} mục');
}
