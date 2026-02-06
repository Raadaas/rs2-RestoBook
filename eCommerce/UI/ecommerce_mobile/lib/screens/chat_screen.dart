import 'dart:async';

import 'package:ecommerce_mobile/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:ecommerce_mobile/model/chat_models.dart';
import 'package:ecommerce_mobile/providers/chat_provider.dart';
import 'package:ecommerce_mobile/screens/chat_conversation_screen.dart';
import 'package:ecommerce_mobile/screens/new_chat_screen.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const _pollInterval = Duration(seconds: 2);

  Timer? _pollTimer;
  bool _isLoading = true;
  String? _error;
  List<ChatConversation> _conversations = [];

  @override
  void initState() {
    super.initState();
    _load();
  }


  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) async {
      if (!_isLoading) {
        await _refreshSilently();
      }
    });
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await ChatProvider.getMyConversations();
      if (!mounted) return;
      setState(() {
        _conversations = list;
        _isLoading = false;
      });
      // Start polling after initial load completes
      if (_pollTimer == null) {
        _startPolling();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshSilently() async {
    if (_isLoading) return; // Don't refresh while loading
    try {
      final list = await ChatProvider.getMyConversations();
      if (!mounted) return;
      setState(() {
        _conversations = list;
      });
    } catch (_) {
      // Silent refresh failures
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text('Messages', style: kScreenTitleStyle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(19),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: kScreenTitleUnderline(margin: EdgeInsets.zero),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              final didStart = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const NewChatScreen()),
              );
              if (didStart == true) {
                _load();
              }
            },
            icon: const Icon(Icons.add, color: Color(0xFF4A4A4A)),
            tooltip: 'New message',
          ),
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh, color: Color(0xFF4A4A4A)),
            tooltip: 'Refresh',
          )
        ],
      ),
      body: _isLoading
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
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _conversations.isEmpty
                  ? const Center(
                      child: Text(
                        'No messages yet.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        itemCount: _conversations.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: Colors.grey.shade200,
                        ),
                        itemBuilder: (context, index) {
                          final c = _conversations[index];
                          return _ConversationTile(
                            conversation: c,
                            onTap: () async {
                              await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatConversationScreen(
                                      conversation: c),
                                ),
                              );
                              // reload list to update unread counts / lastMessageAt
                              _load();
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ChatConversation conversation;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatarText = conversation.restaurantName.trim().isNotEmpty
        ? conversation.restaurantName.trim()[0].toUpperCase()
        : '?';
    final preview = (conversation.lastMessageText ?? '').trim();
    final time = _timeAgo(conversation.lastMessageAt);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: const Color(0xFFF0EAE2),
        child: Text(
          avatarText,
          style: const TextStyle(
            color: Color(0xFF8B7355),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: Text(
        conversation.restaurantName,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Color(0xFF4A4A4A),
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          preview.isEmpty ? '—' : preview,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey[600]),
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            time,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 6),
          if (conversation.unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF8B7355),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                conversation.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
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
