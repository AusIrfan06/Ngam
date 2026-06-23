import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocationService {
  static final LocationService instance = LocationService._internal();
  LocationService._internal();

  final _supabase = Supabase.instance.client;
  StreamSubscription<Position>? _positionStreamSubscription;
  RealtimeChannel? _locationChannel;
  String? _currentTrackingGigId;

  /// Request permissions if not granted
  Future<bool> requestPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Start tracking and broadcasting location for a specific gig
  Future<void> startTracking(String gigId, String runnerId) async {
    // If already tracking this gig, do nothing
    if (_currentTrackingGigId == gigId && _positionStreamSubscription != null) {
      return;
    }
    
    // Stop any existing tracking first
    await stopTracking();

    final hasPermission = await requestPermission();
    if (!hasPermission) return;

    _currentTrackingGigId = gigId;

    // Join the gig's location broadcast channel
    _locationChannel = _supabase.channel('public:gig_location:$gigId');
    _locationChannel!.subscribe((status, [error]) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        // Ready to broadcast
      }
    });

    // Start location stream
    final locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Only send if moved by 10 meters
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position? position) {
        if (position != null && _locationChannel != null) {
          try {
            _locationChannel!.sendBroadcastMessage(
              event: 'location_update',
              payload: {
                'lat': position.latitude,
                'lng': position.longitude,
                'runner_id': runnerId,
                'timestamp': DateTime.now().toUtc().toIso8601String(),
              },
            );
          } catch (e) {
            // Ignore channel errors if any
          }
        }
      },
    );
  }

  /// Stop tracking and disconnect channel
  Future<void> stopTracking() async {
    _currentTrackingGigId = null;
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;

    if (_locationChannel != null) {
      await _supabase.removeChannel(_locationChannel!);
      _locationChannel = null;
    }
  }
}
