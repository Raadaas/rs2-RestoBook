import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ecommerce_desktop/models/reward_model.dart';
import 'package:ecommerce_desktop/providers/reward_provider.dart';

class CreateRewardScreen extends StatefulWidget {
  final int restaurantId;
  final Reward? reward;

  const CreateRewardScreen({
    super.key,
    required this.restaurantId,
    this.reward,
  });

  @override
  State<CreateRewardScreen> createState() => _CreateRewardScreenState();
}

class _CreateRewardScreenState extends State<CreateRewardScreen> {
  final _formKey = GlobalKey<FormState>();
  final RewardProvider _rewardProvider = RewardProvider();
  
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _pointsController;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.reward?.title ?? '');
    _descriptionController = TextEditingController(text: widget.reward?.description ?? '');
    _pointsController = TextEditingController(
      text: widget.reward?.pointsRequired?.toString() ?? '',
    );
    _isActive = widget.reward?.isActive ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _saveReward() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'pointsRequired': int.parse(_pointsController.text),
        'restaurantId': widget.restaurantId,
        'isActive': _isActive,
      };

      if (widget.reward != null) {
        await _rewardProvider.update(widget.reward!.id!, request);
      } else {
        await _rewardProvider.insert(request);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.reward != null
                  ? 'Reward updated successfully'
                  : 'Reward created successfully',
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save reward: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.reward != null;
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF8B7355), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red[400]!, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF4A4A4A), size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEdit ? 'Edit Reward' : 'Create New Reward',
          style: const TextStyle(
            color: Color(0xFF4A4A4A),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reward Details Card
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B7355).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.card_giftcard_rounded,
                            color: Color(0xFF8B7355),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Text(
                          'Reward Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A4A4A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    TextFormField(
                      controller: _titleController,
                      decoration: inputDecoration.copyWith(
                        labelText: 'Reward Name',
                        hintText: 'e.g., Free Dessert',
                        prefixIcon: Icon(Icons.card_giftcard_rounded, color: Colors.grey[500], size: 22),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a reward name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _pointsController,
                      decoration: inputDecoration.copyWith(
                        labelText: 'Points Required',
                        hintText: 'e.g., 200',
                        prefixIcon: Icon(Icons.stars_rounded, color: Colors.grey[500], size: 22),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter points required';
                        }
                        final points = int.tryParse(value);
                        if (points == null || points <= 0) {
                          return 'Please enter a valid number greater than 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _descriptionController,
                      decoration: inputDecoration.copyWith(
                        labelText: 'Reward Description',
                        hintText: 'Describe what customers get...',
                        prefixIcon: Icon(Icons.description_rounded, color: Colors.grey[500], size: 22),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SwitchListTile(
                        title: const Text(
                          'Active',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Customers can redeem this reward when active',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                        value: _isActive,
                        onChanged: (value) => setState(() => _isActive = value),
                        activeColor: const Color(0xFF8B7355),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    child: Text('Cancel', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveReward,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B7355),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      shadowColor: const Color(0xFF8B7355).withOpacity(0.4),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(isEdit ? Icons.check_rounded : Icons.add_rounded, size: 20),
                              const SizedBox(width: 10),
                              Text(isEdit ? 'Update Reward' : 'Save Reward'),
                            ],
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
