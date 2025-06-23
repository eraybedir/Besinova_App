import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import 'firebase_service.dart';

/// Service for managing favorite products
class FavoritesService {
  static const String _favoritesKey = 'favorites';
  static SharedPreferences? _prefs;

  /// Initialize the favorites service
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get SharedPreferences instance
  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw StateError('FavoritesService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  /// Add a product to favorites
  static Future<bool> addToFavorites(Product product) async {
    try {
      await init();
      
      // Add to Firebase
      await FirebaseService.addToFavorites(product.name);
      
      // Keep local cache for offline access
      List<Product> favorites = await getFavorites();
      if (!favorites.any((p) => p.id == product.id)) {
        favorites.add(product);
        await _saveFavorites(favorites);
      }
      
      return true;
    } catch (e) {
      print('Error adding to favorites: $e');
      return false;
    }
  }

  /// Remove a product from favorites
  static Future<bool> removeFromFavorites(int productId) async {
    try {
      await init();
      
      // Get product name to remove from Firebase
      List<Product> favorites = await getFavorites();
      final product = favorites.firstWhere((p) => p.id == productId);
      
      // Remove from Firebase
      await FirebaseService.removeFromFavorites(product.name);
      
      // Remove from local cache
      favorites.removeWhere((product) => product.id == productId);
      await _saveFavorites(favorites);
      
      return true;
    } catch (e) {
      print('Error removing from favorites: $e');
      return false;
    }
  }

  /// Get all favorite products
  static Future<List<Product>> getFavorites() async {
    try {
      await init();
      
      // Try to get from Firebase first
      try {
        List<String> favoriteNames = await FirebaseService.loadFavorites();
        
        // Convert names back to Product objects (you might need to implement this)
        // For now, we'll use local storage as fallback
        final String? favoritesJson = prefs.getString(_favoritesKey);
        
        if (favoritesJson == null || favoritesJson.isEmpty) {
          return [];
        }
        
        final List<dynamic> favoritesList = json.decode(favoritesJson);
        return favoritesList.map((json) => Product.fromJson(json)).toList();
      } catch (e) {
        print('Error loading from Firebase, using local cache: $e');
        // Fallback to local storage
        final String? favoritesJson = prefs.getString(_favoritesKey);
        
        if (favoritesJson == null || favoritesJson.isEmpty) {
          return [];
        }
        
        final List<dynamic> favoritesList = json.decode(favoritesJson);
        return favoritesList.map((json) => Product.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error getting favorites: $e');
      return [];
    }
  }

  /// Check if a product is in favorites
  static Future<bool> isFavorite(int productId) async {
    try {
      List<Product> favorites = await getFavorites();
      return favorites.any((product) => product.id == productId);
    } catch (e) {
      print('Error checking favorite status: $e');
      return false;
    }
  }

  /// Toggle favorite status of a product
  static Future<bool> toggleFavorite(Product product) async {
    try {
      bool isFav = await isFavorite(product.id);
      
      if (isFav) {
        return await removeFromFavorites(product.id);
      } else {
        return await addToFavorites(product);
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      return false;
    }
  }

  /// Clear all favorites
  static Future<bool> clearFavorites() async {
    try {
      await init();
      
      // Clear from Firebase
      await FirebaseService.saveFavorites([]);
      
      // Clear local cache
      await prefs.remove(_favoritesKey);
      return true;
    } catch (e) {
      print('Error clearing favorites: $e');
      return false;
    }
  }

  /// Save favorites to SharedPreferences (local cache)
  static Future<void> _saveFavorites(List<Product> favorites) async {
    final List<Map<String, dynamic>> favoritesJson = 
        favorites.map((product) => product.toJson()).toList();
    await prefs.setString(_favoritesKey, json.encode(favoritesJson));
  }
} 