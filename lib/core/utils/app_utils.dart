import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

/// Utility functions for the application
class AppUtils {
  static final RegExp _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  static const Duration _defaultSnackBarDuration = Duration(seconds: 3);

  /// Show a snackbar with the given message
  static void showSnackBar(BuildContext context, String message,
      {Duration? duration}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration ?? _defaultSnackBarDuration,
      ),
    );
  }

  /// Show a loading dialog
  static void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// Hide the current dialog
  static void hideDialog(BuildContext context) => Navigator.of(context).pop();

  /// Format currency
  static String formatCurrency(double amount) =>
      '₺${amount.toStringAsFixed(2)}';

  /// Format date
  static String formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

  /// Validate email format
  static bool isValidEmail(String email) => _emailRegex.hasMatch(email);

  /// Validate password strength
  static bool isValidPassword(String password) => password.length >= 6;

  /// Get initials from name
  static String getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return '';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  /// Execute a heavy operation in background thread
  static Future<T> runInBackground<T>(Future<T> Function() operation) async {
    try {
      return await compute(_executeOperation, operation);
    } catch (e) {
      print('Error in background operation: $e');
      rethrow;
    }
  }

  /// Execute operation in isolate (for compute function)
  static Future<T> _executeOperation<T>(Future<T> Function() operation) async {
    return await operation();
  }

  /// Execute operation with timeout
  static Future<T?> runWithTimeout<T>(
    Future<T> Function() operation,
    Duration timeout,
  ) async {
    try {
      return await operation().timeout(timeout);
    } on TimeoutException catch (e) {
      print('Operation timeout: $e');
      return null;
    } catch (e) {
      print('Operation error: $e');
      return null;
    }
  }

  /// Execute operation with retry logic
  static Future<T?> runWithRetry<T>(
    Future<T> Function() operation,
    int maxRetries, {
    Duration delay = const Duration(seconds: 1),
  }) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        return await operation();
      } catch (e) {
        print('Attempt ${i + 1} failed: $e');
        if (i < maxRetries - 1) {
          await Future.delayed(delay * (i + 1)); // Exponential backoff
        }
      }
    }
    return null;
  }

  /// Debounce function calls
  static Timer? _debounceTimer;
  static void debounce(VoidCallback callback, Duration duration) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(duration, callback);
  }

  /// Throttle function calls
  static DateTime? _lastThrottleCall;
  static bool throttle(VoidCallback callback, Duration duration) {
    final now = DateTime.now();
    if (_lastThrottleCall == null || 
        now.difference(_lastThrottleCall!) >= duration) {
      _lastThrottleCall = now;
      callback();
      return true;
    }
    return false;
  }

  /// Safe async operation with error handling
  static Future<T?> safeAsync<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (e) {
      print('Safe async operation failed: $e');
      return null;
    }
  }

  /// Batch process items with progress callback
  static Future<List<R>> batchProcess<T, R>(
    List<T> items,
    Future<R> Function(T item) processor, {
    int batchSize = 10,
    void Function(int current, int total)? onProgress,
  }) async {
    final results = <R>[];
    final total = items.length;
    
    for (int i = 0; i < total; i += batchSize) {
      final batch = items.skip(i).take(batchSize);
      final batchResults = await Future.wait(
        batch.map((item) => processor(item)),
      );
      results.addAll(batchResults);
      
      onProgress?.call(results.length, total);
    }
    
    return results;
  }

  /// Memory efficient list processing
  static Stream<R> streamProcess<T, R>(
    List<T> items,
    Future<R> Function(T item) processor, {
    int concurrency = 4,
  }) async* {
    final controller = StreamController<R>();
    final queue = items.toList();
    
    // Process items in batches
    while (queue.isNotEmpty) {
      final batch = queue.take(concurrency).toList();
      queue.removeRange(0, batch.length);
      
      final futures = batch.map((item) => processor(item)).toList();
      
      try {
        final results = await Future.wait(futures);
        for (final result in results) {
          controller.add(result);
        }
      } catch (e) {
        print('Stream processing error: $e');
      }
    }
    
    await controller.close();
    yield* controller.stream;
  }

  /// Cancelable operation wrapper
  static Future<T?> cancelableOperation<T>(
    Future<T> Function() operation,
    Future<void> Function()? onCancel,
  ) async {
    final completer = Completer<T?>();
    
    try {
      final result = await operation();
      if (!completer.isCompleted) {
        completer.complete(result);
      }
    } catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
    }
    
    return completer.future;
  }
}
