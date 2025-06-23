import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../models/product.dart';

class ProductService {
  final String baseUrl = AppConstants.baseApiUrl;
  
  // Timeout constants
  static const Duration _networkTimeout = Duration(seconds: 15);

  Future<List<Product>> fetchProducts() async {
    try {
      final response = await http.get(Uri.parse(AppConstants.productEndpoint))
          .timeout(_networkTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      throw Exception('Product fetch timeout: $e');
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }

  Future<Product> fetchProductById(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/product/$id'))
          .timeout(_networkTimeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return Product.fromJson(jsonData);
      } else {
        throw Exception('Failed to load product: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      throw Exception('Product fetch timeout: $e');
    } catch (e) {
      throw Exception('Error fetching product: $e');
    }
  }

  Future<List<Product>> searchProducts(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/product/search?q=${Uri.encodeComponent(query)}'),
      ).timeout(_networkTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search products: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      throw Exception('Product search timeout: $e');
    } catch (e) {
      throw Exception('Error searching products: $e');
    }
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/product/category/${Uri.encodeComponent(category)}'),
      ).timeout(_networkTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception(
            'Failed to load products by category: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      throw Exception('Category fetch timeout: $e');
    } catch (e) {
      throw Exception('Error fetching products by category: $e');
    }
  }
}
