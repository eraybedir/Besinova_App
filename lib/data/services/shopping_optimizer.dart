import '../models/product.dart';
import '../models/optimization_result.dart';
import '../models/shopping_item.dart';
import '../models/shopping_result.dart';
import 'data_preprocessor.dart';

/// Shopping optimizer implementing the Python algorithm logic
class ShoppingOptimizer {
  
  /// Main optimization function
  static OptimizationResult? optimizeShopping({
    required List<Product> products,
    required int age,
    required String gender,
    required double weight,
    required double height,
    required String activityLevel,
    required String goal,
    required double budget,
    int days = 30,
  }) {
    try {
      print("=== OPTIMIZATION SERVICE: Starting optimization ===");
      
      // Preprocess data
      List<Product> filteredProducts = DataPreprocessor.preprocessData(products);
      
      if (filteredProducts.isEmpty) {
        print("❌ No products available after preprocessing");
        return null;
      }
      
      // Calculate nutrition targets
      double tdee = _calculateTDEE(age, gender, weight, height, activityLevel);
      Map<String, double> macroTargets = _getMacroTargets(tdee, goal);
      
      double targetCalories = tdee * days;
      double targetProtein = macroTargets['protein']! * days;
      double targetFat = macroTargets['fat']! * days;
      double targetCarbs = macroTargets['carbs']! * days;
      
      print("=== OPTIMIZATION PARAMETERS ===");
      print("Budget: ${budget.toStringAsFixed(2)} TL");
      print("Required calories: ${targetCalories.toStringAsFixed(0)} kcal");
      print("Required protein: ${targetProtein.toStringAsFixed(0)} g");
      print("Required fat: ${targetFat.toStringAsFixed(0)} g");
      print("Required carbs: ${targetCarbs.toStringAsFixed(0)} g");
      print("Available products: ${filteredProducts.length}");
      
      // Category analysis
      print("=== CATEGORY ANALYSIS ===");
      Map<String, List<Product>> categoryProducts = {};
      for (String category in ['vegetables', 'fruits', 'dairy', 'legumes', 'meat_fish', 'grains']) {
        categoryProducts[category] = filteredProducts.where((p) => p.mainGroup == category).toList();
        print("${category}: ${categoryProducts[category]!.length} products");
        if (categoryProducts[category]!.isEmpty) {
          print("!  WARNING: No products found in $category category!");
        }
      }
      
      // Nutrition feasibility check
      print("=== NUTRITION FEASIBILITY CHECK ===");
      double maxCalories = filteredProducts.map((p) => p.caloriesPer100g ?? 0).reduce((a, b) => a + b) * 5;
      double maxProtein = filteredProducts.map((p) => p.proteinPer100g ?? 0).reduce((a, b) => a + b) * 5;
      double maxFat = filteredProducts.map((p) => p.fatPer100g ?? 0).reduce((a, b) => a + b) * 5;
      double maxCarbs = filteredProducts.map((p) => p.carbsPer100g ?? 0).reduce((a, b) => a + b) * 5;
      
      print("Available calories (max): ${maxCalories.toStringAsFixed(0)} kcal");
      print("Required calories: ${targetCalories.toStringAsFixed(0)} kcal");
      print("Feasible: ${maxCalories >= targetCalories ? '✅' : '❌'}");
      
      print("Available protein (max): ${maxProtein.toStringAsFixed(0)} g");
      print("Required protein: ${targetProtein.toStringAsFixed(0)} g");
      print("Feasible: ${maxProtein >= targetProtein ? '✅' : '❌'}");
      
      print("Available fat (max): ${maxFat.toStringAsFixed(0)} g");
      print("Required fat: ${targetFat.toStringAsFixed(0)} g");
      print("Feasible: ${maxFat >= targetFat ? '✅' : '❌'}");
      
      print("Available carbs (max): ${maxCarbs.toStringAsFixed(0)} g");
      print("Required carbs: ${targetCarbs.toStringAsFixed(0)} g");
      print("Feasible: ${maxCarbs >= targetCarbs ? '✅' : '❌'}");
      
      // Budget feasibility check
      print("=== BUDGET FEASIBILITY CHECK ===");
      double minPrice = filteredProducts.map((p) => p.price).reduce((a, b) => a < b ? a : b);
      double maxPrice = filteredProducts.map((p) => p.price).reduce((a, b) => a > b ? a : b);
      double avgPrice = filteredProducts.map((p) => p.price).reduce((a, b) => a + b) / filteredProducts.length;
      
      print("Product price range: ${minPrice.toStringAsFixed(2)} - ${maxPrice.toStringAsFixed(2)} TL");
      print("Average product price: ${avgPrice.toStringAsFixed(2)} TL");
      print("Budget: ${budget.toStringAsFixed(2)} TL");
      print("Minimum budget needed (70%): ${(budget * 0.70).toStringAsFixed(2)} TL");
      
      // Run greedy optimization
      print("=== RUNNING GREEDY OPTIMIZATION ===");
      Map<String, dynamic> result = _runGreedyOptimization(
        filteredProducts,
        categoryProducts,
        targetCalories,
        targetProtein,
        targetFat,
        targetCarbs,
        budget,
        days,
      );
      
      if (result['items'].isEmpty) {
        print("❌ No items selected in optimization");
        return null;
      }
      
      // Create shopping items
      List<ShoppingItem> shoppingItems = (result['items'] as List<Map<String, dynamic>>)
          .map((item) => ShoppingItem(
                id: item['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                name: item['name'],
                productName: item['name'],
                market: item['market'],
                quantity: item['quantity'],
                pricePerUnit: item['price_per_unit'],
                totalPrice: item['total_price'],
                price: item['price_per_unit'],
                weightPerUnit: item['weight_per_unit'],
                totalWeight: item['total_weight'],
                calories: item['calories'],
                protein: item['protein'],
                carbs: item['carbs'],
                fat: item['fat'],
                category: item['category'],
                mainGroup: item['category'],
                unit: 'adet',
                imageUrl: item['image_url'] ?? '',
                isChecked: false,
              ))
          .toList();
      
      // Create shopping result
      ShoppingResult shoppingResult = ShoppingResult(
        totalCost: result['total_cost'],
        totalWeight: result['total_weight'],
        totalItems: result['total_items'],
        budgetUsage: (result['total_cost'] / budget) * 100,
        calories: result['achieved_calories'],
        protein: result['achieved_protein'],
        fat: result['achieved_fat'],
        carbs: result['achieved_carbs'],
      );
      
      // Create optimization result
      OptimizationResult optimizationResult = OptimizationResult(
        shoppingItems: shoppingItems,
        shoppingResult: shoppingResult,
      );
      
      print("✅ Optimization completed successfully!");
      print("Selected ${shoppingItems.length} different products");
      print("Total cost: ${result['total_cost'].toStringAsFixed(2)} TL");
      print("Budget usage: ${((result['total_cost'] / budget) * 100).toStringAsFixed(1)}%");
      
      return optimizationResult;
      
    } catch (e) {
      print("❌ Error in optimization: $e");
      return null;
    }
  }
  
  /// Calculate Total Daily Energy Expenditure (TDEE)
  static double _calculateTDEE(int age, String gender, double weight, double height, String activityLevel) {
    // Basal Metabolic Rate (BMR) calculation using Mifflin-St Jeor Equation
    double bmr;
    if (gender.toLowerCase() == "male") {
      bmr = 10 * weight + 6.25 * height - 5 * age + 5;
    } else {
      bmr = 10 * weight + 6.25 * height - 5 * age - 161;
    }
    
    // Activity level multipliers
    Map<String, double> activityFactors = {
      "sedentary": 1.2,
      "lightly active": 1.375,
      "moderately active": 1.55,
      "very active": 1.725,
      "extra active": 1.9
    };
    
    double tdee = bmr * (activityFactors[activityLevel.toLowerCase()] ?? 1.2);
    return tdee;
  }
  
  /// Get macro targets based on goal
  static Map<String, double> _getMacroTargets(double tdee, String goal) {
    // Adjust TDEE based on goal
    if (goal.toLowerCase().contains("gain")) {
      tdee += 200;
    } else if (goal.toLowerCase().contains("lose")) {
      tdee -= 200;
    }
    
    // Macro ratios based on goal
    double proteinRatio, fatRatio, carbRatio;
    
    if (goal.toLowerCase().contains("sport")) {
      proteinRatio = 0.20;
      fatRatio = 0.25;
      carbRatio = 0.55;
    } else {
      proteinRatio = 0.15;
      fatRatio = 0.25;
      carbRatio = 0.60;
    }
    
    // Calculate macro targets in grams
    double proteinG = (tdee * proteinRatio) / 4;  // 4 calories per gram of protein
    double fatG = (tdee * fatRatio) / 9;          // 9 calories per gram of fat
    double carbG = (tdee * carbRatio) / 4;        // 4 calories per gram of carbs
    
    return {
      'protein': proteinG,
      'fat': fatG,
      'carbs': carbG,
    };
  }
  
  /// Run greedy optimization algorithm
  static Map<String, dynamic> _runGreedyOptimization(
    List<Product> products,
    Map<String, List<Product>> categoryProducts,
    double targetCalories,
    double targetProtein,
    double targetFat,
    double targetCarbs,
    double budget,
    int days,
  ) {
    print("Phase 1: Ensuring category diversity...");
    
    Map<int, int> selectedQuantities = {};
    double totalCost = 0.0;
    double totalWeight = 0.0;
    double achievedCalories = 0.0;
    double achievedProtein = 0.0;
    double achievedFat = 0.0;
    double achievedCarbs = 0.0;
    
    // Phase 1: Ensure at least one item from each category
    for (String category in ['vegetables', 'fruits', 'dairy', 'legumes', 'meat_fish', 'grains']) {
      List<Product> categoryItems = categoryProducts[category] ?? [];
      if (categoryItems.isNotEmpty) {
        // Select the best item from this category
        Product? bestProduct = _findBestProduct(categoryItems, budget - totalCost);
        if (bestProduct != null) {
          selectedQuantities[bestProduct.id] = 1;
          totalCost += bestProduct.price;
          totalWeight += bestProduct.weightG ?? 1000;
          achievedCalories += bestProduct.caloriesPer100g ?? 0;
          achievedProtein += bestProduct.proteinPer100g ?? 0;
          achievedFat += bestProduct.fatPer100g ?? 0;
          achievedCarbs += bestProduct.carbsPer100g ?? 0;
        }
      }
    }
    
    print("Phase 2: Filling remaining budget...");
    
    // Phase 2: Fill remaining budget with best value items
    double remainingBudget = budget - totalCost;
    int maxIterations = 1000; // Prevent infinite loops
    int iterations = 0;
    
    while (remainingBudget > 0 && iterations < maxIterations) {
      Product? bestProduct = _findBestProduct(products, remainingBudget);
      if (bestProduct == null) break;
      
      int currentQty = selectedQuantities[bestProduct.id] ?? 0;
      if (currentQty >= 5) break; // Max 5 of each item
      
      selectedQuantities[bestProduct.id] = currentQty + 1;
      totalCost += bestProduct.price;
      totalWeight += bestProduct.weightG ?? 1000;
      achievedCalories += bestProduct.caloriesPer100g ?? 0;
      achievedProtein += bestProduct.proteinPer100g ?? 0;
      achievedFat += bestProduct.fatPer100g ?? 0;
      achievedCarbs += bestProduct.carbsPer100g ?? 0;
      
      remainingBudget = budget - totalCost;
      iterations++;
    }
    
    // Create result items
    List<Map<String, dynamic>> items = [];
    for (MapEntry<int, int> entry in selectedQuantities.entries) {
      Product product = products.firstWhere((p) => p.id == entry.key);
      items.add({
        'id': product.id.toString(),
        'name': product.name,
        'market': product.market,
        'quantity': entry.value,
        'price_per_unit': product.price,
        'total_price': product.price * entry.value,
        'weight_per_unit': product.weightG ?? 1000,
        'total_weight': (product.weightG ?? 1000) * entry.value,
        'calories': product.caloriesPer100g ?? 0,
        'protein': product.proteinPer100g ?? 0,
        'carbs': product.carbsPer100g ?? 0,
        'fat': product.fatPer100g ?? 0,
        'category': product.mainGroup ?? 'other',
        'image_url': product.imageUrl,
      });
    }
    
    return {
      'items': items,
      'total_cost': totalCost,
      'total_weight': totalWeight,
      'total_items': selectedQuantities.values.fold(0, (sum, qty) => sum + qty),
      'achieved_calories': achievedCalories,
      'achieved_protein': achievedProtein,
      'achieved_fat': achievedFat,
      'achieved_carbs': achievedCarbs,
    };
  }
  
  /// Find the best product within budget
  static Product? _findBestProduct(List<Product> products, double remainingBudget) {
    Product? bestProduct;
    double bestValue = 0.0;
    
    for (Product product in products) {
      if (product.price <= remainingBudget) {
        // Calculate value based on nutrition density and price
        double nutritionValue = (product.caloriesPer100g ?? 0) + 
                               (product.proteinPer100g ?? 0) * 4 + 
                               (product.carbsPer100g ?? 0) * 2 + 
                               (product.fatPer100g ?? 0) * 2;
        double value = nutritionValue / product.price;
        
        if (value > bestValue) {
          bestValue = value;
          bestProduct = product;
        }
      }
    }
    
    return bestProduct;
  }
} 