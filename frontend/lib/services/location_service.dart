import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Location error: $e');
      return null;
    }
  }

  Future<double> calculateDistance(
    double lat1, double lng1,
    double lat2, double lng2,
  ) async {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000;
  }

  bool isLocationServiceAvailable() {
    return Geolocator.isLocationServiceEnabled() as bool;
  }
}
