import 'dart:convert';
import 'dart:math';
import '../models/user.dart';
import '../models/product.dart';
import '../models/shopping_item.dart';
import '../models/shopping_result.dart';
import '../models/optimization_result.dart';
import 'local_optimization_service.dart';

/// Service for handling shopping optimization algorithm
class OptimizationService {
  /// Initialize the optimization service
  static Future<bool> initialize() async {
    return await LocalOptimizationService.initialize();
  }
  
  /// Optimize shopping list based on user profile and available products
  static Future<OptimizationResult?> optimizeShopping({
    required User user,
    List<Product>? products,
    int days = 30,
  }) async {
    try {
      print("=== OPTIMIZATION SERVICE: Starting optimization ===");
      
      // Use local optimization service
      OptimizationResult? result = await LocalOptimizationService.runOptimization(
        user: user,
        days: days,
      );
      
      if (result != null) {
        print("✅ Optimization completed successfully!");
        print("Selected ${result.shoppingItems.length} products");
        print("Total cost: ${result.shoppingResult.totalCost.toStringAsFixed(2)} TL");
        print("Budget usage: ${result.shoppingResult.budgetUsage.toStringAsFixed(1)}%");
      } else {
        print("❌ Optimization failed");
      }
      
      return result;
    } catch (e) {
      print("❌ Error in optimization service: $e");
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
      
      // Use local optimization service
      OptimizationResult? result = await LocalOptimizationService.runOptimizationWithParams(
        age: age,
        gender: gender,
        weight: weight,
        height: height,
        activityLevel: activityLevel,
        goal: goal,
        budget: budget,
        days: days,
      );
      
      if (result != null) {
        print("✅ Optimization completed successfully!");
        print("Selected ${result.shoppingItems.length} products");
        print("Total cost: ${result.shoppingResult.totalCost.toStringAsFixed(2)} TL");
        print("Budget usage: ${result.shoppingResult.budgetUsage.toStringAsFixed(1)}%");
      } else {
        print("❌ Optimization failed");
      }
      
      return result;
    } catch (e) {
      print("❌ Error in optimization service: $e");
      return null;
    }
  }

  /// Get optimization statistics
  static Map<String, dynamic> getOptimizationStats() {
    return LocalOptimizationService.getOptimizationStats();
  }

  /// Check if optimization service is ready
  static bool isReady() {
    return LocalOptimizationService.isReady();
  }

  /// Get available products
  static List<Product> getProducts() {
    return LocalOptimizationService.getProducts();
  }

  /// Clear optimization cache
  static void clearCache() {
    LocalOptimizationService.clearCache();
  }

  // Legacy methods for backward compatibility
  static double _calculateTDEE({
    required int age,
    required String gender,
    required double weight,
    required double height,
    required String activity,
  }) {
    // Basal Metabolic Rate (BMR) calculation using Mifflin-St Jeor Equation
    double bmr;
    if (gender.toLowerCase() == 'male') {
      bmr = 10 * weight + 6.25 * height - 5 * age + 5;
    } else {
      bmr = 10 * weight + 6.25 * height - 5 * age - 161;
    }

    // Activity level multipliers
    final activityFactors = {
      'sedentary': 1.2,
      'lightly active': 1.375,
      'moderately active': 1.55,
      'very active': 1.725,
      'extra active': 1.9,
    };

    final activityFactor = activityFactors[activity.toLowerCase()] ?? 1.2;
    return bmr * activityFactor;
  }

  static (double, double, double, double) _getMacroTargets({
    required double tdee,
    required String goal,
  }) {
    // Adjust TDEE based on goal
    double adjustedTdee = tdee;
    if (goal.toLowerCase().contains('gain')) {
      adjustedTdee += 200;
    } else if (goal.toLowerCase().contains('lose')) {
      adjustedTdee -= 200;
    }

    // Macro ratios based on goal
    double proteinRatio, fatRatio, carbRatio;
    if (goal.toLowerCase().contains('sport')) {
      proteinRatio = 0.20;
      fatRatio = 0.25;
      carbRatio = 0.55;
    } else {
      proteinRatio = 0.15;
      fatRatio = 0.25;
      carbRatio = 0.60;
    }

    // Calculate macro targets in grams
    final proteinG = (adjustedTdee * proteinRatio) / 4; // 4 calories per gram of protein
    final fatG = (adjustedTdee * fatRatio) / 9; // 9 calories per gram of fat
    final carbG = (adjustedTdee * carbRatio) / 4; // 4 calories per gram of carbs

    return (adjustedTdee, proteinG, fatG, carbG);
  }

  static List<Map<String, dynamic>> _preprocessProducts(List<Product> products) {
    final processed = <Map<String, dynamic>>[];

    for (final product in products) {
      // Skip products without nutritional data
      if ((product.caloriesPer100g ?? 0) <= 0 ||
          (product.proteinPer100g ?? 0) <= 0 ||
          (product.carbsPer100g ?? 0) <= 0 ||
          (product.fatPer100g ?? 0) <= 0) {
        continue;
      }

      // Skip expensive products
      if (product.price > 1000) continue;

      // Extract weight from product name or use default
      final weightG = _extractWeight(product.name);

      // Skip very heavy products
      if (weightG > 5000) continue;

      // Map to main group
      final mainGroup = _mapMainGroup(product.name, product.category ?? '');

      // Skip excluded groups
      if (mainGroup == 'exclude') continue;

      processed.add({
        'name': product.name,
        'category': product.category ?? 'Gıda',
        'item_category': product.category ?? 'Gıda',
        'price': product.price,
        'calories': product.caloriesPer100g!,
        'protein': product.proteinPer100g!,
        'carbs': product.carbsPer100g!,
        'fat': product.fatPer100g!,
        'image_url': product.imageUrl ?? '',
        'main_group': mainGroup,
        'weight_g': weightG,
      });
    }

    return processed;
  }

  static int _extractWeight(String name) {
    final regex = RegExp(r'(\d+[.,]?\d*)\s*(kg|g|gr)', caseSensitive: false);
    final match = regex.firstMatch(name);
    
    if (match != null) {
      final value = double.parse(match.group(1)!.replaceAll(',', '.'));
      final unit = match.group(2)!.toLowerCase();
      
      if (unit.contains('kg')) {
        return (value * 1000).round(); // Convert kg to grams
      } else {
        return value.round(); // Already in grams
      }
    }
    
    return 1000; // Default weight in grams
  }

  static String _mapMainGroup(String name, String category) {
    final itemCategory = category.toLowerCase();
    final productName = name.toLowerCase();

    // Exclude granola items
    if (itemCategory.contains('granola') || productName.contains('granola')) {
      return 'exclude';
    }

    // Vegetables
    if (_containsAny(itemCategory, ['sebze', 'domates', 'biber', 'salatalık', 'patates', 'soğan', 'havuç']) ||
        _containsAny(productName, ['domates', 'biber', 'salatalık', 'patates', 'soğan', 'havuç', 'kabak'])) {
      return 'vegetables';
    }

    // Fruits
    if (_containsAny(itemCategory, ['meyve', 'elma', 'muz', 'portakal', 'armut', 'çilek']) ||
        _containsAny(productName, ['elma', 'muz', 'portakal', 'armut', 'çilek', 'kayısı', 'şeftali'])) {
      return 'fruits';
    }

    // Dairy
    if (_containsAny(itemCategory, ['süt', 'kahvalt', 'peynir', 'yoğurt', 'süt ürünleri']) ||
        _containsAny(productName, ['peynir', 'yoğurt', 'süt', 'kaymak', 'krema'])) {
      return 'dairy';
    }

    // Legumes
    if (_containsAny(itemCategory, ['bakliyat', 'fasulye', 'mercimek', 'nohut', 'bezelye']) ||
        _containsAny(productName, ['fasulye', 'mercimek', 'nohut', 'bezelye', 'barbunya'])) {
      return 'legumes';
    }

    // Meat/Fish
    if (_containsAny(itemCategory, ['et', 'balık', 'tavuk', 'kıyma', 'sucuk']) ||
        _containsAny(productName, ['tavuk', 'balık', 'kıyma', 'sucuk', 'salam', 'pastırma'])) {
      return 'meat_fish';
    }

    // Grains
    if (_containsAny(itemCategory, ['temel gıda', 'ekmek', 'bulgur', 'pirinç', 'makarna', 'un']) ||
        _containsAny(productName, ['ekmek', 'bulgur', 'pirinç', 'makarna', 'un', 'börek'])) {
      return 'grains';
    }

    return 'other';
  }

  static bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }
} 