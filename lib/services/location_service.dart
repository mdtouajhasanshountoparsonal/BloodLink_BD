import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  Position? _cached;
  bool _tried = false;

  /// এক সেশনে একবার মাত্র লোকেশন চেষ্টা — এই ডিভাইসে Play services না থাকলে
  /// প্রতি ডায়লাগ/পুর রিপিট না হয়।
  Future<Position?> currentPosition() async {
    if (_tried) return _cached;
    _tried = true;
    if (kIsWeb) return null;
    try {
      final service = await Geolocator.isLocationServiceEnabled();
      if (!service) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      _cached = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return _cached;
    } catch (_) {
      return null;
    }
  }

  double distanceKm(double lat1, double lng1, double lat2, double lng2) =>
      Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000.0;
}
