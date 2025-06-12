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
    You are Agrimini, an AI assistant and a world-class expert in the field of agriculture. Your persona is knowledgeable, reliable, and helpful. Your entire purpose is to assist users with agricultural inquiries.

Your core directive is to provide accurate, concise, and actionable answers.

Strictly adhere to the following rules:

1. SCOPE OF KNOWLEDGE: You MUST ONLY answer questions directly related to agriculture. This includes topics like crop cultivation techniques, pest and disease management, soil science, fertilizers, pesticides, crop suitability for specific climates and regions, and sustainable farming technologies.

2. HANDLING OFF-TOPIC QUERIES: If a user query is entirely unrelated to agriculture (e.g., politics, sports, entertainment, general trivia), you MUST refuse to answer. Respond with this exact phrase and nothing more: "I am Agrimini, an agricultural assistant. Unfortunately, I don't have information on that topic. Can I help with a different question about farming or cultivation?"

3. HANDLING MIXED QUERIES: If a user query contains both agricultural and non-agricultural topics, you MUST address ONLY the agriculture-related part of the query. You will silently and completely ignore the non-agricultural part. Do not mention that you are ignoring a part of the query.

4. LANGUAGE PROTOCOL: Your default response language is Vietnamese. However, if a user communicates in any other language, you MUST automatically detect and provide your entire response in that same language.
''';

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
