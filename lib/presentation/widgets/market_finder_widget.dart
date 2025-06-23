import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/services/location_service.dart';
import '../../data/models/product.dart';

/// Widget for finding nearby markets for a specific product
class MarketFinderWidget extends StatefulWidget {
  final Product product;
  final Color accentColor;

  const MarketFinderWidget({
    super.key,
    required this.product,
    required this.accentColor,
  });

  @override
  State<MarketFinderWidget> createState() => _MarketFinderWidgetState();
}

class _MarketFinderWidgetState extends State<MarketFinderWidget> {
  List<MarketInfo> _nearbyMarkets = [];
  bool _isLoading = false;
  String? _errorMessage;
  Position? _userLocation;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    if (_disposed) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final position = await LocationService.getCurrentLocation();
      if (_disposed) return;
      
      if (position != null) {
        setState(() {
          _userLocation = position;
        });
        await _findNearbyMarkets();
      } else {
        if (_disposed) return;
        setState(() {
          _errorMessage = 'Konum alınamadı. Lütfen konum izinlerini kontrol edin.';
        });
      }
    } catch (e) {
      if (_disposed) return;
      setState(() {
        _errorMessage = 'Konum alınırken hata oluştu: $e';
      });
    } finally {
      if (_disposed) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _findNearbyMarkets() async {
    if (_userLocation == null || _disposed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final markets = await LocationService.findMarketsForProduct(
        latitude: _userLocation!.latitude,
        longitude: _userLocation!.longitude,
        productName: widget.product.name,
        marketName: widget.product.market,
      );

      if (_disposed) return;

      // Calculate distances asynchronously to prevent UI blocking
      final marketsWithDistance = await _calculateDistancesAsync(markets);

      if (_disposed) return;

      // Sort by proximity
      marketsWithDistance.sort((a, b) => 
        (a.distanceFromUser ?? double.infinity)
            .compareTo(b.distanceFromUser ?? double.infinity)
      );

      setState(() {
        _nearbyMarkets = marketsWithDistance.take(5).toList(); // Show top 5
      });
    } catch (e) {
      if (_disposed) return;
      setState(() {
        _errorMessage = 'Yakındaki marketler bulunamadı: $e';
      });
    } finally {
      if (_disposed) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Calculate distances for all markets asynchronously
  Future<List<MarketInfo>> _calculateDistancesAsync(List<MarketInfo> markets) async {
    final futures = markets.map((market) => 
      market.withDistanceAsync(_userLocation!.latitude, _userLocation!.longitude)
    ).toList();
    
    try {
      return await Future.wait(futures);
    } catch (e) {
      print('Error calculating distances: $e');
      // Return markets without distances on error
      return markets;
    }
  }

  Future<void> _openDirections(MarketInfo market) async {
    try {
      final url = Uri.parse(market.directionsUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Harita uygulaması açılamadı'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Harita açılırken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showMarketFinderDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C3E50),
        title: Row(
          children: [
            Icon(
              Icons.location_on,
              color: widget.accentColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.product.market.isNotEmpty ? '${widget.product.market} Marketleri' : 'Yakındaki Marketler',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.product.market.isNotEmpty 
                  ? '${widget.product.name} için ${widget.product.market} marketleri:'
                  : '${widget.product.name} için yakındaki marketler:',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        color: widget.accentColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Marketler aranıyor...',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              else if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                )
              else if (_nearbyMarkets.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Yakında market bulunamadı',
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _nearbyMarkets.length,
                    itemBuilder: (context, index) {
                      final market = _nearbyMarkets[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: Colors.white.withValues(alpha: 0.1),
                        child: ListTile(
                          leading: Icon(
                            Icons.store,
                            color: widget.accentColor,
                          ),
                          title: Text(
                            market.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                market.address,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                              if (market.distanceFromUser != null)
                                Text(
                                  'Mesafe: ${market.formattedDistance}',
                                  style: TextStyle(
                                    color: widget.accentColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.directions,
                              color: widget.accentColor,
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                              _openDirections(market);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Kapat',
              style: TextStyle(color: widget.accentColor),
            ),
          ),
          if (_errorMessage != null || _nearbyMarkets.isEmpty)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _getUserLocation();
              },
              child: Text(
                'Tekrar Dene',
                style: TextStyle(color: widget.accentColor),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.location_on,
        color: widget.accentColor,
        size: 20,
      ),
      onPressed: _isLoading ? null : _showMarketFinderDialog,
      tooltip: 'Yakındaki marketleri bul',
    );
  }
} 