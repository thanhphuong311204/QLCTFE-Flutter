import 'package:flutter/material.dart';
import 'package:qlctfe/core/services/assistant_service.dart';

class AssistantChatScreen extends StatefulWidget {
  const AssistantChatScreen({super.key});

  @override
  State<AssistantChatScreen> createState() => _AssistantChatScreenState();
}

class _AssistantChatScreenState extends State<AssistantChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> _messages = [];
  bool _loading = false;

  /// ⚙️ Chế độ trợ lý (gentle / neutral / savage)
  String currentMode = "neutral";

  /// ⭐ TỰ CUỘN XUỐNG CUỐI TIN NHẮN
  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// 🚀 GỬI TIN NHẮN
  void sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "text": text});
      _controller.clear();
      _loading = true;
    });

    scrollToBottom();

    final reply = await AssistantService().askAssistant(text, currentMode);

    setState(() {
      _messages.add({"role": "assistant", "text": reply});
      _loading = false;
    });

    scrollToBottom();
  }

  /// 💬 Bubble chat UI
  Widget chatBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isUser ? Colors.orange.shade300 : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 15),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🤖 Trợ lý ảo tài chính"),
        backgroundColor: Colors.orange,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: DropdownButton<String>(
              dropdownColor: Colors.white,
              value: currentMode,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(
                    value: "gentle", child: Text("😇 Nhẹ nhàng")),
                DropdownMenuItem(
                    value: "neutral", child: Text("🙂 Trung lập")),
                DropdownMenuItem(
                    value: "savage", child: Text("😈 Gắt")),
              ],
              onChanged: (value) {
                setState(() {
                  currentMode = value!;
                });
              },
            ),
          ),
        ],
      ),

      // 📌 Nội dung chính
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return chatBubble(
                  msg["text"]!,
                  msg["role"] == "user",
                );
              },
            ),
          ),

          if (_loading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                "🤖 Trợ lý đang trả lời...",
                style: TextStyle(color: Colors.grey),
              ),
            ),

          // ✏️ Ô nhập tin nhắn
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Nhập câu hỏi…",
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // 📤 Nút gửi
                GestureDetector(
                  onTap: sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
