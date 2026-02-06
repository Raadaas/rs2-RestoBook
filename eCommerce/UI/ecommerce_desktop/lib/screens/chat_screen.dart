import 'dart:async';

import 'package:ecommerce_desktop/models/chat_models.dart';
import 'package:ecommerce_desktop/services/chat_service.dart';
import 'package:ecommerce_desktop/widgets/screen_title_header.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final int restaurantId;

  const ChatScreen({
    super.key,
    required this.restaurantId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const _pollInterval = Duration(seconds: 2);

  final _searchController = TextEditingController();
  final _messageController = TextEditingController();
  final _messagesScrollController = ScrollController();

  Timer? _pollTimer;

  bool _isLoadingConversations = true;
  String? _error;

  List<ChatConversation> _conversations = [];
  List<ChatConversation> _filteredConversations = [];

  ChatConversation? _selectedConversation;
  List<ChatMessage> _messages = [];
  int? _lastMessageId;
  bool _isSending = false;
  bool _isLoadingMessages = false;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _searchController.addListener(_applySearch);
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _searchController.dispose();
    _messageController.dispose();
    _messagesScrollController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) async {
      await _refreshConversationsSilently();
      if (_selectedConversation != null) {
        await _pollNewMessages();
      }
    });
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoadingConversations = true;
      _error = null;
    });

    try {
      final list =
          await ChatService.getRestaurantConversations(widget.restaurantId);
      if (!mounted) return;
      setState(() {
        _conversations = list;
        _filteredConversations = _filterBySearch(list, _searchController.text);
        _isLoadingConversations = false;

        // keep selection if still present
        if (_selectedConversation != null) {
          final stillThere = _conversations
              .firstWhere((c) => c.id == _selectedConversation!.id, orElse: () => _selectedConversation!);
          _selectedConversation = stillThere.id == _selectedConversation!.id
              ? stillThere
              : null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoadingConversations = false;
      });
    }
  }

  Future<void> _refreshConversationsSilently() async {
    try {
      final list =
          await ChatService.getRestaurantConversations(widget.restaurantId);
      if (!mounted) return;
      setState(() {
        _conversations = list;
        _filteredConversations = _filterBySearch(list, _searchController.text);
        if (_selectedConversation != null) {
          final idx = _conversations
              .indexWhere((c) => c.id == _selectedConversation!.id);
          if (idx != -1) {
            _selectedConversation = _conversations[idx];
          }
        }
      });
    } catch (_) {
      // silent
    }
  }

  void _applySearch() {
    setState(() {
      _filteredConversations =
          _filterBySearch(_conversations, _searchController.text);
    });
  }

  List<ChatConversation> _filterBySearch(
      List<ChatConversation> conversations, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return conversations;
    return conversations
        .where((c) =>
            c.userName.toLowerCase().contains(q) ||
            (c.lastMessageText ?? '').toLowerCase().contains(q))
        .toList();
  }

  Future<void> _selectConversation(ChatConversation convo) async {
    setState(() {
      _selectedConversation = convo;
      _messages = [];
      _lastMessageId = null;
      _isLoadingMessages = true;
    });

    try {
      final msgs = await ChatService.getMessages(convo.id, page: 0, pageSize: 50);
      if (!mounted) return;
      setState(() {
        _messages = msgs;
        _lastMessageId = msgs.isNotEmpty ? msgs.last.id : null;
        _isLoadingMessages = false;
      });
      await ChatService.markRead(convo.id);
      await _refreshConversationsSilently();
      _scrollToBottom(animated: false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMessages = false;
      });
      _showSnack('Error loading messages: $e');
    }
  }

  Future<void> _pollNewMessages() async {
    final convo = _selectedConversation;
    if (convo == null) return;

    try {
      final afterId = _lastMessageId;
      final newMsgs = await ChatService.getMessages(
        convo.id,
        afterId: afterId,
        pageSize: 200,
      );
      if (!mounted) return;
      if (newMsgs.isEmpty) return;
      setState(() {
        _messages.addAll(newMsgs);
        _lastMessageId = _messages.isNotEmpty ? _messages.last.id : afterId;
      });
      await ChatService.markRead(convo.id);
      await _refreshConversationsSilently();
      _scrollToBottom(animated: true);
    } catch (_) {
      // silent
    }
  }

  Future<void> _sendMessage() async {
    final convo = _selectedConversation;
    if (convo == null) return;

    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      final msg = await ChatService.sendMessage(convo.id, text);
      if (!mounted) return;
      setState(() {
        _messages.add(msg);
        _lastMessageId = msg.id;
        _messageController.clear();
        _isSending = false;
      });
      await _refreshConversationsSilently();
      _scrollToBottom(animated: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
      });
      _showSnack('Error sending message: $e');
    }
  }


  void _scrollToBottom({required bool animated}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_messagesScrollController.hasClients) return;
      final position = _messagesScrollController.position.maxScrollExtent;
      if (animated) {
        _messagesScrollController.animateTo(
          position,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } else {
        _messagesScrollController.jumpTo(position);
      }
    });
  }

  void _showSnack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  int get _totalUnread =>
      _conversations.fold<int>(0, (sum, c) => sum + (c.unreadCount));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenTitleHeader(
              title: 'Chat',
              subtitle: 'Conversations with guests',
              icon: Icons.chat_rounded,
              trailing: _totalUnread > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B7355),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '$_totalUnread new',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                children: [
                  _buildLeftPane(),
                  const SizedBox(width: 16),
                  Expanded(child: _buildRightPane()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftPane() {
    return SizedBox(
      width: 360,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Messages',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A4A4A),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _loadConversations,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search conversations...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _isLoadingConversations
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Error: $_error',
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _loadConversations,
                                  child: const Text('Retry'),
                                )
                              ],
                            ),
                          )
                        : _filteredConversations.isEmpty
                            ? const Center(
                                child: Text(
                                  'No conversations yet.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.separated(
                                itemCount: _filteredConversations.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final c = _filteredConversations[index];
                                  final isSelected =
                                      _selectedConversation?.id == c.id;
                                  return _buildConversationTile(c, isSelected);
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConversationTile(ChatConversation c, bool isSelected) {
    final avatarText =
        c.userName.trim().isNotEmpty ? c.userName.trim()[0].toUpperCase() : '?';
    final preview = (c.lastMessageText ?? '').trim();
    final timeAgo = _timeAgo(c.lastMessageAt);

    return InkWell(
      onTap: () => _selectConversation(c),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B7355).withOpacity(0.08) : null,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF8B7355).withOpacity(0.5)
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF8B7355),
              child: Text(
                avatarText,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A4A4A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    preview.isEmpty ? '—' : preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeAgo,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                if (c.unreadCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B7355),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      c.unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRightPane() {
    if (_selectedConversation == null) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Center(
          child: Text(
            'Select a conversation to start chatting.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _buildChatHeader(),
          const Divider(height: 1),
          Expanded(child: _buildMessages()),
          const Divider(height: 1),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildChatHeader() {
    final c = _selectedConversation!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF8B7355),
            child: Text(
              c.userName.trim().isNotEmpty
                  ? c.userName.trim()[0].toUpperCase()
                  : '?',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.userName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4A4A4A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    if (_isLoadingMessages) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_messages.isEmpty) {
      return const Center(
        child: Text(
          'No messages yet.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      controller: _messagesScrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final m = _messages[index];
        return _buildMessageBubble(m);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage m) {
    final isMine = m.isFromRestaurant;
    final bg = isMine ? const Color(0xFF8B7355) : Colors.white;
    final fg = isMine ? Colors.white : const Color(0xFF4A4A4A);
    final align = isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(12),
      topRight: const Radius.circular(12),
      bottomLeft: Radius.circular(isMine ? 12 : 2),
      bottomRight: Radius.circular(isMine ? 2 : 12),
    );

    final time = DateFormat('HH:mm').format(m.sentAt.toLocal());

    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: radius,
            border: isMine ? null : Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: align,
            children: [
              Text(
                m.messageText,
                style: TextStyle(color: fg, fontSize: 14, height: 1.2),
              ),
              const SizedBox(height: 6),
              Text(
                time,
                style: TextStyle(
                  color: isMine ? Colors.white70 : Colors.grey[600],
                  fontSize: 11,
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildComposer() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 46,
            width: 46,
            child: ElevatedButton(
              onPressed: _isSending ? null : _sendMessage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B7355),
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSending
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
    );
  }

  String _timeAgo(DateTime dt) {
    // Both dates are already in local time from the model
    final now = DateTime.now();
    final ts = dt.isUtc ? dt.toLocal() : dt;
    final diff = now.difference(ts);
    
    if (diff.inSeconds < 60) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} ${diff.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    if (diff.inHours < 24) return '${diff.inHours} ${diff.inHours == 1 ? 'hour' : 'hours'} ago';
    if (diff.inDays < 30) return '${diff.inDays} ${diff.inDays == 1 ? 'day' : 'days'} ago';
    
    // Calculate months - difference in calendar months
    int months = (now.year - ts.year) * 12 + (now.month - ts.month);
    // Adjust if current day is before the day of the month in the past date
    if (now.day < ts.day) {
      months--;
    }
    if (months < 12) {
      return '${months} ${months == 1 ? 'month' : 'months'} ago';
    }
    
    // Calculate years
    int years = now.year - ts.year;
    if (now.month < ts.month || (now.month == ts.month && now.day < ts.day)) {
      years--;
    }
    return '${years} ${years == 1 ? 'year' : 'years'} ago';
  }
}

