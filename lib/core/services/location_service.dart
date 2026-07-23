import '../import.dart';

class LocationService {
  static final Geocoding _geocoding = Geocoding();

  static Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition();
  }

  static Future<City?> getCityFromPosition(Position position) async {
    try {
      final placemarks = await _geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty) return null;

      final p = placemarks.first;
      // Use the best available place name; an empty result is a failed lookup.
      final subLocality = p.subLocality?.trim();
      final locality = p.locality?.trim();
      final placeName = subLocality?.isNotEmpty == true
          ? subLocality
          : locality?.isNotEmpty == true
              ? locality
              : p.name?.trim();
      if (placeName == null || placeName.isEmpty) return null;

      return City(
        name: placeName,
        admin: p.administrativeArea,
        country: p.country ?? '',
        lat: position.latitude,
        lon: position.longitude,
      );
    } catch (_) {
      return null;
    }
  }
}
