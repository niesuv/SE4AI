// lib/services/chat_service.dart

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatService {
  late final Dio _dio;
  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  ChatService() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://generativelanguage.googleapis.com/',
      headers: {
        'Content-Type': 'application/json',
      },
    ));
  }

  Future<String> sendMessage(String question) async {
    const String modelId = 'gemini-2.5-flash-preview-05-20';

    final systemPrompt = '''
Bạn là trợ lý chuyên về nông nghiệp. Chỉ trả lời các câu hỏi về bệnh cây trồng và loại cây trong dữ liệu đã cho. Nếu người dùng hỏi ngoài phạm vi này, hãy trả lời: "Xin lỗi, tôi chỉ hỗ trợ về nông nghiệp."''';

    final payload = {
      'contents': [
        {'role': 'user', 'parts': [{'text': systemPrompt}]},
        {'role': 'user', 'parts': [{'text': question}]},
      ],
      'generationConfig': {
        'temperature': 0.2,
        'maxOutputTokens': 1024,  // tăng lên để tránh cắt chữ
      },
    };

    try {
      final resp = await _dio.post(
        '/v1beta/models/$modelId:generateContent',
        queryParameters: {'key': _apiKey},
        data: payload,
      );

      // Lấy danh sách candidates, rồi ghép hết các parts lại
      final cands = resp.data['candidates'] as List<dynamic>?;
      if (cands != null && cands.isNotEmpty) {
        final parts = cands[0]['content']['parts'] as List<dynamic>?;
        if (parts != null && parts.isNotEmpty) {
          // Ghép tất cả parts thành 1 chuỗi
          final text = parts.map((p) => p['text'] as String).join(' ');
          return text;
        }
      }
      // Không có response như mong muốn, trả plain text trống
      return '';
    } on DioException catch (e) {
      // Trả lời thật plain text, không JSON
      return e.message ?? 'Đã xảy ra lỗi khi gọi API.';
    } catch (e) {
      return '$e';
    }
  }
}
