// lib/screen/chat_bot_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';

class ChatBotScreen extends ConsumerStatefulWidget {
  const ChatBotScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends ConsumerState<ChatBotScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _ctrl = TextEditingController();
  final ChatService _chatService = ChatService();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _loading = false;

  @override
  bool get wantKeepAlive => true;

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text, true));
      _loading = true;
      _ctrl.clear();
    });
    _scrollToEnd();

    final reply = await _chatService.sendMessage(text);
    setState(() {
      _messages.add(ChatMessage(reply, false));
      _loading = false;
    });
    _scrollToEnd();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      body: SafeArea(
        child: Column(
          children: [
            // Chat area or welcome screen
            Expanded(
              child: _messages.isEmpty && !_loading
                  ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/Hi_AI.png',
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                ],
              )
                  : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _messages.length,
                itemBuilder: (ctx, i) {
                  final m = _messages[i];
                  return Align(
                    alignment: m.fromUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: m.fromUser
                            ? Colors.green.shade100
                            : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(12),
                          topRight: const Radius.circular(12),
                          bottomLeft: m.fromUser
                              ? const Radius.circular(12)
                              : Radius.zero,
                          bottomRight: m.fromUser
                              ? Radius.zero
                              : const Radius.circular(12),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 2,
                            offset: Offset(1, 1),
                          )
                        ],
                      ),
                      child: MarkdownBody(
                        data: m.text,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(
                              fontSize: 14, height: 1.4),
                          strong: const TextStyle(
                              fontWeight: FontWeight.bold),
                          em: const TextStyle(
                              fontStyle: FontStyle.italic),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Loading indicator
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: CircularProgressIndicator(),
              ),

            // Input bar
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn cho AI...',
                        contentPadding:
                        const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        fillColor: Colors.grey[200],
                        filled: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _loading ? null : _send,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
