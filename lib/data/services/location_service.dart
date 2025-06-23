import 'dart:convert';
import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../../core/constants/api_keys.dart';

/// Service for handling location-based market finding
class LocationService {
  static const String _apiKey = ApiKeys.googlePlacesApiKey;
  static const String _placesBaseUrl = 'https://maps.googleapis.com/maps/api/place';
  
  // Timeout constants
  static const Duration _locationTimeout = Duration(seconds: 10);
  static const Duration _networkTimeout = Duration(seconds: 15);

  /// Get user's current location with timeout and proper error handling
  static Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return null;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        return null;
      }

      // Get current position with timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: _locationTimeout,
      ).timeout(_locationTimeout, onTimeout: () {
        throw TimeoutException('Location request timed out', _locationTimeout);
      });

      print('Current location: ${position.latitude}, ${position.longitude}');
      return position;
    } on TimeoutException catch (e) {
      print('Location timeout: $e');
      return null;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  /// Find nearby markets/supermarkets with timeout and error handling
  static Future<List<MarketInfo>> findNearbyMarkets({
    required double latitude,
    required double longitude,
    double radius = 5000, // 5km radius
  }) async {
    try {
      final url = Uri.parse(
        '$_placesBaseUrl/nearbysearch/json?'
        'location=$latitude,$longitude&'
        'radius=$radius&'
        'type=supermarket&'
        'key=$_apiKey'
      );

      print('Searching for markets near: $latitude, $longitude');
      
      final response = await http.get(url).timeout(_networkTimeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          
          return results.map((place) => MarketInfo.fromJson(place)).toList();
        } else {
          print('Places API error: ${data['status']}');
          return [];
        }
      } else {
        print('HTTP error: ${response.statusCode}');
        return [];
      }
    } on TimeoutException catch (e) {
      print('Network timeout: $e');
      return [];
    } catch (e) {
      print('Error finding nearby markets: $e');
      return [];
    }
  }

  /// Find markets that might sell a specific product with timeout
  static Future<List<MarketInfo>> findMarketsForProduct({
    required double latitude,
    required double longitude,
    required String productName,
    required String marketName,
    double radius = 5000,
  }) async {
    try {
      // Search for the specific market instead of all markets
      final query = marketName.isNotEmpty ? marketName : 'supermarket grocery store';
      final url = Uri.parse(
        '$_placesBaseUrl/textsearch/json?'
        'query=$query&'
        'location=$latitude,$longitude&'
        'radius=$radius&'
        'key=$_apiKey'
      );

      print('Searching for specific market: $marketName for product: $productName');
      
      final response = await http.get(url).timeout(_networkTimeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          
          return results.map((place) => MarketInfo.fromJson(place)).toList();
        } else {
          print('Places API error: ${data['status']}');
          return [];
        }
      } else {
        print('HTTP error: ${response.statusCode}');
        return [];
      }
    } on TimeoutException catch (e) {
      print('Network timeout: $e');
      return [];
    } catch (e) {
      print('Error finding markets for product: $e');
      return [];
    }
  }

  /// Calculate distance between two points (moved to background thread)
  static Future<double> calculateDistanceAsync({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) async {
    return await compute(_calculateDistanceSync, {
      'lat1': lat1,
      'lon1': lon1,
      'lat2': lat2,
      'lon2': lon2,
    });
  }

  /// Synchronous distance calculation for compute function
  static double _calculateDistanceSync(Map<String, double> params) {
    return Geolocator.distanceBetween(
      params['lat1']!,
      params['lon1']!,
      params['lat2']!,
      params['lon2']!,
    );
  }

  /// Calculate distance between two points (legacy method)
  static double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Format distance for display
  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    }
  }
}

/// Model for market information
class MarketInfo {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double? rating;
  final int? userRatingsTotal;
  final String? placeId;
  final double? distanceFromUser;

  MarketInfo({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.rating,
    this.userRatingsTotal,
    this.placeId,
    this.distanceFromUser,
  });

  factory MarketInfo.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] as Map<String, dynamic>;
    final location = geometry['location'] as Map<String, dynamic>;
    
    return MarketInfo(
      id: json['place_id'] ?? '',
      name: json['name'] ?? '',
      address: json['vicinity'] ?? '',
      latitude: location['lat']?.toDouble() ?? 0.0,
      longitude: location['lng']?.toDouble() ?? 0.0,
      rating: json['rating']?.toDouble(),
      userRatingsTotal: json['user_ratings_total'],
      placeId: json['place_id'],
    );
  }

  /// Calculate distance from user location (async version)
  Future<MarketInfo> withDistanceAsync(double userLat, double userLng) async {
    try {
      final distance = await LocationService.calculateDistanceAsync(
        lat1: userLat,
        lon1: userLng,
        lat2: latitude,
        lon2: longitude,
      );
      
      return MarketInfo(
        id: id,
        name: name,
        address: address,
        latitude: latitude,
        longitude: longitude,
        rating: rating,
        userRatingsTotal: userRatingsTotal,
        placeId: placeId,
        distanceFromUser: distance,
      );
    } catch (e) {
      print('Error calculating distance: $e');
      // Return market info without distance on error
      return MarketInfo(
        id: id,
        name: name,
        address: address,
        latitude: latitude,
        longitude: longitude,
        rating: rating,
        userRatingsTotal: userRatingsTotal,
        placeId: placeId,
        distanceFromUser: null,
      );
    }
  }

  /// Calculate distance from user location (sync version for backward compatibility)
  MarketInfo withDistance(double userLat, double userLng) {
    try {
      final distance = LocationService.calculateDistance(
        lat1: userLat,
        lon1: userLng,
        lat2: latitude,
        lon2: longitude,
      );
      
      return MarketInfo(
        id: id,
        name: name,
        address: address,
        latitude: latitude,
        longitude: longitude,
        rating: rating,
        userRatingsTotal: userRatingsTotal,
        placeId: placeId,
        distanceFromUser: distance,
      );
    } catch (e) {
      print('Error calculating distance: $e');
      // Return market info without distance on error
      return MarketInfo(
        id: id,
        name: name,
        address: address,
        latitude: latitude,
        longitude: longitude,
        rating: rating,
        userRatingsTotal: userRatingsTotal,
        placeId: placeId,
        distanceFromUser: null,
      );
    }
  }

  /// Get formatted distance string
  String get formattedDistance {
    if (distanceFromUser == null) return 'Unknown';
    return LocationService.formatDistance(distanceFromUser!);
  }

  /// Get Google Maps URL for directions
  String get directionsUrl {
    return 'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude';
  }
} 