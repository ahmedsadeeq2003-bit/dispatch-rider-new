import 'dart:math';

class PricingUtils {
  // Surge pricing multiplier (can be dynamic based on demand)
  static const double _surgeMultiplier = 1.0; // No surge for now

  // Calculate distance between two coordinates using Haversine formula
  static double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  // Extract city from location string
  static String _extractCity(String location) {
    final lowerLocation = location.toLowerCase();
    if (lowerLocation.contains('abuja')) return 'abuja';
    if (lowerLocation.contains('kaduna')) return 'kaduna';
    if (lowerLocation.contains('adamawa') || lowerLocation.contains('yola'))
      return 'adamawa';
    return 'abuja'; // Default to Abuja
  }

  // Calculate total price for a delivery
  static double calculatePrice({
    required String pickupLocation,
    required String destinationLocation,
    double? pickupLat,
    double? pickupLon,
    double? destLat,
    double? destLon,
  }) {
    // DEBUG: Print received coordinates
    print(
        'DEBUG PRICING: pickupLat=$pickupLat, pickupLon=$pickupLon, destLat=$destLat, destLon=$destLon');

    // Extract cities
    final pickupCity = _extractCity(pickupLocation);
    final destCity = _extractCity(destinationLocation);

    // Calculate distance
    double distance = 0;
    if (pickupLat != null &&
        pickupLon != null &&
        destLat != null &&
        destLon != null) {
      distance = calculateDistance(pickupLat, pickupLon, destLat, destLon);
      print('DEBUG PRICING: Using actual distance = $distance km');
    } else {
      // Fallback distance estimation based on city pairs
      distance = _estimateDistance(pickupCity, destCity);
      print(
          'DEBUG PRICING: Using fallback distance = $distance km (from city estimation)');
    }

    // Base fare: 500 Naira (always added)
    const double baseFare = 500.0;

    // Per km rate: 100 Naira
    const double perKmRate = 100.0;

    // Calculate distance cost
    double distanceCost = distance * perKmRate;

    // Final price = Base fare + Distance cost
    double totalPrice = baseFare + distanceCost;

    // Apply surge pricing
    totalPrice *= _surgeMultiplier;

    // DEBUG: Print final price breakdown
    print('DEBUG PRICING: Base fare = $baseFare Naira');
    print(
        'DEBUG PRICING: Distance = $distance km, Distance cost = $distanceCost Naira');
    print('DEBUG PRICING: Final price = $totalPrice Naira');

    // Round to nearest 50 Naira for cleaner pricing
    return (totalPrice / 50).round() * 50.0;
  }

  // Estimate distance between cities (fallback when coordinates not available)
  // Returns 0 when no coordinates are provided to avoid incorrect pricing
  static double _estimateDistance(String city1, String city2) {
    if (city1 == city2) {
      // Return 0 for same-city - user will only pay base fare when no coords
      // This prevents the $2000 default price issue
      return 0.0;
    }

    // Inter-city distances (approximate)
    const interCityDistances = {
      'abuja-kaduna': 180.0,
      'abuja-adamawa': 650.0,
      'kaduna-adamawa': 470.0,
    };

    final key = city1.compareTo(city2) < 0 ? '$city1-$city2' : '$city2-$city1';
    return interCityDistances[key] ??
        0.0; // Default to 0 to avoid wrong pricing
  }

  // Get estimated delivery time based on distance and city
  static String getEstimatedTime(double distance, String city) {
    // Base time in minutes
    double baseTime = 10; // Base pickup time

    // Time per km based on city traffic
    final timePerKm = {
          'abuja': 3.0, // Minutes per km in Abuja
          'kaduna': 2.5,
          'adamawa': 3.5,
        }[city] ??
        3.0;

    final travelTime = distance * timePerKm;
    final totalMinutes = (baseTime + travelTime).round();

    if (totalMinutes < 60) {
      return '$totalMinutes mins';
    } else {
      final hours = totalMinutes ~/ 60;
      final mins = totalMinutes % 60;
      return '$hours hr ${mins > 0 ? '$mins min' : ''}';
    }
  }
}
