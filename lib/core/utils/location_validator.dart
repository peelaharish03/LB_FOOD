import 'dart:math' as math;

const double ANAKAPALLI_LATITUDE = 17.6869;
const double ANAKAPALLI_LONGITUDE = 82.8580;
const double SERVICE_RADIUS_KM = 40.0;

class LocationValidator {
  /// Calculate distance between two points using Haversine formula
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371; // Earth radius in kilometers
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  static double _toRad(double degree) {
    return degree * math.pi / 180;
  }

  /// Check if location is within service radius
  static bool isWithinServiceArea(double latitude, double longitude) {
    final distance = calculateDistance(
      latitude,
      longitude,
      ANAKAPALLI_LATITUDE,
      ANAKAPALLI_LONGITUDE,
    );
    return distance <= SERVICE_RADIUS_KM;
  }
}
