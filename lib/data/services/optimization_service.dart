import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/product.dart';
import '../models/shopping_item.dart';
import '../models/shopping_result.dart';
import '../models/optimization_result.dart';

/// Service for handling shopping optimization via Render server API
class OptimizationService {
  static const String _baseUrl = 'https://shopping-optimizer-api.onrender.com';
  static bool _isInitialized = false;

  /// Initialize the optimization service
  static Future<bool> initialize() async {
    try {
      print("=== OPTIMIZATION SERVICE: Initializing with Render server ===");
      
      // Test gender mapping
      testGenderMapping();
      
      // Test the server connection
      final response = await http.get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _isInitialized = data['data_loaded'] == true;
        print("✅ Server connection successful. Products loaded: ${data['products_count']}");
        return _isInitialized;
      } else {
        print("❌ Server health check failed: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("❌ Error initializing optimization service: $e");
      return false;
    }
  }
  
  /// Optimize shopping list based on user profile
  static Future<OptimizationResult?> optimizeShopping({
    required User user,
    List<Product>? products,
    int days = 30,
  }) async {
    try {
      print("🔥🔥🔥 UPDATED OPTIMIZATION SERVICE CODE IS RUNNING! 🔥🔥🔥");
      print("=== OPTIMIZATION SERVICE: Starting optimization ===");
      
      // Quick test of gender mapping
      print("TEST: Gender mapping test:");
      print("  'Erkek' contains 'erkek': ${'Erkek'.toLowerCase().contains('erkek')}");
      print("  'Kadın' contains 'kadın': ${'Kadın'.toLowerCase().contains('kadın')}");
      
      print("DEBUG: User age value: ${user.age}");
      print("DEBUG: User age type: ${user.age.runtimeType}");
      print("DEBUG: User gender value: '${user.gender}'");
      print("DEBUG: User gender type: ${user.gender.runtimeType}");
      
      // Force gender mapping with explicit logging
      String mappedGender;
      if (user.gender.toLowerCase().contains('erkek')) {
        mappedGender = 'male';
        print("DEBUG: Direct mapping '${user.gender}' -> 'male'");
      } else if (user.gender.toLowerCase().contains('kadın')) {
        mappedGender = 'female';
        print("DEBUG: Direct mapping '${user.gender}' -> 'female'");
      } else {
        mappedGender = 'male';
        print("DEBUG: Default mapping '${user.gender}' -> 'male'");
      }
      
      print("DEBUG: Final mapped gender: '$mappedGender'");
      
      final params = {
        'age': user.age,
        'gender': mappedGender,
        'weight': user.weight,
        'height': user.height,
        'activity': _mapActivityLevel(user.activityLevel),
        'goal': _mapGoal(user.goal),
        'budget': user.budget,
        'days': days,
      };
      
      print("DEBUG: API params age value: ${params['age']}");
      print("DEBUG: API params age type: ${params['age'].runtimeType}");
      print("DEBUG: API params gender value: '${params['gender']}'");
      print("DEBUG: API params gender type: ${params['gender'].runtimeType}");
      
      final result = await _callOptimizationAPI(params);
      
      if (result != null) {
        print("SUCCESS: Optimization completed successfully!");
        print("Selected ${result.shoppingItems.length} products");
        print("Total cost: ${result.shoppingResult.totalCost.toStringAsFixed(2)} TL");
        print("Budget usage: ${result.shoppingResult.budgetUsage.toStringAsFixed(1)}%");
      } else {
        print("ERROR: Optimization failed");
      }
      
      return result;
    } catch (e) {
      print("ERROR: Error in optimization service: $e");
      return null;
    }
  }

  /// Optimize shopping list with custom parameters
  static Future<OptimizationResult?> optimizeShoppingWithParams({
    required int age,
    required String gender,
    required double weight,
    required double height,
    required String activityLevel,
    required String goal,
    required double budget,
    int days = 30,
  }) async {
    try {
      print("=== OPTIMIZATION SERVICE: Starting optimization with custom params ===");
      
      final params = {
        'age': age,
        'gender': _mapGender(gender),
        'weight': weight,
        'height': height,
        'activity': _mapActivityLevel(activityLevel),
        'goal': _mapGoal(goal),
        'budget': budget,
        'days': days,
      };
      
      final result = await _callOptimizationAPI(params);
      
      if (result != null) {
        print("SUCCESS: Optimization completed successfully!");
        print("Selected ${result.shoppingItems.length} products");
        print("Total cost: ${result.shoppingResult.totalCost.toStringAsFixed(2)} TL");
        print("Budget usage: ${result.shoppingResult.budgetUsage.toStringAsFixed(1)}%");
      } else {
        print("ERROR: Optimization failed");
      }
      
      return result;
    } catch (e) {
      print("ERROR: Error in optimization service: $e");
      return null;
    }
  }

  /// Call the Render API for optimization
  static Future<OptimizationResult?> _callOptimizationAPI(Map<String, dynamic> params) async {
    try {
      print("Calling Render API with params: $params");
      
      final response = await http.post(
        Uri.parse('$_baseUrl/optimize'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(params),
      ).timeout(const Duration(seconds: 35)); // 35 second timeout
      
      print("API Response Status: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseOptimizationResult(data);
      } else {
        final errorData = json.decode(response.body);
        print("API Error: ${errorData['error']}");
        return null;
      }
    } catch (e) {
      print("Error calling optimization API: $e");
      return null;
    }
  }

  /// Parse the API response into OptimizationResult
  static OptimizationResult? _parseOptimizationResult(Map<String, dynamic> data) {
    try {
      final optimizationData = data['optimization_results'];
      final items = optimizationData['items'] as List;
      
      // Create shopping items from API response
      final List<ShoppingItem> shoppingItems = [];
      final List<Product> optimizedProducts = [];
      
      for (var item in items) {
        print('DEBUG: Processing item: ${item['name']} with image_url: ${item['image_url']}');
        
        final shoppingItem = ShoppingItem(
          id: '${item['name']}_${item['market']}_${item['quantity']}', // Generate unique ID
          name: item['name'] ?? '',
          productName: item['name'] ?? '',
          market: item['market'] ?? '',
          quantity: item['quantity'] ?? 1,
          pricePerUnit: (item['price'] is num) ? (item['price'] as num).toDouble() : 0.0,
          totalPrice: (item['price'] is num) ? (item['price'] as num).toDouble() : 0.0,
          price: (item['price'] is num) ? (item['price'] as num).toDouble() : 0.0,
          weightPerUnit: (item['weight_g'] is num) ? (item['weight_g'] as num).toInt() : 1000,
          totalWeight: (item['weight_g'] is num) ? (item['weight_g'] as num).toInt() : 1000,
          calories: (item['calories'] is num) ? (item['calories'] as num).toDouble() : 0.0,
          protein: (item['protein'] is num) ? (item['protein'] as num).toDouble() : 0.0,
          carbs: (item['carbs'] is num) ? (item['carbs'] as num).toDouble() : 0.0,
          fat: (item['fat'] is num) ? (item['fat'] as num).toDouble() : 0.0,
          category: item['category'] ?? '',
          mainGroup: item['category'] ?? '',
          unit: 'piece',
          imageUrl: item['image_url'] ?? '', // Add image URL from server
        );
        
        final product = Product(
          id: item['id'] ?? 0,
          name: item['name'] ?? '',
          market: item['market'] ?? '',
          price: (item['price'] is num) ? (item['price'] as num).toDouble() : 0.0,
          imageUrl: item['image_url'] ?? '', // Add image URL from server
          category: item['category'] ?? '',
          caloriesPer100g: (item['calories'] is num) ? (item['calories'] as num).toDouble() : null,
          proteinPer100g: (item['protein'] is num) ? (item['protein'] as num).toDouble() : null,
          carbsPer100g: (item['carbs'] is num) ? (item['carbs'] as num).toDouble() : null,
          fatPer100g: (item['fat'] is num) ? (item['fat'] as num).toDouble() : null,
          createdAt: DateTime.now(),
        );
        
        print('DEBUG: Created shopping item with imageUrl: ${shoppingItem.imageUrl}');
        print('DEBUG: Created product with imageUrl: ${product.imageUrl}');
        
        shoppingItems.add(shoppingItem);
        optimizedProducts.add(product);
      }
      
      // Calculate nutrition totals
      final totalCalories = shoppingItems.fold(0.0, (sum, item) => sum + (item.calories * item.quantity));
      final totalProtein = shoppingItems.fold(0.0, (sum, item) => sum + (item.protein * item.quantity));
      final totalFat = shoppingItems.fold(0.0, (sum, item) => sum + (item.fat * item.quantity));
      final totalCarbs = shoppingItems.fold(0.0, (sum, item) => sum + (item.carbs * item.quantity));
      
      // Create shopping result
      final shoppingResult = ShoppingResult(
        totalCost: optimizationData['total_cost'].toDouble(),
        totalWeight: optimizationData['total_weight'].toDouble(),
        totalItems: optimizationData['total_items'].toInt(),
        budgetUsage: optimizationData['budget_usage'].toDouble(),
        calories: totalCalories,
        protein: totalProtein,
        fat: totalFat,
        carbs: totalCarbs,
      );
      
      return OptimizationResult(
        shoppingResult: shoppingResult,
        shoppingItems: shoppingItems,
      );
    } catch (e) {
      print("Error parsing optimization result: $e");
      return null;
    }
  }

  /// Map activity level to API format
  static String _mapActivityLevel(String activityLevel) {
    switch (activityLevel.toLowerCase()) {
      case 'sedanter':
        return 'sedentary';
      case 'hafif aktif':
        return 'lightly active';
      case 'orta aktif':
        return 'moderately active';
      case 'çok aktif':
        return 'very active';
      case 'ekstra aktif':
        return 'extra active';
      default:
        return 'moderately active';
    }
  }

  /// Map goal to API format
  static String _mapGoal(String goal) {
    switch (goal.toLowerCase()) {
      case 'kilo almak':
        return 'gaining weight';
      case 'sporcu için besin önerisi':
        return 'doing sports';
      case 'kilo vermek':
        return 'losing weight';
      case 'sağlıklı olmak':
        return 'being healthy';
      default:
        return 'being healthy';
    }
  }

  /// Map gender to API format
  static String _mapGender(String gender) {
    print("DEBUG: _mapGender called with: '$gender'");
    print("DEBUG: _mapGender input type: ${gender.runtimeType}");
    print("DEBUG: _mapGender input length: ${gender.length}");
    print("DEBUG: _mapGender input bytes: ${gender.codeUnits}");
    
    final lowerGender = gender.toLowerCase().trim();
    print("DEBUG: _mapGender lowercase and trimmed: '$lowerGender'");
    
    // Handle various possible formats
    if (lowerGender.contains('erkek') || lowerGender.contains('male')) {
      print("DEBUG: _mapGender mapping to 'male'");
      return 'male';
    } else if (lowerGender.contains('kadın') || lowerGender.contains('female')) {
      print("DEBUG: _mapGender mapping to 'female'");
      return 'female';
    } else {
      print("DEBUG: _mapGender using default 'male' for: '$lowerGender'");
      return 'male'; // Default fallback
    }
  }

  /// Test gender mapping function
  static void testGenderMapping() {
    print("=== TESTING GENDER MAPPING ===");
    print("Test 1: 'Erkek' -> ${_mapGender('Erkek')}");
    print("Test 2: 'erkek' -> ${_mapGender('erkek')}");
    print("Test 3: 'Kadın' -> ${_mapGender('Kadın')}");
    print("Test 4: 'kadın' -> ${_mapGender('kadın')}");
    print("Test 5: 'male' -> ${_mapGender('male')}");
    print("Test 6: 'female' -> ${_mapGender('female')}");
    print("Test 7: 'unknown' -> ${_mapGender('unknown')}");
    print("=== END GENDER MAPPING TEST ===");
  }

  /// Get optimization statistics
  static Map<String, dynamic> getOptimizationStats() {
    return {
      'server_connected': _isInitialized,
      'server_url': _baseUrl,
      'last_optimization': null,
    };
  }

  /// Check if optimization service is ready
  static bool isReady() {
    return _isInitialized;
  }

  /// Get available products (not available with server API)
  static List<Product> getProducts() {
    return [];
  }

  /// Clear optimization cache
  static void clearCache() {
    // No cache to clear with server API
  }
} 