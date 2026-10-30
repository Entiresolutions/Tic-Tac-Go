import 'package:flutter/material.dart';
import 'package:tic_tac_go/game/caro/caro_controller.dart';
import '../../core/theme/app_colors.dart';

class CaroChatPanel extends StatefulWidget {
  final CaroController controller;

  const CaroChatPanel({super.key, required this.controller});

  @override
  State<CaroChatPanel> createState() => _CaroChatPanelState();
}

class _CaroChatPanelState extends State<CaroChatPanel> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Listen for new messages and rebuild
    widget.controller.addListener(_onChatUpdate);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChatUpdate);
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onChatUpdate() {
    // Rebuild the widget when a new message arrives
    if (mounted) {
      setState(() {});
      // Auto scroll to bottom
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients &&
          _scrollController.position.hasContentDimensions) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    widget.controller.sendChat(text);
    _chatController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final chats = widget.controller.chatMessages;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.draw,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          // 🧠 Header
          Container(
            color: AppColors.primaryLight,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline, size: 18),
                const SizedBox(width: 6),
                Text(
                  "Chat (${chats.length})",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // 🧩 Message list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: chats.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final msg = chats[index];
                final fromUserId = msg["from"];
                final fromMe = fromUserId == widget.controller.myUserId;
                final time =
                    msg["time"]?.toString().split("T").last.split(".").first ??
                    "";

                return Align(
                  alignment: fromMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 10,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: fromMe
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : AppColors.draw,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: fromMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        if (!fromMe)
                          Text(
                            "Opponent",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.draw,
                            ),
                          ),
                        Text(
                          msg["message"] ?? "",
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 📝 Chat input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: AppColors.surface,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: "Enter a message...",
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: Icon(
                    Icons.send_rounded,
                    color: AppColors.primary,
                  ),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
