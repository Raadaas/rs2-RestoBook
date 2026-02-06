import 'package:ecommerce_mobile/model/restaurant.dart';
import 'package:ecommerce_mobile/providers/chat_provider.dart';
import 'package:ecommerce_mobile/providers/restaurant_provider.dart';
import 'package:ecommerce_mobile/screens/chat_conversation_screen.dart';
import 'package:ecommerce_mobile/app_styles.dart';
import 'package:flutter/material.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final _searchController = TextEditingController();
  final RestaurantProvider _restaurantProvider = RestaurantProvider();

  bool _isSearching = false;
  String? _error;
  List<Restaurant> _results = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchController.text.trim();
    if (q.isEmpty) {
      setState(() {
        _isSearching = false;
        _error = null;
        _results = [];
      });
      return;
    }

    if (q.length < 3) {
      setState(() {
        _isSearching = false;
        _error = null;
        _results = [];
      });
      return;
    }

    _searchRestaurants(q);
  }

  Future<void> _searchRestaurants(String query) async {
    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      final result = await _restaurantProvider.get(
        filter: {
          'isActive': true,
          'name': query,
          // fetch a bit more in case paging applies
          'page': 0,
          'pageSize': 25,
          'includeTotalCount': false,
          'retrieveAll': false,
        },
      );

      if (!mounted) return;
      setState(() {
        _results = result.items ?? [];
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isSearching = false;
      });
    }
  }

  Future<void> _openConversation(Restaurant restaurant) async {
    try {
      final convo = await ChatProvider.getConversation(restaurant.id);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatConversationScreen(
            conversation: convo,
            restaurantId: restaurant.id,
            restaurantName: restaurant.name,
          ),
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, true); // tell chat list to refresh
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting chat: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _searchController.text.trim();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        foregroundColor: const Color(0xFF333333),
        title: const Text('New message', style: kScreenTitleStyle),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search restaurants...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFF3F3F0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : q.isEmpty
                        ? const Center(
                            child: Text(
                              'Type to search restaurants.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : q.length < 3
                            ? const Center(
                                child: Text(
                                  'Type at least 3 characters.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : _results.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No restaurants found.',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: _results.length,
                                    separatorBuilder: (_, __) => Divider(
                                      height: 1,
                                      color: Colors.grey.shade200,
                                    ),
                                    itemBuilder: (context, index) {
                                      final r = _results[index];
                                      final avatarText = r.name.trim().isNotEmpty
                                          ? r.name.trim()[0].toUpperCase()
                                          : '?';
                                      return ListTile(
                                        onTap: () => _openConversation(r),
                                        leading: CircleAvatar(
                                          radius: 22,
                                          backgroundColor:
                                              const Color(0xFFF0EAE2),
                                          child: Text(
                                            avatarText,
                                            style: const TextStyle(
                                              color: Color(0xFF8B7355),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          r.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF4A4A4A),
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${r.cityName} • ${r.cuisineTypeName}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        trailing: const Icon(
                                          Icons.chevron_right,
                                          color: Color(0xFF8B7355),
                                        ),
                                      );
                                    },
                                  ),
          ),
        ],
      ),
    );
  }
}

