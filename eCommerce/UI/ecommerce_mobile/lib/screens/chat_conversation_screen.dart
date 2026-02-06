import 'dart:async';

import 'package:ecommerce_mobile/model/chat_models.dart';
import 'package:ecommerce_mobile/providers/chat_provider.dart';
import 'package:ecommerce_mobile/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatConversationScreen extends StatefulWidget {
  final ChatConversation? conversation;
  final int? restaurantId;
  final String? restaurantName;

  const ChatConversationScreen({
    super.key,
    this.conversation,
    this.restaurantId,
    this.restaurantName,
  }) : assert(conversation != null || restaurantId != null,
            'Either conversation or restaurantId must be provided');

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  static const _pollInterval = Duration(seconds: 2);

  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  Timer? _pollTimer;
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;

  List<ChatMessage> _messages = [];
  int? _lastMessageId;

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) async {
      await _pollNewMessages();
    });
  }

  Future<void> _loadInitial() async {
    if (widget.conversation == null) {
      // No conversation yet, just show empty state
      setState(() {
        _isLoading = false;
        _messages = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final msgs = await ChatProvider.getMessages(
        widget.conversation!.id,
        page: 0,
        pageSize: 50,
      );
      if (!mounted) return;
      setState(() {
        _messages = msgs;
        _lastMessageId = msgs.isNotEmpty ? msgs.last.id : null;
        _isLoading = false;
      });
      await ChatProvider.markRead(widget.conversation!.id);
      _scrollToBottom(animated: false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _pollNewMessages() async {
    if (widget.conversation == null) return; // No conversation yet, skip polling

    try {
      final afterId = _lastMessageId;
      final newMsgs = await ChatProvider.getMessages(
        widget.conversation!.id,
        afterId: afterId,
        pageSize: 200,
      );
      if (!mounted) return;
      if (newMsgs.isEmpty) return;
      setState(() {
        _messages.addAll(newMsgs);
        _lastMessageId = _messages.isNotEmpty ? _messages.last.id : afterId;
      });
      await ChatProvider.markRead(widget.conversation!.id);
      _scrollToBottom(animated: true);
    } catch (_) {
      // silent polling failures
    }
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      ChatMessage msg;
      int? conversationId;

      if (widget.conversation == null && widget.restaurantId != null) {
        // First message - create conversation
        msg = await ChatProvider.sendFirstMessage(widget.restaurantId!, text);
        conversationId = msg.conversationId;
        
        // Reload conversation to get full details
        final convo = await ChatProvider.getConversation(widget.restaurantId!);
        if (!mounted) return;
        
        // Update widget state by replacing the screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ChatConversationScreen(
              conversation: convo,
              restaurantId: widget.restaurantId,
              restaurantName: widget.restaurantName,
            ),
          ),
        );
        return;
      } else if (widget.conversation != null) {
        // Existing conversation
        msg = await ChatProvider.sendMessage(widget.conversation!.id, text);
        conversationId = msg.conversationId;
      } else {
        throw Exception('Cannot send message: no conversation or restaurant ID');
      }

      if (!mounted) return;
      setState(() {
        _messages.add(msg);
        _lastMessageId = msg.id;
        _messageController.clear();
        _isSending = false;
      });
      _scrollToBottom(animated: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error sending: $e')));
    }
  }

  void _scrollToBottom({required bool animated}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final offset = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(offset);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        foregroundColor: const Color(0xFF4A4A4A),
        elevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.conversation?.restaurantName ?? widget.restaurantName ?? 'Restaurant',
              style: kScreenTitleStyle,
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(19),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: kScreenTitleUnderline(margin: EdgeInsets.zero),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _error!,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _loadInitial,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _messages.isEmpty
                        ? const Center(
                            child: Text(
                              'No messages yet.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              return _MessageBubble(message: _messages[index]);
                            },
                          ),
          ),
          _Composer(
            controller: _messageController,
            isSending: _isSending,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isMine = !message.isFromRestaurant;
    final bg = isMine ? const Color(0xFF8B7355) : const Color(0xFFF7F7F5);
    final fg = isMine ? Colors.white : const Color(0xFF4A4A4A);
    final align = isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(14),
      topRight: const Radius.circular(14),
      bottomLeft: Radius.circular(isMine ? 14 : 4),
      bottomRight: Radius.circular(isMine ? 4 : 14),
    );

    final time = DateFormat('h:mm a').format(message.sentAt.toLocal());

    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          constraints:
              BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: radius,
          ),
          child: Column(
            crossAxisAlignment: align,
            children: [
              Text(
                message.messageText,
                style: TextStyle(color: fg, fontSize: 14, height: 1.2),
              ),
              const SizedBox(height: 6),
              Text(
                time,
                style: TextStyle(
                  color: isMine ? Colors.white70 : Colors.grey[700],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  filled: true,
                  fillColor: const Color(0xFFF3F3F0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 46,
              width: 46,
              child: ElevatedButton(
                onPressed: isSending ? null : onSend,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B7355),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

