import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce_desktop/providers/menu_item_provider.dart';
import 'package:ecommerce_desktop/providers/special_offer_provider.dart';
import 'package:ecommerce_desktop/models/menu_item_model.dart';
import 'package:ecommerce_desktop/models/special_offer_model.dart';
import 'package:ecommerce_desktop/model/search_result.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';

class MenuScreen extends StatefulWidget {
  final int restaurantId;

  const MenuScreen({
    super.key,
    required this.restaurantId,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _expandedCategories = <String>{};
  final Set<String> _expandedSpecialCategories = <String>{};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleCategory(String category) {
    setState(() {
      if (_expandedCategories.contains(category)) {
        _expandedCategories.remove(category);
      } else {
        _expandedCategories.add(category);
      }
    });
  }

  void _toggleSpecialCategory(String category) {
    setState(() {
      if (_expandedSpecialCategories.contains(category)) {
        _expandedSpecialCategories.remove(category);
      } else {
        _expandedSpecialCategories.add(category);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: ChangeNotifierProvider(
        create: (_) => MenuItemProvider()..loadMenuItems(widget.restaurantId),
        child: Consumer<MenuItemProvider>(
          builder: (context, provider, child) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with title
                  const Text(
                    'Menu Management',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A4A4A),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Tabs
                  TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFF8B6F47),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: const Color(0xFF8B6F47),
                    tabs: const [
                      Tab(text: 'Menu Items'),
                      Tab(text: 'Daily Specials'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Tab content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Menu Items Tab
                        ChangeNotifierProvider.value(
                          value: provider,
                          child: Consumer<MenuItemProvider>(
                            builder: (context, menuProvider, child) {
                              return Column(
                                children: [
                                  // Add Item button
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: ElevatedButton.icon(
                                        onPressed: () => _showAddItemDialog(context, menuProvider, null),
                                        icon: const Icon(Icons.add, color: Colors.white),
                                        label: const Text(
                                          'Add Item',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF8B6F47),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Menu items list
                                  Expanded(
                                    child: menuProvider.isLoading
                                        ? const Center(child: CircularProgressIndicator())
                                        : menuProvider.error != null
                                            ? Center(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      'Error: ${menuProvider.error}',
                                                      style: const TextStyle(color: Colors.red),
                                                    ),
                                                    const SizedBox(height: 16),
                                                    ElevatedButton(
                                                      onPressed: () => menuProvider.loadMenuItems(widget.restaurantId),
                                                      child: const Text('Retry'),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : menuProvider.menuItems.isEmpty
                                                ? const Center(
                                                    child: Text(
                                                      'No menu items found',
                                                      style: TextStyle(fontSize: 16),
                                                    ),
                                                  )
                                                : RefreshIndicator(
                                                    onRefresh: () => menuProvider.loadMenuItems(widget.restaurantId),
                                                    child: _buildMenuItemsByCategory(context, menuProvider),
                                                  ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        // Daily Specials Tab
                        ChangeNotifierProvider(
                          create: (_) => SpecialOfferProvider()..loadSpecialOffers(widget.restaurantId),
                          child: Consumer<SpecialOfferProvider>(
                            builder: (context, specialProvider, child) {
                              return Column(
                                children: [
                                  // Add Special button
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: ElevatedButton.icon(
                                        onPressed: () => _showAddSpecialDialog(context, specialProvider, null),
                                        icon: const Icon(Icons.add, color: Colors.white),
                                        label: const Text(
                                          'Add Special',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF8B6F47),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Specials list
                                  Expanded(
                                    child: specialProvider.isLoading
                                        ? const Center(child: CircularProgressIndicator())
                                        : specialProvider.error != null
                                            ? Center(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      'Error: ${specialProvider.error}',
                                                      style: const TextStyle(color: Colors.red),
                                                    ),
                                                    const SizedBox(height: 16),
                                                    ElevatedButton(
                                                      onPressed: () => specialProvider.loadSpecialOffers(widget.restaurantId),
                                                      child: const Text('Retry'),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : specialProvider.specialOffers.isEmpty
                                                ? const Center(
                                                    child: Text(
                                                      'No specials found',
                                                      style: TextStyle(fontSize: 16),
                                                    ),
                                                  )
                                                : RefreshIndicator(
                                                    onRefresh: () => specialProvider.loadSpecialOffers(widget.restaurantId),
                                                    child: _buildSpecialOffersByCategory(context, specialProvider),
                                                  ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMenuItemsByCategory(
      BuildContext context, MenuItemProvider provider) {
    // Group menu items by category
    final Map<String, List<MenuItem>> itemsByCategory = {};
    
    for (var item in provider.menuItems) {
      final category = item.category ?? 'Uncategorized';
      if (!itemsByCategory.containsKey(category)) {
        itemsByCategory[category] = [];
      }
      itemsByCategory[category]!.add(item);
    }
    
    // Sort categories alphabetically
    final sortedCategories = itemsByCategory.keys.toList()..sort((a, b) {
      final aDisplay = _getCategoryDisplayName(a);
      final bDisplay = _getCategoryDisplayName(b);
      return aDisplay.compareTo(bDisplay);
    });
    
    return ListView.builder(
      itemCount: sortedCategories.length,
      itemBuilder: (context, index) {
        final category = sortedCategories[index];
        final categoryItems = itemsByCategory[category]!;
        final isExpanded = _expandedCategories.contains(category);
        final categoryDisplayName = _getCategoryDisplayName(category);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header
            InkWell(
              onTap: () => _toggleCategory(category),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: EdgeInsets.only(bottom: 8, top: index == 0 ? 0 : 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B6F47).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF8B6F47).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        categoryDisplayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A4A4A),
                        ),
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: const Color(0xFF8B6F47),
                    ),
                  ],
                ),
              ),
            ),
            // Menu items for this category
            if (isExpanded)
              ...categoryItems.map((item) => _buildMenuItemCard(context, provider, item)),
          ],
        );
      },
    );
  }

  Widget _buildMenuItemCard(
      BuildContext context, MenuItemProvider provider, MenuItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              bottomLeft: Radius.circular(8),
            ),
            child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                ? _buildImageWidget(item.imageUrl!)
                : Container(
                    width: 120,
                    height: 120,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, size: 48),
                  ),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getCategoryDisplayName(item.category),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${item.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8B6F47),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xFF8B6F47)),
                  onPressed: () => _showAddItemDialog(context, provider, item),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteDialog(context, provider, item),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(String imageUrl) {
    // Check if it's a base64 data URL
    if (imageUrl.startsWith('data:image/')) {
      try {
        final base64String = imageUrl.split(',')[1];
        return Image.memory(
          base64Decode(base64String),
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 120,
              height: 120,
              color: Colors.grey[300],
              child: const Icon(Icons.image, size: 48),
            );
          },
        );
      } catch (e) {
        return Container(
          width: 120,
          height: 120,
          color: Colors.grey[300],
          child: const Icon(Icons.image, size: 48),
        );
      }
    } else {
      // Regular HTTP/HTTPS URL
      return Image.network(
        imageUrl,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 120,
            height: 120,
            color: Colors.grey[300],
            child: const Icon(Icons.image, size: 48),
          );
        },
      );
    }
  }

  String _getCategoryDisplayName(String? category) {
    if (category == null) return 'Uncategorized';
    // Convert enum values to display names
    switch (category.toLowerCase()) {
      case 'appetizer':
        return 'Appetizer';
      case 'maincourse':
        return 'Mains';
      case 'dessert':
        return 'Desserts';
      case 'beverage':
        return 'Beverages';
      case 'salad':
        return 'Starters';
      case 'soup':
        return 'Soup';
      case 'sidedish':
        return 'Side Dish';
      case 'breakfast':
        return 'Breakfast';
      case 'lunch':
        return 'Lunch';
      case 'dinner':
        return 'Dinner';
      default:
        return category;
    }
  }

  int? _categoryStringToEnum(String? categoryStr) {
    if (categoryStr == null) return null;
    switch (categoryStr.toLowerCase()) {
      case 'appetizer': 
        return 0;
      case 'maincourse': 
        return 1;
      case 'dessert': 
        return 2;
      case 'beverage': 
        return 3;
      case 'salad': 
        return 4;
      case 'soup': 
        return 5;
      case 'sidedish': 
        return 6;
      case 'breakfast': 
        return 7;
      case 'lunch': 
        return 8;
      case 'dinner': 
        return 9;
      default: 
        return null;
    }
  }

  int _allergenStringToEnum(String? allergenStr) {
    if (allergenStr == null || allergenStr.isEmpty || allergenStr.toLowerCase() == 'none') {
      return 0;
    }
    int value = 0;
    switch (allergenStr.toLowerCase()) {
      case 'gluten': value = 1; break;
      case 'crustaceans': value = 2; break;
      case 'eggs': value = 4; break;
      case 'fish': value = 8; break;
      case 'peanuts': value = 16; break;
      case 'soybeans': value = 32; break;
      case 'milk': value = 64; break;
      case 'nuts': value = 128; break;
      case 'celery': value = 256; break;
      case 'mustard': value = 512; break;
      case 'sesame': value = 1024; break;
      case 'sulfites': value = 2048; break;
      case 'lupin': value = 4096; break;
      case 'molluscs': value = 8192; break;
      default: value = 0;
    }
    return value;
  }

  void _showAddItemDialog(
      BuildContext context, MenuItemProvider provider, MenuItem? item) {
    final nameController = TextEditingController(text: item?.name ?? '');
    final descriptionController = TextEditingController(text: item?.description ?? '');
    final priceController = TextEditingController(text: item?.price.toStringAsFixed(2) ?? '0.00');
    final imageUrlController = TextEditingController(text: item?.imageUrl ?? '');
    
    // For storing selected file
    File? selectedImageFile;
    String? selectedImageDataUrl;

    // Initialize category - convert to dropdown format
    String? selectedCategory;
    if (item?.category != null) {
      // Convert backend category format to dropdown format
      final cat = item!.category!.toLowerCase();
      switch (cat) {
        case 'appetizer': selectedCategory = 'Appetizer'; break;
        case 'maincourse': selectedCategory = 'MainCourse'; break;
        case 'dessert': selectedCategory = 'Dessert'; break;
        case 'beverage': selectedCategory = 'Beverage'; break;
        case 'salad': selectedCategory = 'Salad'; break;
        case 'soup': selectedCategory = 'Soup'; break;
        case 'sidedish': selectedCategory = 'SideDish'; break;
        case 'breakfast': selectedCategory = 'Breakfast'; break;
        case 'lunch': selectedCategory = 'Lunch'; break;
        case 'dinner': selectedCategory = 'Dinner'; break;
        default: selectedCategory = item.category; break;
      }
    }
    
    // Extract first allergen from comma-separated string, or use 'None'
    String? selectedAllergen;
    if (item?.allergens != null && item!.allergens!.isNotEmpty) {
      final allergenList = item.allergens!.split(',').map((e) => e.trim()).toList();
      if (allergenList.isNotEmpty && allergenList.first.toLowerCase() != 'none') {
        // Capitalize first letter to match dropdown values
        final allergen = allergenList.first;
        selectedAllergen = allergen.substring(0, 1).toUpperCase() + allergen.substring(1).toLowerCase();
      } else {
        selectedAllergen = 'None';
      }
    } else {
      selectedAllergen = 'None';
    }

    final categories = [
      'Appetizer',
      'MainCourse',
      'Dessert',
      'Beverage',
      'Salad',
      'Soup',
      'SideDish',
      'Breakfast',
      'Lunch',
      'Dinner',
    ];

    final allergens = [
      'None',
      'Gluten',
      'Crustaceans',
      'Eggs',
      'Fish',
      'Peanuts',
      'Soybeans',
      'Milk',
      'Nuts',
      'Celery',
      'Mustard',
      'Sesame',
      'Sulfites',
      'Lupin',
      'Molluscs',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item == null ? 'Add New Menu Item' : 'Edit Menu Item'),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item Name
                  const Text(
                    'Item Name *',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      hintText: 'e.g., Margherita Pizza',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Category
                  const Text(
                    'Category *',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      hintText: 'e.g., Mains, Starters, Desserts',
                      border: OutlineInputBorder(),
                    ),
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(_getCategoryDisplayName(category.toLowerCase())),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Describe the dish...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Price
                  const Text(
                    'Price *',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      hintText: '0.00',
                      border: OutlineInputBorder(),
                    ),
                    onTap: () {
                      if (priceController.text == '0.00') {
                        priceController.selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: priceController.text.length,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  // Image
                  const Text(
                    'Image',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  // Preview of selected or existing image
                  Container(
                    height: 150,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: selectedImageFile != null
                          ? Image.file(
                              selectedImageFile!,
                              fit: BoxFit.cover,
                            )
                          : selectedImageDataUrl != null
                              ? Image.memory(
                                  base64Decode(selectedImageDataUrl!.split(',')[1]),
                                  fit: BoxFit.cover,
                                )
                              : item?.imageUrl != null && item!.imageUrl!.isNotEmpty
                                  ? Image.network(
                                      item.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Center(
                                          child: Icon(Icons.image, size: 48),
                                        );
                                      },
                                    )
                                  : const Center(
                                      child: Icon(Icons.image, size: 48, color: Colors.grey),
                                    ),
                    ),
                  ),
                  // File picker button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        debugPrint('Choose file button pressed');
                        try {
                          // Use rootNavigator to ensure file picker works from dialog
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.image,
                            allowMultiple: false,
                            withData: false,
                            withReadStream: false,
                          );

                          debugPrint('File picker result: $result');
                          
                          if (result != null && result.files.isNotEmpty) {
                            final filePath = result.files.single.path;
                            debugPrint('Selected file path: $filePath');
                            
                            if (filePath != null) {
                              final file = File(filePath);
                              final originalBytes = await file.readAsBytes();
                              
                              // Decode and compress image
                              final decodedImage = img.decodeImage(originalBytes);
                              if (decodedImage != null) {
                                // Start with aggressive compression - max 300px on longest side
                                img.Image resized = decodedImage;
                                if (decodedImage.width > 300 || decodedImage.height > 300) {
                                  if (decodedImage.width > decodedImage.height) {
                                    resized = img.copyResize(decodedImage, width: 300);
                                  } else {
                                    resized = img.copyResize(decodedImage, height: 300);
                                  }
                                }
                                
                                // Encode as JPEG with quality 60 to minimize size
                                Uint8List compressedBytes = Uint8List.fromList(
                                  img.encodeJpg(resized, quality: 60)
                                );
                                String dataUrl = 'data:image/jpeg;base64,${base64Encode(compressedBytes)}';
                                
                                debugPrint('Original size: ${originalBytes.length} bytes');
                                debugPrint('Compressed size: ${compressedBytes.length} bytes');
                                debugPrint('Base64 URL length: ${dataUrl.length} characters');
                                
                                setState(() {
                                  selectedImageFile = file;
                                  selectedImageDataUrl = dataUrl;
                                  imageUrlController.text = dataUrl;
                                });
                              } else {
                                throw Exception('Could not decode image');
                              }
                            }
                          }
                        } catch (e, stackTrace) {
                          debugPrint('Error picking image: $e');
                          debugPrint('Stack trace: $stackTrace');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error picking image: $e'),
                                duration: const Duration(seconds: 5),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.image, size: 20),
                      label: const Text('Choose Image File'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B6F47),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (selectedImageFile != null || selectedImageDataUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              selectedImageFile = null;
                              selectedImageDataUrl = null;
                              imageUrlController.text = item?.imageUrl ?? '';
                            });
                          },
                          icon: const Icon(Icons.clear, size: 16),
                          label: const Text('Clear selected image'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Dietary & Allergen Information
                  const Text(
                    'Dietary & Allergen Information',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedAllergen,
                    decoration: const InputDecoration(
                      hintText: 'Select allergen',
                      border: OutlineInputBorder(),
                    ),
                    items: allergens.map((allergen) {
                      return DropdownMenuItem(
                        value: allergen,
                        child: Text(allergen),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedAllergen = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (nameController.text.isEmpty || selectedCategory == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all required fields'),
                    ),
                  );
                  return;
                }

                try {
                  final price = double.tryParse(priceController.text) ?? 0.0;
                  
                  // Convert category string to enum int (dropdown uses capitalized format)
                  int? categoryInt = selectedCategory != null 
                      ? _categoryStringToEnum(selectedCategory?.toLowerCase()) 
                      : null;
                  
                  // Convert allergen string to enum int
                  int allergenInt = _allergenStringToEnum(selectedAllergen);
                  
                  // Get imageUrl
                  String? imageUrl = imageUrlController.text.isEmpty
                      ? null
                      : imageUrlController.text;
                  
                  final request = {
                    'restaurantId': widget.restaurantId,
                    'name': nameController.text,
                    'description': descriptionController.text.isEmpty
                        ? null
                        : descriptionController.text,
                    'price': price,
                    'category': categoryInt,
                    'allergens': allergenInt,
                    'imageUrl': imageUrl,
                    'isAvailable': true,
                  };

                  debugPrint('Sending request: $request');
                  
                  if (item == null) {
                    await provider.insert(request);
                  } else {
                    await provider.updateItem(item.id, request);
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                    provider.loadMenuItems(widget.restaurantId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(item == null ? 'Menu item added successfully' : 'Menu item updated successfully'),
                      ),
                    );
                  }
                } catch (e, stackTrace) {
                  debugPrint('Error saving menu item: $e');
                  debugPrint('Stack trace: $stackTrace');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.add, color: Colors.white, size: 18),
              label: Text(item == null ? 'Add Item' : 'Update Item'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B6F47),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialOffersByCategory(
      BuildContext context, SpecialOfferProvider provider) {
    final now = DateTime.now();
    
    // Group special offers by Active/Expired
    final List<SpecialOffer> activeSpecials = [];
    final List<SpecialOffer> expiredSpecials = [];
    
    for (var special in provider.specialOffers) {
      if (special.validTo.isBefore(now)) {
        expiredSpecials.add(special);
      } else {
        activeSpecials.add(special);
      }
    }
    
    final categories = <String, List<SpecialOffer>>{
      'Active': activeSpecials,
      'Expired': expiredSpecials,
    };
    
    // Always show Active first, then Expired
    final sortedCategories = ['Active', 'Expired'];
    
    return ListView.builder(
      itemCount: sortedCategories.length,
      itemBuilder: (context, index) {
        final categoryName = sortedCategories[index];
        final categoryItems = categories[categoryName]!;
        final isExpanded = _expandedSpecialCategories.contains(categoryName);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header
            InkWell(
              onTap: () => _toggleSpecialCategory(categoryName),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: EdgeInsets.only(bottom: 8, top: index == 0 ? 0 : 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B6F47).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF8B6F47).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        categoryName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A4A4A),
                        ),
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: const Color(0xFF8B6F47),
                    ),
                  ],
                ),
              ),
            ),
            // Special offers for this category
            if (isExpanded)
              ...categoryItems.map((special) => _buildSpecialOfferCard(context, provider, special)),
          ],
        );
      },
    );
  }

  Widget _buildSpecialOfferCard(
      BuildContext context, SpecialOfferProvider provider, SpecialOffer special) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    special.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (special.description != null && special.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      special.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '\$${special.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: special.validTo.isBefore(DateTime.now()) 
                          ? Colors.grey 
                          : const Color(0xFF8B6F47),
                    ),
                  ),
                  // Status indicator
                  if (special.validTo.isBefore(DateTime.now()))
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Expired',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Valid until label
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Valid until ${DateFormat('MMM d, yyyy').format(special.validTo)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ),
            // Action buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.edit, 
                    color: special.validTo.isBefore(DateTime.now()) 
                        ? Colors.grey 
                        : const Color(0xFF8B6F47),
                  ),
                  onPressed: special.validTo.isBefore(DateTime.now())
                      ? null
                      : () => _showAddSpecialDialog(context, provider, special),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteSpecialDialog(context, provider, special),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSpecialDialog(
      BuildContext context, SpecialOfferProvider provider, SpecialOffer? special) {
    final titleController = TextEditingController(text: special?.title ?? '');
    final descriptionController = TextEditingController(text: special?.description ?? '');
    final priceController = TextEditingController(text: special?.price.toStringAsFixed(2) ?? '0.00');
    
    DateTime? validFrom = special?.validFrom ?? DateTime.now();
    DateTime? validTo = special?.validTo ?? DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(special == null ? 'Add New Special' : 'Edit Special'),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  const Text(
                    'Title *',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      hintText: 'e.g., Weekend Brunch Special',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Describe the special...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Discount/Price
                  const Text(
                    'Price *',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      hintText: '0.00',
                      border: OutlineInputBorder(),
                    ),
                    onTap: () {
                      if (priceController.text == '0.00') {
                        priceController.selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: priceController.text.length,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  // Valid From
                  const Text(
                    'Valid From *',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: validFrom ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                      );
                      if (date != null) {
                        setState(() {
                          validFrom = date;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        validFrom != null
                            ? DateFormat('MMM d, yyyy').format(validFrom!)
                            : 'Select date',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Valid To
                  const Text(
                    'Valid To *',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: validTo ?? DateTime.now().add(const Duration(days: 30)),
                        firstDate: validFrom ?? DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                      );
                      if (date != null) {
                        setState(() {
                          validTo = date;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        validTo != null
                            ? DateFormat('MMM d, yyyy').format(validTo!)
                            : 'Select date',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (titleController.text.isEmpty || validFrom == null || validTo == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all required fields'),
                    ),
                  );
                  return;
                }

                try {
                  final price = double.tryParse(priceController.text) ?? 0.0;
                  
                  final request = {
                    'restaurantId': widget.restaurantId,
                    'title': titleController.text,
                    'description': descriptionController.text.isEmpty
                        ? null
                        : descriptionController.text,
                    'price': price,
                    'validFrom': validFrom!.toIso8601String(),
                    'validTo': validTo!.toIso8601String(),
                    'isActive': true,
                  };

                  if (special == null) {
                    await provider.insert(request);
                  } else {
                    await provider.updateItem(special.id, request);
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                    provider.loadSpecialOffers(widget.restaurantId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(special == null ? 'Special added successfully' : 'Special updated successfully'),
                      ),
                    );
                  }
                } catch (e, stackTrace) {
                  debugPrint('Error saving special: $e');
                  debugPrint('Stack trace: $stackTrace');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.add, color: Colors.white, size: 18),
              label: Text(special == null ? 'Add Special' : 'Update Special'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B6F47),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteSpecialDialog(
      BuildContext context, SpecialOfferProvider provider, SpecialOffer special) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Special'),
        content: Text('Are you sure you want to delete "${special.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await provider.delete(special.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  provider.loadSpecialOffers(widget.restaurantId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Special deleted successfully'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting special: $e'),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
      BuildContext context, MenuItemProvider provider, MenuItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Menu Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await provider.delete(item.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  provider.loadMenuItems(widget.restaurantId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Menu item deleted successfully'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting item: $e'),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
