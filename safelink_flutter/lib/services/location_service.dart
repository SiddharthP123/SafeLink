// location_service.dart
//
// iOS permissions required — add these keys to ios/Runner/Info.plist:
//   <key>NSLocationWhenInUseUsageDescription</key>
//   <string>SafeLink needs your location to send accurate alert coordinates.</string>
//   <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
//   <string>SafeLink needs your location in the background for SOS alerts.</string>
//   <key>NSLocationAlwaysUsageDescription</key>
//   <string>SafeLink needs your location in the background for SOS alerts.</string>
//
// Android permissions — add to android/app/src/main/AndroidManifest.xml:
//   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
//   <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>

import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Requests location permission if needed, then returns the current position.
  /// Throws a [String] error message if permission is denied or unavailable.
  static Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Location services are disabled. Please enable them in Settings.';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Location permission denied.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Location permission permanently denied. '
          'Enable it in app Settings.';
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }
}
