import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';
import '../models/product.dart';

/// Service for loading product data from CSV files
class CsvDataLoader {
  static const String _csvAssetPath = 'assets/enriched_2025_05_21.csv';
  
  /// Load products from CSV file with background processing
  static Future<List<Product>> loadProductsFromCsv() async {
    try {
      print("Loading products from CSV file...");
      
      // Load CSV data from assets
      final String csvData = await rootBundle.loadString('assets/enriched_2025_05_21.csv');
      
      // Process CSV data in background thread to prevent UI blocking
      return await compute(_processCsvData, csvData);
      
    } catch (e) {
      print("ERROR: Error loading CSV data: $e");
      return [];
    }
  }
  
  /// Process CSV data in background thread
  static List<Product> _processCsvData(String csvData) {
    try {
      // Debug: Print first 200 characters to see the format
      print("CSV data preview: ${csvData.substring(0, csvData.length > 200 ? 200 : csvData.length)}");
      
      // Split by lines first to handle potential line ending issues
      List<String> lines = csvData.split('\n');
      print("Total lines in CSV: ${lines.length}");
      
      if (lines.isEmpty) {
        print("ERROR: CSV file is empty");
        return [];
      }
      
      // Get headers from first line
      String headerLine = lines[0].trim();
      List<String> headers = headerLine.split(',').map((h) => h.trim()).toList();
      print("Raw headers: $headers");
      
      // Validate headers
      List<String> requiredHeaders = ['category', 'subcategory', 'item_category', 'name', 'price', 'market', 'image_url', 'calories', 'protein', 'carbs', 'fat'];
      for (String required in requiredHeaders) {
        if (!headers.contains(required)) {
          print("ERROR: Missing required header: $required");
          print("Available headers: $headers");
          return [];
        }
      }
      
      // Convert data rows to products
      List<Product> products = [];
      int productId = 1;
      
      print("Processing ${lines.length - 1} data rows...");
      
      for (int i = 1; i < lines.length; i++) {
        try {
          String line = lines[i].trim();
          if (line.isEmpty) {
            print("WARNING: Skipping empty line $i");
            continue;
          }
          
          // Parse CSV line manually to handle complex data
          List<String> values = _parseCsvLine(line);
          
          if (values.length < headers.length) {
            print("WARNING: Skipping line $i: insufficient columns (${values.length} < ${headers.length})");
            continue;
          }
          
          Map<String, dynamic> rowMap = {};
          for (int j = 0; j < headers.length; j++) {
            rowMap[headers[j]] = values[j];
          }
          
          // Debug: Print first 5 rows to see the data structure
          if (i <= 5) {
            print("Row $i data: $rowMap");
          }
          
          // Validate required fields
          if (rowMap['name'] == null || rowMap['name'].toString().trim().isEmpty) {
            print("WARNING: Skipping row $i: missing name");
            continue;
          }
          
          // Create product from row data
          Product product = Product.fromCsvRow(rowMap, productId);
          products.add(product);
          productId++;
          
        } catch (e) {
          print("WARNING: Skipping row $i due to error: $e");
          print("WARNING: Row data: ${lines[i]}");
          continue;
        }
      }
      
      print("SUCCESS: Successfully loaded ${products.length} products from CSV");
      
      // Print some statistics
      if (products.isNotEmpty) {
        double avgPrice = products.map((p) => p.price).reduce((a, b) => a + b) / products.length;
        double avgCalories = products.where((p) => p.caloriesPer100g != null)
            .map((p) => p.caloriesPer100g!)
            .reduce((a, b) => a + b) / products.where((p) => p.caloriesPer100g != null).length;
        
        print("Average price: ${avgPrice.toStringAsFixed(2)} TL");
        print("Average calories: ${avgCalories.toStringAsFixed(0)} kcal per 100g");
        
        // Category distribution
        Map<String, int> categoryCounts = {};
        for (Product product in products) {
          String category = product.mainGroup ?? 'other';
          categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
        }
        
        print("Category distribution:");
        categoryCounts.forEach((category, count) {
          print("  $category: $count products");
        });
      }
      
      return products;
      
    } catch (e) {
      print("ERROR: Error processing CSV data: $e");
      return [];
    }
  }
  
  /// Parse a CSV line manually to handle complex data
  static List<String> _parseCsvLine(String line) {
    List<String> values = [];
    String currentValue = '';
    bool inQuotes = false;
    
    for (int i = 0; i < line.length; i++) {
      final c = line[i];
      
      if (c == '"') {
        inQuotes = !inQuotes;
      } else if (c == ',' && !inQuotes) {
        values.add(currentValue.trim());
        currentValue = '';
      } else {
        currentValue += c;
      }
    }
    
    // Add the last value
    values.add(currentValue.trim());
    
    return values;
  }
  
  /// Load products from a local file (for testing) with background processing
  static Future<List<Product>> loadProductsFromFile(String filePath) async {
    try {
      print("Loading products from file: $filePath");
      
      final File file = File(filePath);
      if (!await file.exists()) {
        print("ERROR: File does not exist: $filePath");
        return [];
      }
      
      final String csvData = await file.readAsString();
      
      // Process CSV data in background thread
      return await compute(_processFileData, csvData);
      
    } catch (e) {
      print("ERROR: Error loading file data: $e");
      return [];
    }
  }
  
  /// Process file data in background thread
  static List<Product> _processFileData(String csvData) {
    try {
      print("Processing file data...");
      
      // Parse CSV
      List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvData);
      
      if (csvTable.isEmpty) {
        print("ERROR: CSV file is empty");
        return [];
      }
      
      // Get headers (first row)
      List<String> headers = csvTable[0].map((header) => header.toString()).toList();
      
      // Convert rows to products
      List<Product> products = [];
      int productId = 1;
      
      for (int i = 1; i < csvTable.length; i++) {
        try {
          List<dynamic> row = csvTable[i];
          Map<String, dynamic> rowMap = {};
          
          // Create map from headers and values
          for (int j = 0; j < headers.length && j < row.length; j++) {
            rowMap[headers[j]] = row[j];
          }
          
          // Debug: Print first 10 rows to see the data structure
          if (i <= 10) {
            print("Row $i data: $rowMap");
          }
          
          // Create product from row data
          Product product = Product.fromCsvRow(rowMap, productId);
          products.add(product);
          productId++;
          
        } catch (e) {
          print("WARNING: Skipping row $i due to error: $e");
          continue;
        }
      }
      
      print("SUCCESS: Successfully loaded ${products.length} products from file");
      return products;
      
    } catch (e) {
      print("ERROR: Error processing file data: $e");
      return [];
    }
  }
  
  /// Get sample products for testing (when CSV is not available)
  static List<Product> getSampleProducts() {
    return [
      Product(
        id: 1,
        name: "Domates 1kg",
        market: "Market A",
        price: 15.50,
        category: "Sebze",
        itemCategory: "Sebze",
        caloriesPer100g: 18,
        proteinPer100g: 0.9,
        carbsPer100g: 3.9,
        fatPer100g: 0.2,
        weightG: 1000,
        mainGroup: "vegetables",
        createdAt: DateTime.now(),
      ),
      Product(
        id: 2,
        name: "Tavuk Göğsü 1kg",
        market: "Market B",
        price: 45.00,
        category: "Et",
        itemCategory: "Et",
        caloriesPer100g: 165,
        proteinPer100g: 31,
        carbsPer100g: 0,
        fatPer100g: 3.6,
        weightG: 1000,
        mainGroup: "meat_fish",
        createdAt: DateTime.now(),
      ),
      Product(
        id: 3,
        name: "Pirinç 1kg",
        market: "Market C",
        price: 25.00,
        category: "Temel Gıda",
        itemCategory: "Temel Gıda",
        caloriesPer100g: 130,
        proteinPer100g: 2.7,
        carbsPer100g: 28,
        fatPer100g: 0.3,
        weightG: 1000,
        mainGroup: "grains",
        createdAt: DateTime.now(),
      ),
      Product(
        id: 4,
        name: "Süt 1L",
        market: "Market A",
        price: 12.50,
        category: "Süt Ürünleri",
        itemCategory: "Süt",
        caloriesPer100g: 42,
        proteinPer100g: 3.4,
        carbsPer100g: 5.0,
        fatPer100g: 1.0,
        weightG: 1000,
        mainGroup: "dairy",
        createdAt: DateTime.now(),
      ),
      Product(
        id: 5,
        name: "Elma 1kg",
        market: "Market B",
        price: 18.00,
        category: "Meyve",
        itemCategory: "Meyve",
        caloriesPer100g: 52,
        proteinPer100g: 0.3,
        carbsPer100g: 14,
        fatPer100g: 0.2,
        weightG: 1000,
        mainGroup: "fruits",
        createdAt: DateTime.now(),
      ),
    ];
  }
} 