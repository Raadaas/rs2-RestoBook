import 'package:ecommerce_mobile/model/review.dart';
import 'package:ecommerce_mobile/providers/review_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  List<Review> _reviews = [];
  bool _loading = true;
  String? _error;
  int? _editingReviewId;
  late TextEditingController _editCommentController;
  int _editRating = 5;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _editCommentController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _editCommentController.dispose();
    super.dispose();
  }

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading) setState(() { _loading = true; _error = null; });
    try {
      final provider = context.read<ReviewProvider>();
      final list = await provider.getMyReviews();
      if (!mounted) return;
      setState(() {
        _reviews = list;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _startEdit(Review r) {
    setState(() {
      _editingReviewId = r.id;
      _editCommentController.text = r.comment ?? '';
      _editRating = r.rating;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingReviewId = null;
    });
  }

  Future<void> _saveEdit(Review r) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await context.read<ReviewProvider>().updateReview(
            r,
            rating: _editRating,
            comment: _editCommentController.text.trim().isEmpty
                ? null
                : _editCommentController.text.trim(),
          );
      if (!mounted) return;
      setState(() {
        _editingReviewId = null;
        _saving = false;
      });
      _load(showLoading: false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving: $e')),
      );
    }
  }

  Future<void> _confirmDelete(Review r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete review'),
        content: Text('Delete your review for "${r.restaurantName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<ReviewProvider>().deleteReview(r.id);
      if (!mounted) return;
      _load(showLoading: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Reviews',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!, style: TextStyle(color: Colors.red[700])))
                      : _reviews.isEmpty
                          ? Center(
                              child: Text(
                                'You have not written any reviews yet.',
                                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () => _load(showLoading: false),
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                itemCount: _reviews.length,
                                itemBuilder: (context, i) => _buildReviewCard(_reviews[i]),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(Review r) {
    final isEditing = _editingReviewId == r.id;

    if (isEditing) {
      return _buildEditCard(r);
    }
    return _buildViewCard(r);
  }

  Widget _buildViewCard(Review r) {
    final dateStr = DateFormat('MMM d, yyyy').format(r.createdAt);
    final comment = r.comment ?? 'No comment';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 0,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.star_border, color: Color(0xFF8B7355), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.restaurantName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A4A4A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          ...List.generate(5, (i) => Icon(
                            i < r.rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 16,
                          )),
                          const SizedBox(width: 4),
                          Text(
                            '• $dateStr',
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey[700], size: 22),
                  padding: EdgeInsets.zero,
                  onSelected: (value) {
                    if (value == 'edit') _startEdit(r);
                    if (value == 'delete') _confirmDelete(r);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              comment,
              style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.4),
              maxLines: 10,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditCard(Review r) {
    final dateStr = DateFormat('MMM d, yyyy').format(r.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 0,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.star_border, color: Color(0xFF8B7355), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.restaurantName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A4A4A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• $dateStr',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _editCommentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Your review...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              style: TextStyle(fontSize: 14, color: Colors.grey[800]),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Rating: ', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                ...List.generate(5, (i) => InkWell(
                  onTap: () => setState(() => _editRating = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      i < _editRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 28,
                    ),
                  ),
                )),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _saving ? null : _cancelEdit,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _saving ? null : () => _saveEdit(r),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B7355),
                    foregroundColor: Colors.white,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save changes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
