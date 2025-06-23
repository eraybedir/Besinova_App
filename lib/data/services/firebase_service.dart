import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user.dart' as app_user;
import '../models/shopping_item.dart';
import '../models/product.dart';

/// Service for handling Firebase Firestore operations
class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  /// Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;

  /// Check if user is authenticated
  static bool get isAuthenticated => _auth.currentUser != null;

  // ==================== USER DATA OPERATIONS ====================

  /// Save user data to Firestore
  static Future<void> saveUser(app_user.User user) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(currentUserId)
        .set({
          'name': user.name,
          'email': user.email,
          'height': user.height,
          'weight': user.weight,
          'age': user.age,
          'gender': user.gender,
          'activityLevel': user.activityLevel,
          'goal': user.goal,
          'avatar': user.avatar,
          'loginCount': user.loginCount,
          'lastLogin': user.lastLogin,
          'completedGoals': user.completedGoals,
          'budget': user.budget,
          'notificationCount': user.notificationCount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  /// Load user data from Firestore
  static Future<app_user.User> loadUser() async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final doc = await _firestore
        .collection('users')
        .doc(currentUserId)
        .get();

    if (!doc.exists) {
      throw Exception('User data not found');
    }

    final data = doc.data()!;
    return app_user.User(
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      height: (data['height'] ?? 0.0).toDouble(),
      weight: (data['weight'] ?? 0.0).toDouble(),
      age: data['age'] ?? 0,
      gender: data['gender'] ?? '',
      activityLevel: data['activityLevel'] ?? '',
      goal: data['goal'] ?? '',
      avatar: data['avatar'] ?? '',
      loginCount: data['loginCount'] ?? 0,
      lastLogin: data['lastLogin'] ?? DateTime.now().toString(),
      completedGoals: data['completedGoals'] ?? 0,
      budget: (data['budget'] ?? 0.0).toDouble(),
      notificationCount: data['notificationCount'] ?? 0,
    );
  }

  /// Update specific user field
  static Future<void> updateUserField(String field, dynamic value) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(currentUserId)
        .update({
          field: value,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  // ==================== SHOPPING LIST OPERATIONS ====================

  /// Save shopping list to Firestore
  static Future<void> saveShoppingList(List<ShoppingItem> items) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final batch = _firestore.batch();
    final shoppingRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('shopping_lists')
        .doc('current');

    // Clear existing items
    batch.set(shoppingRef, {
      'items': items.map((item) => {
        'id': item.id,
        'name': item.name,
        'productName': item.productName,
        'market': item.market,
        'quantity': item.quantity,
        'pricePerUnit': item.pricePerUnit,
        'totalPrice': item.totalPrice,
        'price': item.price,
        'weightPerUnit': item.weightPerUnit,
        'totalWeight': item.totalWeight,
        'calories': item.calories,
        'protein': item.protein,
        'carbs': item.carbs,
        'fat': item.fat,
        'category': item.category,
        'mainGroup': item.mainGroup,
        'unit': item.unit,
        'imageUrl': item.imageUrl,
        'isChecked': item.isChecked,
      }).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Load shopping list from Firestore
  static Future<List<ShoppingItem>> loadShoppingList() async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final doc = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('shopping_lists')
        .doc('current')
        .get();

    if (!doc.exists) return [];

    final data = doc.data()!;
    final items = data['items'] as List<dynamic>? ?? [];

    return items.map((item) => ShoppingItem(
      id: item['id'] ?? '',
      name: item['name'] ?? '',
      productName: item['productName'] ?? item['name'] ?? '',
      market: item['market'] ?? '',
      quantity: item['quantity'] ?? 1,
      pricePerUnit: (item['pricePerUnit'] ?? item['price'] ?? 0.0).toDouble(),
      totalPrice: (item['totalPrice'] ?? (item['pricePerUnit'] ?? item['price'] ?? 0.0) * (item['quantity'] ?? 1)).toDouble(),
      price: (item['price'] ?? item['pricePerUnit'] ?? 0.0).toDouble(),
      weightPerUnit: item['weightPerUnit'] ?? 100,
      totalWeight: item['totalWeight'] ?? (item['weightPerUnit'] ?? 100) * (item['quantity'] ?? 1),
      calories: (item['calories'] ?? 0.0).toDouble(),
      protein: (item['protein'] ?? 0.0).toDouble(),
      carbs: (item['carbs'] ?? 0.0).toDouble(),
      fat: (item['fat'] ?? 0.0).toDouble(),
      category: item['category'] ?? '',
      mainGroup: item['mainGroup'] ?? item['category'] ?? '',
      unit: item['unit'] ?? 'piece',
      imageUrl: item['imageUrl'] ?? '',
      isChecked: item['isChecked'] ?? false,
    )).toList();
  }

  /// Add item to shopping list
  static Future<void> addShoppingItem(ShoppingItem item) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final currentList = await loadShoppingList();
    currentList.add(item);
    await saveShoppingList(currentList);
  }

  /// Update shopping item
  static Future<void> updateShoppingItem(int index, ShoppingItem item) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final currentList = await loadShoppingList();
    if (index < currentList.length) {
      currentList[index] = item;
      await saveShoppingList(currentList);
    }
  }

  /// Remove item from shopping list
  static Future<void> removeShoppingItem(int index) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final currentList = await loadShoppingList();
    if (index < currentList.length) {
      currentList.removeAt(index);
      await saveShoppingList(currentList);
    }
  }

  // ==================== FAVORITES OPERATIONS ====================

  /// Save favorites to Firestore
  static Future<void> saveFavorites(List<String> favoriteProductNames) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('favorites')
        .doc('products')
        .set({
          'productNames': favoriteProductNames,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  /// Load favorites from Firestore
  static Future<List<String>> loadFavorites() async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final doc = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('favorites')
        .doc('products')
        .get();

    if (!doc.exists) return [];

    final data = doc.data()!;
    final favorites = data['productNames'] as List<dynamic>? ?? [];
    return favorites.map((favorite) => favorite.toString()).toList();
  }

  /// Add product to favorites
  static Future<void> addToFavorites(String productName) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final favorites = await loadFavorites();
    if (!favorites.contains(productName)) {
      favorites.add(productName);
      await saveFavorites(favorites);
    }
  }

  /// Remove product from favorites
  static Future<void> removeFromFavorites(String productName) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final favorites = await loadFavorites();
    favorites.remove(productName);
    await saveFavorites(favorites);
  }

  // ==================== OPTIMIZATION HISTORY ====================

  /// Save optimization result to Firestore
  static Future<void> saveOptimizationResult(Map<String, dynamic> result) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('optimizations')
        .add({
          ...result,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  /// Load optimization history from Firestore
  static Future<List<Map<String, dynamic>>> loadOptimizationHistory() async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final querySnapshot = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('optimizations')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  // ==================== UTILITY METHODS ====================

  /// Clear all user data
  static Future<void> clearAllUserData() async {
    if (currentUserId == null) throw Exception('User not authenticated');

    // Delete user document and all subcollections
    await _firestore.collection('users').doc(currentUserId).delete();
  }

  /// Check if user data exists
  static Future<bool> userDataExists() async {
    if (currentUserId == null) return false;

    final doc = await _firestore
        .collection('users')
        .doc(currentUserId)
        .get();

    return doc.exists;
  }

  /// Initialize user data if it doesn't exist
  static Future<void> initializeUserDataIfNeeded(app_user.User defaultUser) async {
    if (currentUserId == null) return;

    final exists = await userDataExists();
    if (!exists) {
      await saveUser(defaultUser);
    }
  }
} 