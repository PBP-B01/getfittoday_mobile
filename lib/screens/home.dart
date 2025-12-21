import 'package:flutter/material.dart';
import 'dart:async';
import 'package:getfittoday_mobile/constants.dart';
import 'package:getfittoday_mobile/models/fitness_spot.dart';
import 'package:getfittoday_mobile/services/fitness_spot_service.dart';
import 'package:getfittoday_mobile/state/auth_state.dart';
import 'package:getfittoday_mobile/utils/grid_helper.dart';
import 'package:getfittoday_mobile/widgets/site_navbar.dart';
import 'package:getfittoday_mobile/widgets/location_sidebar.dart';
import 'package:getfittoday_mobile/widgets/add_spot_form.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _fitnessSpotService = FitnessSpotService();
  Set<Marker> _markers = {};
  final Map<String, List<FitnessSpot>> _gridCache = {};
  final Set<String> _loadedGrids = {};

  GoogleMapController? _mapController;
  bool _isFullScreen = false;
  bool _isSidebarVisible = false;
  bool _isLoading = false;
  Timer? _debounceTimer;
  CameraTargetBounds _cameraTargetBounds = CameraTargetBounds.unbounded;

  List<FitnessSpot> _visibleSpots = [];
  FitnessSpot? _selectedSpot;

  bool _showInfoWindow = false;

  static const CameraPosition _kInitialPosition = CameraPosition(
    target: LatLng(-6.362143, 106.824928),
    zoom: 14.0,
  );

  Future<void> _ensureSession() async {
    final request = context.read<CookieRequest>();
    if (request.loggedIn) return;
    try {
      final resp = await request.get('$djangoBaseUrl/auth/whoami/');
      final loggedIn = resp is Map &&
          (resp['logged_in'] == true ||
              resp['loggedIn'] == true ||
              resp['status'] == true ||
              resp['status'] == 'success');
      if (loggedIn) {
        request.loggedIn = true;
        request.jsonData = Map<String, dynamic>.from(resp);
        if (mounted) {
          context.read<AuthState>().setFromLoginResponse(
                Map<String, dynamic>.from(resp),
                fallbackUsername: resp['username']?.toString(),
              );
        }
      }
    } catch (_) {
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    await _ensureSession();
    await _fetchBoundaries();
    _updateVisibleSpots();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchBoundaries() async {
    final request = context.read<CookieRequest>();
    final bounds = await _fitnessSpotService.fetchMapBoundaries(request);
    if (bounds != null) {
      setState(() {
        _cameraTargetBounds = CameraTargetBounds(
          LatLngBounds(
            southwest: LatLng(bounds['south']!, bounds['west']!),
            northeast: LatLng(bounds['north']!, bounds['east']!),
          ),
        );
      });
    }
  }

  void _onCameraIdle() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _updateVisibleSpots();
    });
  }

  Future<void> _updateVisibleSpots() async {
    if (_mapController == null) return;

    try {
      final bounds = await _mapController!.getVisibleRegion();
      final visibleGridIds = GridHelper.getVisibleGridIds(bounds);

      final gridsToFetch = visibleGridIds.where((id) => !_loadedGrids.contains(id)).toList();

      if (gridsToFetch.isNotEmpty) {
        setState(() => _isLoading = true);
        final request = context.read<CookieRequest>();

        await Future.wait(gridsToFetch.map((gridId) async {
          try {
            final spots = await _fitnessSpotService.fetchFitnessSpots(request, gridId: gridId);
            _gridCache[gridId] = spots;
            _loadedGrids.add(gridId);
          } catch (e) {
            print('Error fetching grid $gridId: $e');
          }
        }));

        setState(() => _isLoading = false);
      }

      _rebuildMarkersAndList(visibleGridIds);

    } catch (e) {
      print('Error updating visible spots: $e');
      setState(() => _isLoading = false);
    }
  }

  void _rebuildMarkersAndList(Set<String> visibleGridIds) {
    final Set<Marker> newMarkers = {};
    final List<FitnessSpot> newVisibleSpots = [];
    final Set<String> processedSpotIds = {};
    for (var gridId in visibleGridIds) {
      final spots = _gridCache[gridId];
      if (spots != null) {
        for (var spot in spots) {
          if (processedSpotIds.contains(spot.placeId)) continue;
          processedSpotIds.add(spot.placeId);
          newVisibleSpots.add(spot);

          final isSelected = _selectedSpot?.placeId == spot.placeId;

          newMarkers.add(
            Marker(
              markerId: MarkerId(spot.placeId + (isSelected ? '_selected' : '')),
              position: LatLng(spot.latitude, spot.longitude),
              onTap: () => _onSpotSelected(spot),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                isSelected
                    ? BitmapDescriptor.hueBlue
                    : BitmapDescriptor.hueRed
              ),
            ),
          );
        }
      }
    }

    setState(() {
      _markers = newMarkers;
      _visibleSpots = newVisibleSpots;
    });
  }

  void _onSpotSelected(FitnessSpot spot) {
    setState(() {
      _selectedSpot = spot;
      _showInfoWindow = true;
      _isSidebarVisible = true;

      final Set<Marker> newMarkers = {};
      for (var m in _markers) {
        final isTarget = m.markerId.value == spot.placeId || m.markerId.value == '${spot.placeId}_selected';

        newMarkers.add(
          m.copyWith(
            iconParam: BitmapDescriptor.defaultMarkerWithHue(
              isTarget ? BitmapDescriptor.hueBlue : BitmapDescriptor.hueRed
            ),
          )
        );
      }
    });



    _selectedSpot = spot;
    _showInfoWindow = true;
    _isSidebarVisible = true;

    _rebuildMarkersAndList(_loadedGrids);

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(spot.latitude, spot.longitude),
        16,
      ),
    );
  }

  void _closeInfoWindow() {
    setState(() {
      _showInfoWindow = false;
      _selectedSpot = null;
    });
    _rebuildMarkersAndList(_loadedGrids);
  }

  Future<void> _onMyLocationPressed() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Can't use center on me since location permission isn't given")),
            );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Can't use center on me since location permission isn't given")),
          );
      }
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(position.latitude, position.longitude),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 768;

    if (_isFullScreen) {
      return Scaffold(
        body: _buildMapInterface(isWide),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [gradientStartColor, gradientEndColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SiteNavBar(active: NavDestination.home),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "YOUR ONE-STOP SOLUTION TO GET FIT",
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: titleColor,
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: size.width * 0.8,
                        height: size.height * 0.5,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _buildMapInterface(isWide),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapInterface(bool isWide) {
    if (isWide) {
      return Row(
        children: [
          if (_isSidebarVisible)
            LocationSidebar(
              spots: _visibleSpots,
              onSpotSelected: _onSpotSelected,
              selectedSpot: _selectedSpot,
            ),
          Expanded(child: _buildMapStack(isWide)),
        ],
      );
    } else {
      return Column(
        children: [
          Expanded(
            flex: _isSidebarVisible ? 1 : 1,
            child: _buildMapStack(isWide),
          ),
          if (_isSidebarVisible)
            Expanded(
              flex: 1,
              child: LocationSidebar(
                spots: _visibleSpots,
                onSpotSelected: _onSpotSelected,
                selectedSpot: _selectedSpot,
                isMobile: true,
              ),
            ),
        ],
      );
    }
  }

  Widget _buildMapStack(bool isWide) {
    return Stack(
      children: [
        GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: _kInitialPosition,
          markers: _markers,
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
            _updateVisibleSpots();
          },
          onCameraIdle: _onCameraIdle,
          cameraTargetBounds: _cameraTargetBounds,
          zoomControlsEnabled: false,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          padding: EdgeInsets.only(
            top: 60,
            bottom: (!isWide && _isSidebarVisible) ? 20 : 0
          ),
        ),

        const Center(
          child: IgnorePointer(
            child: Icon(
              Icons.add,
              size: 30,
              color: Colors.black54,
            ),
          ),
        ),

        if (_showInfoWindow && _selectedSpot != null)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: GestureDetector(
              onTap: () {
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _selectedSpot!.name,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: _closeInfoWindow,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 18, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedSpot!.address,
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_selectedSpot!.rating != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            '${_selectedSpot!.rating} (${_selectedSpot!.ratingCount} reviews)',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

        Positioned(
          top: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FloatingActionButton.small(
                heroTag: 'fullscreen_toggle',
                backgroundColor: Colors.white,
                foregroundColor: primaryNavColor,
                onPressed: () {
                  setState(() {
                    _isFullScreen = !_isFullScreen;
                  });
                },
                child: Icon(_isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen),
              ),
              const SizedBox(height: 8),

              FloatingActionButton.small(
                heroTag: 'sidebar_toggle',
                backgroundColor: Colors.white,
                foregroundColor: primaryNavColor,
                onPressed: () {
                  setState(() {
                    _isSidebarVisible = !_isSidebarVisible;
                  });
                },
                child: Icon(_isSidebarVisible ? Icons.list_alt : Icons.map),
              ),
              const SizedBox(height: 8),

              FloatingActionButton.small(
                heroTag: 'my_location',
                backgroundColor: Colors.white,
                foregroundColor: primaryNavColor,
                onPressed: _onMyLocationPressed,
                child: const Icon(Icons.my_location),
              ),
              const SizedBox(height: 8),

              FloatingActionButton.small(
                heroTag: 'add_spot',
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                onPressed: () async {
                  if (_mapController != null) {
                    final bounds = await _mapController!.getVisibleRegion();
                    final centerLat = (bounds.northeast.latitude + bounds.southwest.latitude) / 2;
                    final centerLng = (bounds.northeast.longitude + bounds.southwest.longitude) / 2;

                    if (mounted) {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => AddSpotForm(
                          latitude: centerLat,
                          longitude: centerLng,
                          onSuccess: () {
                            setState(() {
                              _gridCache.clear();
                              _loadedGrids.clear();
                            });
                            _updateVisibleSpots();
                          },
                        ),
                      );
                    }
                  }
                },
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ),

        if (_isLoading)
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Loading spots...'),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
