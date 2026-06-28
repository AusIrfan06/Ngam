import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapPicker extends StatefulWidget {
  final LatLng initialCenter;
  final ValueChanged<LatLng> onLocationSelected;

  const MapPicker({
    super.key,
    required this.initialCenter,
    required this.onLocationSelected,
  });

  @override
  State<MapPicker> createState() => _MapPickerState();
}

class _MapPickerState extends State<MapPicker> {
  LatLng? _selectedLocation;
  final MapController _mapController = MapController();
  double _rotation = 0.0;
  bool _isLoadingLocation = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialCenter,
              initialZoom: 13.0,
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedLocation = point;
                });
                widget.onLocationSelected(point);
              },
              onPositionChanged: (position, hasGesture) {
                if (position.rotation != _rotation) {
                  setState(() {
                    _rotation = position.rotation;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: isDark
                    ? 'https://{s}.basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}.png'
                    : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ngam.app',
                keepBuffer: 5,
                panBuffer: 3,
                maxNativeZoom: 19,
              ),
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          
          // Map Controls (Right Side)
          Positioned(
            right: 12,
            bottom: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Reset North Button
                if (_rotation != 0.0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: FloatingActionButton.small(
                      heroTag: 'north_btn',
                      backgroundColor: Theme.of(context).cardColor,
                      onPressed: () {
                        _mapController.rotate(0);
                      },
                      child: Transform.rotate(
                        angle: -_rotation * (3.1415926535897932 / 180),
                        child: const Icon(Icons.navigation, color: Colors.blue),
                      ),
                    ),
                  ),
                // Current Location Button
                FloatingActionButton.small(
                  heroTag: 'gps_btn',
                  backgroundColor: Theme.of(context).cardColor,
                  onPressed: () async {
                    setState(() => _isLoadingLocation = true);
                    try {
                      final hasPermission = await Geolocator.requestPermission();
                      if (hasPermission == LocationPermission.always || hasPermission == LocationPermission.whileInUse) {
                        final pos = await Geolocator.getCurrentPosition();
                        final latLng = LatLng(pos.latitude, pos.longitude);
                        _mapController.move(latLng, 15.0);
                        setState(() {
                          _selectedLocation = latLng;
                        });
                        widget.onLocationSelected(latLng);
                      }
                    } finally {
                      setState(() => _isLoadingLocation = false);
                    }
                  },
                  child: _isLoadingLocation 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(Icons.my_location, color: Theme.of(context).primaryColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
