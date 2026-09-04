import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class LocationHeader extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final VoidCallback onLocationChanged;

  const LocationHeader({
    this.latitude,
    this.longitude,
    required this.onLocationChanged,
    super.key,
  });

  @override
  State<LocationHeader> createState() => _LocationHeaderState();
}

class _LocationHeaderState extends State<LocationHeader>
    with WidgetsBindingObserver {
  static const String _cityPrefsKey = 'cached_location_city';
  static const String _areaPrefsKey = 'cached_location_area';

  String _city = "";
  String _area = "";
  bool _isLoading = true;
  bool _hasTriedFetchingLocation = false;

  @override
  void initState() {
    super.initState();
    // Show the last resolved address immediately so the header never falls
    // back to a shimmer while the (usually unchanged) address re-resolves.
    _loadCachedAddress();
    if (widget.latitude != null && widget.longitude != null) {
      _getAddress(widget.latitude!, widget.longitude!);
    }
  }

  Future<void> _loadCachedAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final city = prefs.getString(_cityPrefsKey);
      final area = prefs.getString(_areaPrefsKey);
      if (!mounted || city == null || city.isEmpty) return;
      setState(() {
        _city = city;
        _area = area ?? '';
        _isLoading = false;
        _hasTriedFetchingLocation = true;
      });
    } catch (_) {}
  }

  @override
  void didUpdateWidget(covariant LocationHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.latitude != oldWidget.latitude ||
            widget.longitude != oldWidget.longitude) &&
        widget.latitude != null &&
        widget.longitude != null) {
      _getAddress(widget.latitude!, widget.longitude!);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   if (state == AppLifecycleState.resumed && _shouldRetryLocation) {
  //     _checkPermissionAndFetchLocation();
  //   }
  // }

  // Future<void> _checkPermissionAndFetchLocation() async {
  //   if (_isRequestingPermission) return;
  //   _isRequestingPermission = true;

  //   setState(() => _isLoading = true);

  //   try {
  //     bool enabled = await Geolocator.isLocationServiceEnabled();
  //     if (!enabled) {
  //       _setError("Location Off", "Turn on location");
  //       _isRequestingPermission = false;
  //       return;
  //     }

  //     LocationPermission permission = await Geolocator.checkPermission();
  //     if (permission == LocationPermission.denied) {
  //       permission = await Geolocator.requestPermission();
  //     }

  //     if (permission == LocationPermission.deniedForever) {
  //       _shouldRetryLocation = true;
  //       _setError("Permission Denied", "Go to settings to enable");
  //       await LocationPermissionDialog.show(context);
  //       _isRequestingPermission = false;
  //       return;
  //     }

  //     if (permission == LocationPermission.denied) {
  //       _setError("Permission Denied", "Location not available");
  //       await LocationPermissionDialog.show(context);
  //       _isRequestingPermission = false;
  //       return;
  //     }

  //     await Future.delayed(const Duration(milliseconds: 500));

  //     _shouldRetryLocation = false;
  //     await _fetchLocation();
  //   } catch (e) {
  //     debugPrint("❌ Location permission check failed: $e");
  //     _setError("Error", "Couldn't detect");
  //   }

  //   _isRequestingPermission = false;
  // }

  // Future<void> _fetchLocation() async {
  //   try {
  //     Position? pos;
  //     try {
  //       pos = await Geolocator.getCurrentPosition(
  //         desiredAccuracy: LocationAccuracy.high,
  //       );
  //     } catch (e) {
  //       debugPrint("⚠️ getCurrentPosition failed: $e");
  //       pos = await Geolocator.getLastKnownPosition();
  //     }

  //     if (pos != null) {
  //       await _saveCoordinates(pos.latitude, pos.longitude);
  //       await _getAddress(pos.latitude, pos.longitude);
  //     } else {
  //       const fallbackLat = 17.385044;
  //       const fallbackLng = 78.486671;
  //       await _saveCoordinates(fallbackLat, fallbackLng);
  //       await _getAddress(fallbackLat, fallbackLng);
  //     }
  //   } catch (e) {
  //     debugPrint("❌ Location fetch error: $e");
  //     const fallbackLat = 17.385044;
  //     const fallbackLng = 78.486671;
  //     await _saveCoordinates(fallbackLat, fallbackLng);
  //     await _getAddress(fallbackLat, fallbackLng);
  //   }

  //   widget
  //       .onLocationChanged(); // ✅ Trigger Cubit after setting fallback/real coords
  // }

  Future<void> _getAddress(double lat, double lng) async {
    try {
      List<Placemark> places = await placemarkFromCoordinates(lat, lng);
      Placemark place = places.first;

      if (!mounted) return;
      final city = place.locality ?? "Unknown";
      final area =
          "${place.subLocality ?? ''}, ${place.administrativeArea ?? ''} ${place.postalCode ?? ''}";
      setState(() {
        _city = city;
        _area = area;
        _isLoading = false;
        _hasTriedFetchingLocation = true;
      });
      _cacheAddress(city, area);
    } catch (e) {
      // Keep whatever address is already on screen (cached or previously
      // resolved) rather than replacing it with an error on a transient
      // geocoding failure.
      if (_city.isNotEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasTriedFetchingLocation = true;
          });
        }
        return;
      }
      _setError("Unknown", "Unable to fetch address");
    }
  }

  Future<void> _cacheAddress(String city, String area) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cityPrefsKey, city);
      await prefs.setString(_areaPrefsKey, area);
    } catch (_) {}
  }

  void _setError(String city, String area) {
    debugPrint("📍 Location Error → $city: $area");
    if (!mounted) return;

    setState(() {
      _city = city == "Error" ? "Location" : city;
      _area = area == "Couldn't detect" ? "Using default location" : area;
      _isLoading = false;
      _hasTriedFetchingLocation = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.location_pin, color: Colors.white, size: 24),
        const SizedBox(width: 10),
        Expanded(
          child:
              _isLoading && !_hasTriedFetchingLocation
                  ? _buildShimmer()
                  : GestureDetector(
                    onTap: () {
                      if (widget.latitude != null && widget.longitude != null) {
                        _getAddress(widget.latitude!, widget.longitude!);
                      }
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _city,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _area,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
        ),
      ],
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.white24,
      highlightColor: Colors.white54,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 120, height: 16, color: Colors.white),
          const SizedBox(height: 5),
          Container(width: 180, height: 12, color: Colors.white),
        ],
      ),
    );
  }
}
