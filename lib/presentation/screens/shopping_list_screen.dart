// shopping_list_screen.dart
// Kullanıcının alışveriş listesi ekranı. Optimizasyon algoritması ile entegre edilmiştir.
// Tema renkleri ve dekoratif kutu ile modern bir görünüm sağlar.

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/optimization_provider.dart';
import '../providers/user_provider.dart';
import '../../data/services/product_data_service.dart';
import '../../data/models/shopping_item.dart';
import '../../data/models/product.dart';
import '../widgets/market_finder_widget.dart';

/// Alışveriş listesi ekranı: Kullanıcı burada optimize edilmiş alışveriş ürünlerini görecek.
class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Tümü';
  List<String> categories = [];

  @override
  void initState() {
    super.initState();
    // Use the actual categories from the product data
    categories = ['Tümü', 'Meyve & Sebze', 'Süt & Kahvaltı', 'Et & Tavuk', 'Bakliyat', 'Temel Gıda'];
    
    // Load shopping list from Firebase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OptimizationProvider>().loadShoppingList();
    });
  }

  void _runOptimization() {
    final userProvider = context.read<UserProvider>();
    final optimizationProvider = context.read<OptimizationProvider>();
    
    if (userProvider.user != null) {
      final products = ProductDataService.getProductsWithNutrition();
      optimizationProvider.runOptimization(
        user: userProvider.user!,
        products: products,
        days: 30,
      );
    }
  }

  // Convert ShoppingItem to Product for MarketFinderWidget
  Product _shoppingItemToProduct(ShoppingItem item) {
    return Product(
      id: int.tryParse(item.id) ?? 0,
      name: item.productName,
      category: item.category,
      mainGroup: item.mainGroup,
      subcategory: item.category, // Use category as subcategory since ShoppingItem doesn't have subcategory
      price: item.price,
      caloriesPer100g: item.calories,
      proteinPer100g: item.protein,
      carbsPer100g: item.carbs,
      fatPer100g: item.fat,
      imageUrl: item.imageUrl,
      market: item.market,
      createdAt: DateTime.now(), // Add the required createdAt parameter
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tema renkleri
    const Color midnightBlue = Color(0xFF2C3E50);
    const Color deepFern = Color(0xFF52796F);
    const Color shoppingColor = Color(0xFFFF6B6B); // Ana sayfa buton rengi
    final Color shoppingLight = shoppingColor.withValues(alpha: 0.15);
    final Color shoppingDark = shoppingColor.withValues(alpha: 0.8);

    return Scaffold(
      backgroundColor: midnightBlue,
      appBar: AppBar(
        backgroundColor: shoppingColor.withValues(alpha: 0.95),
        elevation: 0,
        centerTitle: true,
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, shoppingColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'Alışveriş Listem',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 28,
              letterSpacing: 1.2,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _runOptimization,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: () {
              _showClearListDialog(context);
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [shoppingColor.withValues(alpha: 0.8), midnightBlue],
            stops: const [0.0, 0.6],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Dekoratif arka plan daireleri
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: shoppingLight,
                  ),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: shoppingLight,
                  ),
                ),
              ),
              // Ana içerik
              Column(
                children: [
                  // Arama ve filtre kartı
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: shoppingColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: shoppingLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: shoppingColor.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: shoppingColor.withValues(alpha: 0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.search,
                                color: shoppingColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Optimize Edilmiş Liste',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Consumer<UserProvider>(
                                    builder: (context, userProvider, child) {
                                      final user = userProvider.user;
                                      if (user != null) {
                                        return Text(
                                          '${user.name} • ${user.budget.toStringAsFixed(0)} ₺ bütçe',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.7),
                                            fontSize: 12,
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Ürün ara...',
                            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                            prefixIcon: const Icon(Icons.search, color: Colors.white70),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: shoppingColor.withValues(alpha: 0.3)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: shoppingColor.withValues(alpha: 0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: shoppingColor),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  // Alışveriş listesi
                  Expanded(
                    child: Consumer<OptimizationProvider>(
                      builder: (context, optimizationProvider, child) {
                        if (optimizationProvider.isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: shoppingColor,
                            ),
                          );
                        }

                        if (optimizationProvider.error != null) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: shoppingColor.withValues(alpha: 0.7),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Optimizasyon hatası',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  optimizationProvider.error!,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _runOptimization,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: shoppingColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Tekrar Dene'),
                                ),
                              ],
                            ),
                          );
                        }

                        final filteredItems = _getFilteredItems(optimizationProvider);

                        if (!optimizationProvider.hasOptimizationResults) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 64,
                                  color: shoppingColor.withValues(alpha: 0.7),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Optimizasyon Henüz Çalıştırılmadı',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Kişiselleştirilmiş alışveriş listesi için\noptimizasyonu çalıştırın',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: _runOptimization,
                                  icon: const Icon(Icons.auto_awesome),
                                  label: const Text('Optimizasyonu Çalıştır'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: shoppingColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        if (filteredItems.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 64,
                                  color: shoppingColor.withValues(alpha: 0.7),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Arama sonucu bulunamadı',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Farklı bir arama terimi deneyin\nveya filtreleri değiştirin',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }

                        return AnimationLimiter(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = filteredItems[index];
                              return AnimationConfiguration.staggeredList(
                                position: index,
                                duration: const Duration(milliseconds: 375),
                                child: SlideAnimation(
                                  verticalOffset: 50.0,
                                  child: FadeInAnimation(
                                    child: _buildShoppingItemCard(item, optimizationProvider),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
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

  List<ShoppingItem> _getFilteredItems(OptimizationProvider provider) {
    var items = provider.shoppingItems;

    // Apply category filter
    if (_selectedCategory != 'Tümü') {
      items = provider.getShoppingItemsByCategory(_selectedCategory);
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      items = provider.searchItems(_searchQuery);
    }

    return items;
  }

  Widget _buildShoppingItemCard(ShoppingItem item, OptimizationProvider provider) {
    const Color shoppingColor = Color(0xFFFF6B6B);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: shoppingColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () {
            _showItemDetailsDialog(context, item);
          },
          child: Row(
            children: [
              // Product image or category icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: shoppingColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: item.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: shoppingColor.withValues(alpha: 0.2),
                            child: Icon(
                              _getCategoryIcon(item.category),
                              color: shoppingColor,
                              size: 28,
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: shoppingColor.withValues(alpha: 0.2),
                            child: Icon(
                              _getCategoryIcon(item.category),
                              color: shoppingColor,
                              size: 28,
                            ),
                          ),
                        )
                      : Icon(
                          _getCategoryIcon(item.category),
                          color: shoppingColor,
                          size: 28,
                        ),
                ),
              ),
              const SizedBox(width: 16),
              // Main content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.market.isNotEmpty ? item.market : 'Market bilgisi yok',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontStyle: item.market.isEmpty ? FontStyle.italic : FontStyle.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.category} • ${item.quantity.toStringAsFixed(1)} ${item.unit}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildNutritionChip('${item.calories.toStringAsFixed(0)} kcal', Colors.orange),
                          const SizedBox(width: 4),
                          _buildNutritionChip('${item.protein.toStringAsFixed(1)}g protein', Colors.green),
                          const SizedBox(width: 4),
                          _buildNutritionChip('${item.carbs.toStringAsFixed(1)}g karbonhidrat', Colors.blue),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Trailing content
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(item.price * item.quantity).toStringAsFixed(2)} ₺',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Market finder button
                  MarketFinderWidget(
                    product: _shoppingItemToProduct(item),
                    accentColor: shoppingColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'meyve & sebze':
        return Icons.eco;
      case 'süt & kahvaltı':
        return Icons.local_drink;
      case 'et & tavuk':
        return Icons.set_meal;
      case 'temel gıda':
        return Icons.grain;
      case 'bakliyat':
        return Icons.grass;
      default:
        return Icons.shopping_basket;
    }
  }

  void _showItemDetailsDialog(BuildContext context, ShoppingItem item) {
    const Color shoppingColor = Color(0xFFFF6B6B);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C3E50),
        title: Column(
          children: [
            // Product image
            if (item.imageUrl.isNotEmpty)
              Container(
                width: 80,
                height: 80,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: shoppingColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: item.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: shoppingColor.withValues(alpha: 0.2),
                      child: Icon(
                        _getCategoryIcon(item.category),
                        color: shoppingColor,
                        size: 32,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: shoppingColor.withValues(alpha: 0.2),
                      child: Icon(
                        _getCategoryIcon(item.category),
                        color: shoppingColor,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
            Text(
              item.productName,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Kategori', item.category),
            _buildDetailRow('Miktar', '${item.quantity.toStringAsFixed(1)} ${item.unit}'),
            _buildDetailRow('Fiyat', '${item.price.toStringAsFixed(2)} ₺'),
            _buildDetailRow('Toplam', '${(item.price * item.quantity).toStringAsFixed(2)} ₺'),
            const Divider(color: Colors.white24),
            _buildDetailRow('Kalori', '${item.calories.toStringAsFixed(0)} kcal'),
            _buildDetailRow('Protein', '${item.protein.toStringAsFixed(1)}g'),
            _buildDetailRow('Karbonhidrat', '${item.carbs.toStringAsFixed(1)}g'),
            _buildDetailRow('Yağ', '${item.fat.toStringAsFixed(1)}g'),
          ],
        ),
        actions: [
          // Market finder button
          MarketFinderWidget(
            product: _shoppingItemToProduct(item),
            accentColor: shoppingColor,
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showClearListDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C3E50),
        title: const Text(
          'Listeyi Temizle',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Tüm ürünleri listeden kaldırmak istediğinizden emin misiniz?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              context.read<OptimizationProvider>().clearShoppingList();
              Navigator.of(context).pop();
            },
            child: const Text(
              'Temizle',
              style: TextStyle(color: Color(0xFFFF6B6B)),
            ),
          ),
        ],
      ),
    );
  }
}
