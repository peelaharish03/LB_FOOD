import 'package:local_basket/core/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationPickerPage extends StatefulWidget {
  final void Function(LatLng, Placemark)? onLocationSelected;

  const LocationPickerPage({super.key, this.onLocationSelected});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  static const LatLng _defaultLocation = LatLng(20.5937, 78.9629);
  static const double _defaultZoom = 5.0;
  static const double _selectedZoom = 15.0;

  LatLng? _selectedLocation;
  String _address = 'Fetching address...';
  Placemark? _currentPlacemark;
  bool _isLoading = false;
  bool _isMapReady = false;

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar('Location services are disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.deniedForever) {
        _showSnackBar('Location permissions are permanently denied');
        return;
      }

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          _showSnackBar('Location permission is required to detect your place');
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final currentLocation = LatLng(position.latitude, position.longitude);

      if (!mounted) return;
      setState(() {
        _selectedLocation = currentLocation;
      });

      _moveMap(currentLocation, _selectedZoom);
      await _getAddressFromLatLng(currentLocation);
    } catch (e) {
      _showSnackBar('Error getting location: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _getAddressFromLatLng(LatLng latLng) async {
    if (!mounted) return;
    setState(() {
      _address = 'Fetching address...';
      _currentPlacemark = null;
      _isLoading = true;
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );

      if (!mounted) return;
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _currentPlacemark = place;
          _address = [
            place.street,
            place.locality,
            place.administrativeArea,
            place.country,
          ].where((part) => part?.isNotEmpty ?? false).join(', ');
        });
      } else {
        setState(() => _address = 'No address found for this location');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _address = 'Failed to fetch address');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onMapTap(LatLng point) {
    setState(() {
      _selectedLocation = point;
      _address = 'Fetching address...';
    });
    _getAddressFromLatLng(point);
  }

  void _moveMap(LatLng point, double zoom) {
    if (_isMapReady) {
      _mapController.move(point, zoom);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Pick Location"),
        actions: [
          if (_selectedLocation != null && !_isLoading)
            IconButton(
              icon: Icon(Icons.check),
              onPressed: () {
                if (_selectedLocation != null && _currentPlacemark != null) {
                  widget.onLocationSelected?.call(
                    _selectedLocation!,
                    _currentPlacemark!,
                  );
                  Navigator.pop(context, true);
                }
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation ?? _defaultLocation,
              initialZoom:
                  _selectedLocation == null ? _defaultZoom : _selectedZoom,
              onMapReady: () {
                _isMapReady = true;
                final selectedLocation = _selectedLocation;
                if (selectedLocation != null) {
                  _moveMap(selectedLocation, _selectedZoom);
                }
              },
              onTap: (tapPosition, point) => _onMapTap(point),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                retinaMode: RetinaMode.isHighDensity(context),
                userAgentPackageName: 'com.localbaskethd',
                maxNativeZoom: 20,
              ),
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      width: 80,
                      height: 80,
                      child: Icon(
                        Icons.location_pin,
                        size: 40,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              SimpleAttributionWidget(
                alignment: Alignment.bottomLeft,
                backgroundColor: Colors.white.withValues(alpha: 0.8),
                source: const Text('OpenStreetMap contributors, CARTO'),
              ),
            ],
          ),
          if (_isLoading) Center(child: CircularProgressIndicator()),
          if (_selectedLocation != null && !_isLoading)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Card(
                elevation: 2,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_pin, color: Colors.red, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Selected Location',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColor.PrimaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow(
                              'Latitude:',
                              _selectedLocation!.latitude.toStringAsFixed(6),
                            ),
                            SizedBox(height: 6),
                            _buildDetailRow(
                              'Longitude:',
                              _selectedLocation!.longitude.toStringAsFixed(6),
                            ),
                            SizedBox(height: 8),
                            Divider(height: 1),
                            SizedBox(height: 8),
                            Text(
                              'Address:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(_address, style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColor.PrimaryColor,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            if (_selectedLocation != null &&
                                _currentPlacemark != null) {
                              widget.onLocationSelected?.call(
                                _selectedLocation!,
                                _currentPlacemark!,
                              );
                              Navigator.pop(context, true);
                            }
                          },
                          child: Text(
                            'Use This Location',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Widget _buildDetailRow(String label, String value) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
          fontSize: 14,
        ),
      ),
      SizedBox(width: 8),
      Expanded(child: Text(value, style: TextStyle(fontSize: 14))),
    ],
  );
}
