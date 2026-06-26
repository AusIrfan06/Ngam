import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';

import '../../models/gig_model.dart';
import '../../providers/gig_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import 'my_jobs_screen.dart';
import 'stats_screen.dart';
import '../shared/profile_screen.dart';
import '../shared/chat_screen.dart';
import '../../widgets/bottom_nav_runner.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

// ============================================================
// Ngam App — Runner Home Screen
// Discovery feed with glassmorphism map
// ============================================================

class RunnerHomeScreen extends StatefulWidget {
  const RunnerHomeScreen({super.key});

  @override
  State<RunnerHomeScreen> createState() => _RunnerHomeScreenState();
}

class _RunnerHomeScreenState extends State<RunnerHomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final gigProvider = context.read<GigProvider>();
      await gigProvider.loadOpenGigs();
      gigProvider.subscribeToOpenGigs();
      FlutterNativeSplash.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _RunnerExploreFeed(),
      const MyJobsScreen(),
      const ChatScreen(),
      const StatsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          pages[_currentIndex],
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: BottomNavRunner(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() => _currentIndex = index);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RunnerExploreFeed extends StatefulWidget {
  @override
  State<_RunnerExploreFeed> createState() => _RunnerExploreFeedState();
}

class _RunnerExploreFeedState extends State<_RunnerExploreFeed> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final MapController _mapController = MapController();
  final FocusNode _searchFocus = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  final Color _lightModeGray = const Color(0xFF3A3A3C);
  bool _isSearchPanelOpen = false;
  bool _isMapLocked = false;
  final double _baseLatitudeOffset = -0.0055;

  double get _adaptiveOffset {
    double currentZoom = _mapController.camera.zoom;
    return _baseLatitudeOffset * pow(2, 14.0 - currentZoom);
  }

  late PageController _pageController;
  Timer? _snapBackTimer;
  Timer? _debounce;
  StreamSubscription<Position>? _positionStream;

  LatLng _currentLocation = const LatLng(3.1390, 101.6869);
  bool _followUser = true;
  bool _isSearching = false;
  bool _isProfileOpen = false;

  GigModel? _selectedGig;
  int _currentCarouselIndex = 0;
  List<GigModel> _nearbyGigs = [];
  List<GigModel> _displayedGigs = [];
  String? _activeSearchQuery;

  Set<String> _expandedCategories = {};
  List<Map<String, dynamic>> _searchMatchedCategories = [];
  List<Map<String, dynamic>> _searchMatchedGigs = [];

  List<Map<String, dynamic>> _getCategoryTree(BuildContext context) {
    return [
      {
        'label': 'Task Categories',
        'id': 'group_all',
        'icon': HugeIcons.strokeRoundedTask01,
        'sub': TaskCategory.all.map((c) => {
          'label': c,
          'id': c.toLowerCase(),
        }).toList()
      }
    ];
  }

  LatLng _getDynamicCenterOffset(GigModel gig, double targetZoom) {
    if (gig.latitude == null || gig.longitude == null) return _currentLocation;
    double adaptiveOffset = _baseLatitudeOffset * pow(2, 14.0 - targetZoom) * 1.2;
    return LatLng(gig.latitude! + adaptiveOffset, gig.longitude!);
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _searchFocus.addListener(_onSearchFocusChanged);
    _initLocationTracking();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
       _updateGigs();
    });
  }
  
  void _updateGigs() {
    final currentUser = context.read<AuthProvider>().user;
    final gigProvider = context.read<GigProvider>();
    
    gigProvider.addListener(() {
      if (!mounted) return;
      final available = gigProvider.filteredGigs.where((g) => g.customerId != currentUser?.id && g.latitude != null && g.longitude != null).toList();
      
      available.sort((a, b) {
        double distanceA = Geolocator.distanceBetween(
            _currentLocation.latitude, _currentLocation.longitude,
            a.latitude!, a.longitude!
        );
        double distanceB = Geolocator.distanceBetween(
            _currentLocation.latitude, _currentLocation.longitude,
            b.latitude!, b.longitude!
        );
        return distanceA.compareTo(distanceB);
      });

      setState(() {
        _nearbyGigs = available;
        if (_searchController.text.isEmpty) {
          _displayedGigs = List.from(_nearbyGigs);
        }
      });
    });
  }

  void _onSearchFocusChanged() {
    if (_searchFocus.hasFocus && mounted) {
      setState(() {
        _isSearchPanelOpen = true;
      });
    }
  }

  @override
  void dispose() {
    _snapBackTimer?.cancel();
    _pageController.dispose();
    _positionStream?.cancel();
    _debounce?.cancel();
    _searchFocus.removeListener(_onSearchFocusChanged);
    _searchFocus.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(begin: _mapController.camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: _mapController.camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: _mapController.camera.zoom, end: destZoom);

    var controller = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    Animation<double> animation = CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      _mapController.move(LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)), zoomTween.evaluate(animation));
    });
    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) controller.dispose();
    });
    controller.forward();
  }

  void _killFocus() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (mounted) setState(() => _isSearchPanelOpen = false);
  }

  void _hideKeyboardOnly() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _onMapInteractionStart() {
    _killFocus();
    _snapBackTimer?.cancel();
    if (_followUser) setState(() => _followUser = false);
  }

  void _startSnapBackTimer() {
    _snapBackTimer?.cancel();
    _snapBackTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && !_followUser && _selectedGig == null && _searchController.text.isEmpty) {
        setState(() => _followUser = true);
        _animatedMapMove(_currentLocation, _mapController.camera.zoom);
      }
    });
  }

  void _onCarouselPageChanged(int index) {
    if (_isMapLocked) return;
    if (_pageController.page?.round() == index) {
      setState(() {
        _currentCarouselIndex = index;
        _selectedGig = _displayedGigs[index];
        _followUser = false;
      });
      
      final gig = _displayedGigs[index];
      if (gig.latitude != null && gig.longitude != null) {
        LatLng targetLocation = LatLng(gig.latitude!, gig.longitude!);
        LatLng offsetLocation = LatLng(targetLocation.latitude + _adaptiveOffset, targetLocation.longitude);
        _animatedMapMove(offsetLocation, _mapController.camera.zoom);
      }
    }
  }

  void _onMapPinTapped(GigModel gig, int index, {double? targetZoom}) {
    _killFocus();
    if (_selectedGig?.id == gig.id) {
      _showGigProfile(context, gig);
      return;
    }

    _isMapLocked = true;
    setState(() {
      _selectedGig = gig;
      _currentCarouselIndex = index;
      _followUser = false;
      _isProfileOpen = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.animateToPage(index, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      }

      double currentZoom = targetZoom ?? _mapController.camera.zoom;
      LatLng offsetLocation = _getDynamicCenterOffset(gig, currentZoom);
      _animatedMapMove(offsetLocation, currentZoom);
      _showGigProfile(context, gig);
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) _isMapLocked = false;
    });
  }

  void _executeCategorySearch(String categoryId, String categoryLabel, {bool isGroup = false}) {
    _killFocus();
    _searchController.text = categoryLabel;

    List<String> targetIds = [];
    if (isGroup) {
      var group = _getCategoryTree(context).firstWhere((g) => g['id'] == categoryId);
      targetIds = (group['sub'] as List).map((s) => s['id'] as String).toList();
    } else {
      targetIds = [categoryId];
    }

    List<GigModel> results = _nearbyGigs.where((gig) => targetIds.contains(gig.category.toLowerCase())).toList();
    _applySearchResults(results, categoryLabel);
  }

  void _applySearchResults(List<GigModel> results, String queryLabel) {
    setState(() {
      _displayedGigs = results;
      _activeSearchQuery = queryLabel;
      _searchMatchedCategories = [];
      _searchMatchedGigs = [];
      _isSearching = false;
      _selectedGig = results.isNotEmpty ? results.first : null;
      _currentCarouselIndex = 0;
    });

    if (results.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) _pageController.jumpToPage(0);
      });
      Future.delayed(const Duration(milliseconds: 50), () {
        if (!mounted) return;
        final gig = results.first;
        if (gig.latitude != null && gig.longitude != null) {
          _animatedMapMove(LatLng(gig.latitude!, gig.longitude!), 15.0);
        }
      });
    }
  }

  void _handleSearch(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchMatchedCategories = [];
        _searchMatchedGigs = [];
        _displayedGigs = List.from(_nearbyGigs);
        _activeSearchQuery = null;
      });
      return;
    }

    setState(() => _isSearching = true);

    _debounce = Timer(const Duration(milliseconds: 300), () {
      final String q = query.trim().toLowerCase();
      List<Map<String, dynamic>> catMatches = [];
      List<Map<String, dynamic>> gigMatches = [];

      for (var group in _getCategoryTree(context)) {
        if (group['label'].toLowerCase().contains(q)) {
          catMatches.add({'type': 'group', 'label': group['label'], 'id': group['id'], 'icon': group['icon'], 'sub': group['sub']});
        }
        for (var sub in group['sub']) {
          if (sub['label'].toLowerCase().contains(q)) {
            catMatches.add({'type': 'sub', 'label': sub['label'], 'id': sub['id'], 'icon': group['icon']});
          }
        }
      }

      for (var gig in _nearbyGigs) {
        final name = gig.title.toLowerCase();
        if (name.startsWith(q) || name.contains(" $q")) {
          gigMatches.add({'gig': gig, 'match_reason': null});
        } else if (gig.category.toLowerCase().contains(q)) {
          gigMatches.add({'gig': gig, 'match_reason': "Category: ${gig.category}"});
        }
      }

      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchMatchedCategories = catMatches;
          _searchMatchedGigs = gigMatches;
        });
      }
    });
  }

  void _executeSearch(String query) {
    _killFocus();
    if (query.trim().isEmpty) {
      _clearSearch();
      return;
    }
    List<GigModel> results = _searchMatchedGigs.map((e) => e['gig'] as GigModel).toList();
    _applySearchResults(results, query);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchMatchedCategories = [];
      _searchMatchedGigs = [];
      _isSearching = false;
      _displayedGigs = List.from(_nearbyGigs);
      _activeSearchQuery = null;
      _selectedGig = null;
    });
  }

  Future<void> _initLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;
    }

    try {
      Position initialPos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high, timeLimit: const Duration(seconds: 4));
      if (mounted) {
        setState(() => _currentLocation = LatLng(initialPos.latitude, initialPos.longitude));
        if (_followUser) {
          double zoom = 14.0;
          try { zoom = _mapController.camera.zoom; } catch (_) {}
          double adaptiveOffset = _baseLatitudeOffset * pow(2, 14.0 - zoom);
          _mapController.move(LatLng(initialPos.latitude + adaptiveOffset, initialPos.longitude), zoom);
        }
      }
    } catch (_) {}

    _positionStream = Geolocator.getPositionStream(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10)).listen((Position pos) {
      if (!mounted) return;
      setState(() => _currentLocation = LatLng(pos.latitude, pos.longitude));
      if (_followUser) {
        double zoom = 14.0;
        try { zoom = _mapController.camera.zoom; } catch (_) {}
        double adaptiveOffset = _baseLatitudeOffset * pow(2, 14.0 - zoom);
        _animatedMapMove(LatLng(pos.latitude + adaptiveOffset, pos.longitude), zoom);
      }
    });
  }

  String _getDistanceString(GigModel gig) {
    if (gig.latitude == null || gig.longitude == null) return "Unknown distance";
    double m = Geolocator.distanceBetween(_currentLocation.latitude, _currentLocation.longitude, gig.latitude!, gig.longitude!);
    return m < 1000 ? "${m.toStringAsFixed(0)} m" : "${(m / 1000).toStringAsFixed(1)} km";
  }

  LiquidGlassSettings _getGlassSettings(bool isDark, {double blur = 2.0}) {
    return LiquidGlassSettings(
      thickness: 0.1,
      blur: blur,
      refractiveIndex: 1.0,
      glassColor: Colors.transparent,
      lightAngle: 45.0,
      lightIntensity: isDark ? 0.1 : 0.2,
      ambientStrength: 1.0,
      saturation: 1.0,
      chromaticAberration: 0.0,
    );
  }

  Future<void> _getDirections(GigModel gig) async {
    final double lat = gig.latitude ?? 3.1415;
    final double lng = gig.longitude ?? 101.6865;
    final String mapUrl = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
    final Uri uri = Uri.parse(mapUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isSearchActive = _isSearchPanelOpen;
    final bool hideBottomPanel = isSearchActive || _isProfileOpen;
    final double bottomPosition = hideBottomPanel ? -500 : (MediaQuery.of(context).viewInsets.bottom > 0 ? MediaQuery.of(context).viewInsets.bottom + 20 : 110);

    return PopScope(
      canPop: !_searchFocus.hasFocus && _searchController.text.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _killFocus();
          _clearSearch();
        }
      },
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          _killFocus();
        },
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              Listener(
                onPointerDown: (_) => _onMapInteractionStart(),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentLocation,
                    initialZoom: 14.0,
                    minZoom: 3.5,
                    maxZoom: 22.0,
                    cameraConstraint: CameraConstraint.contain(bounds: LatLngBounds(const LatLng(-90, -180), const LatLng(90, 180))),
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                    onTap: (tapPosition, latLng) {
                      _killFocus();
                      _clearSearch();
                    },
                    onPositionChanged: (pos, hasGesture) {
                      if (hasGesture) _onMapInteractionStart();
                      else _startSnapBackTimer();
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: isDark
                          ? 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                          : 'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.ngam',
                      retinaMode: RetinaMode.isHighDensity(context),
                    ),
                    MarkerClusterLayerWidget(
                      options: MarkerClusterLayerOptions(
                        maxClusterRadius: 45,
                        size: const Size(40, 40),
                        onMarkerTap: (Marker marker) {
                          final gigId = (marker.key as ValueKey).value;
                          final index = _displayedGigs.indexWhere((s) => s.id == gigId);
                          if (index != -1) _onMapPinTapped(_displayedGigs[index], index);
                        },
                        markers: _displayedGigs.asMap().entries.where((e) => e.value != _selectedGig && e.value.latitude != null).map((e) {
                          final GigModel gig = e.value;
                          return Marker(
                            key: ValueKey(gig.id),
                            point: LatLng(gig.latitude!, gig.longitude!),
                            width: 44,
                            height: 44,
                            child: _buildMarkerPin(gig, false),
                          );
                        }).toList(),
                        builder: (context, markers) {
                          return Container(
                            decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2)]
                            ),
                            child: Center(
                              child: Text(
                                markers.length.toString(),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    MarkerLayer(markers: [
                      Marker(point: _currentLocation, width: 60, height: 60, child: const _PulsingUserMarker()),
                      if (_selectedGig != null && _selectedGig!.latitude != null)
                        Marker(
                            point: LatLng(_selectedGig!.latitude!, _selectedGig!.longitude!),
                            width: 35,
                            height: 35,
                            child: Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.center,
                                children: [
                                  Positioned(
                                      bottom: 35,
                                      left: -150,
                                      right: -150,
                                      child: Align(
                                        alignment: Alignment.bottomCenter,
                                        child: _buildGigPopup(_selectedGig!, isDark),
                                      )
                                  ),
                                  _buildMarkerPin(_selectedGig!, true)
                                ]
                            )
                        ),
                    ]),
                  ],
                ),
              ),
              Positioned(top: MediaQuery.of(context).padding.top + 20, left: 0, right: 0, child: _buildSearchRow(isDark)),
              Positioned(top: MediaQuery.of(context).padding.top + 80, left: 24, right: 24,
                  child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: isSearchActive ? 1.0 : 0.0,
                      child: isSearchActive ? _buildResultsGlass(isDark) : const SizedBox.shrink())),
              AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOutBack,
                  bottom: bottomPosition,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: hideBottomPanel ? 0.0 : 1.0,
                      child: _buildBottomGlassPanel(isDark))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchRow(bool isDark) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Row(children: [
      Expanded(
        child: GlassContainer(
          useOwnLayer: true,
          quality: GlassQuality.standard,
          shape: LiquidRoundedSuperellipse(borderRadius: 24.0),
          settings: _getGlassSettings(isDark),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.4), width: 1.0),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                SizedBox(width: 20, height: 20, child: _isSearching
                    ? CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(isDark ? Colors.white : _lightModeGray))
                    : HugeIcon(icon: HugeIcons.strokeRoundedSearch01, color: isDark ? Colors.white70 : _lightModeGray.withValues(alpha: 0.6), size: 20, strokeWidth: 2.0)),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController, focusNode: _searchFocus, onChanged: _handleSearch, onSubmitted: _executeSearch,
                    style: TextStyle(color: isDark ? Colors.white : _lightModeGray, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'Search available jobs...', 
                      hintStyle: TextStyle(color: isDark ? Colors.white38 : _lightModeGray.withValues(alpha: 0.4), fontSize: 14), 
                      border: InputBorder.none, 
                      isDense: true,
                      filled: false,
                    ),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  GestureDetector(onTap: _clearSearch, child: Icon(Icons.close, size: 18, color: isDark ? Colors.white70 : _lightModeGray.withValues(alpha: 0.6))),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      _AnimatedPressable(
        onTap: () {
          _killFocus();
          Navigator.pushNamed(context, '/qr-scanner');
        },
        child: GlassContainer(
          useOwnLayer: true,
          quality: GlassQuality.standard,
          shape: LiquidRoundedSuperellipse(borderRadius: 100.0),
          settings: _getGlassSettings(isDark),
          child: Container(
            height: 48, width: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.4), width: 1.0),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Center(child: HugeIcon(icon: HugeIcons.strokeRoundedQrCode01, color: isDark ? Colors.white70 : _lightModeGray, size: 22, strokeWidth: 2.0)),
          ),
        ),
      ),
    ]),
  );

  Widget _buildResultsGlass(bool isDark) {
    final bool isTyping = _searchController.text.isNotEmpty;
    Widget content;
    if (isTyping && _isSearching) {
      content = const Padding(padding: EdgeInsets.all(32.0), child: Center(child: CircularProgressIndicator(color: Colors.blue)));
    } else if (isTyping && _searchMatchedCategories.isEmpty && _searchMatchedGigs.isEmpty) {
      content = Padding(padding: const EdgeInsets.all(32.0), child: Center(child: Text("No matches found", style: TextStyle(color: isDark ? Colors.white54 : Colors.black54))));
    } else if (isTyping) {
      content = ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shrinkWrap: true, physics: const ClampingScrollPhysics(), keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          if (_searchMatchedCategories.isNotEmpty) ...[
            const Padding(padding: EdgeInsets.only(left: 24, bottom: 8, top: 8), child: Text("CATEGORIES", style: TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2))),
            ..._searchMatchedCategories.map((cat) {
              return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  leading: HugeIcon(icon: cat['icon'] ?? HugeIcons.strokeRoundedTask01, color: isDark ? Colors.white70 : Colors.black87, size: 20),
                  title: Text(cat['label'], style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14, fontWeight: FontWeight.w600)),
                  onTap: () {
                    _hideKeyboardOnly();
                    _executeCategorySearch(cat['id'], cat['label'], isGroup: false);
                  }
              );
            }),
            if (_searchMatchedGigs.isNotEmpty) Divider(color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.3), indent: 24, endIndent: 24),
          ],
          if (_searchMatchedGigs.isNotEmpty) ...[
            const Padding(padding: EdgeInsets.only(left: 24, bottom: 8, top: 8), child: Text("JOBS", style: TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2))),
            ..._searchMatchedGigs.map((match) {
              final gig = match['gig'] as GigModel;
              final reason = match['match_reason'] as String?;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                leading: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.3), border: Border.all(color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.5), width: 1.0)),
                  child: Center(child: Text(TaskCategory.icon(gig.category), style: const TextStyle(fontSize: 16))),
                ),
                title: Text(gig.title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: reason != null ? Text(reason, style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold)) : null,
                onTap: () {
                  _killFocus();
                  _searchController.text = gig.title;
                  setState(() {
                    _displayedGigs = [gig];
                    _activeSearchQuery = gig.title;
                    _isSearching = false;
                    _selectedGig = gig;
                    _currentCarouselIndex = 0;
                  });
                  if (gig.latitude != null) {
                    LatLng offsetLocation = _getDynamicCenterOffset(gig, 15.0);
                    _animatedMapMove(offsetLocation, 15.0);
                  }
                  Future.delayed(const Duration(milliseconds: 150), () {
                    _showGigProfile(context, gig);
                  });
                },
              );
            }),
          ]
        ],
      );
    } else {
      content = ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shrinkWrap: true, physics: const ClampingScrollPhysics(), keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          itemCount: _getCategoryTree(context).length,
          itemBuilder: (context, index) {
            var group = _getCategoryTree(context)[index];
            bool isExpanded = _expandedCategories.contains(group['id']);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: isExpanded ? Colors.blue.withValues(alpha: 0.15) : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                    child: HugeIcon(icon: group['icon'], color: isExpanded ? Colors.blue : (isDark ? Colors.white70 : Colors.black87), size: 20),
                  ),
                  title: Text(group['label'], style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 15, fontWeight: isExpanded ? FontWeight.bold : FontWeight.w600)),
                  trailing: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: isExpanded ? 0.5 : 0.0), duration: const Duration(milliseconds: 300),
                      builder: (context, turns, child) { return Transform.rotate(angle: turns * 2 * math.pi, child: child); },
                      child: HugeIcon(icon: HugeIcons.strokeRoundedArrowDown01, color: isDark ? Colors.white54 : Colors.black54, size: 20)
                  ),
                  onTap: () {
                    _hideKeyboardOnly();
                    setState(() {
                      if (isExpanded) { _expandedCategories.remove(group['id']); } else { _expandedCategories.clear(); _expandedCategories.add(group['id']); }
                    });
                  },
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300), curve: Curves.easeInOut,
                  child: !isExpanded ? const SizedBox.shrink() : Padding(
                    padding: const EdgeInsets.only(left: 64, right: 24, bottom: 8),
                    child: Column(
                        children: [
                          ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text("All ${group['label']}", style: const TextStyle(color: Colors.blue, fontSize: 14, fontWeight: FontWeight.bold)),
                              trailing: HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, color: Colors.blue.withValues(alpha: 0.5), size: 16),
                              onTap: () {
                                _hideKeyboardOnly();
                                _executeCategorySearch(group['id'], group['label'], isGroup: true);
                              }
                          ),
                          ...(group['sub'] as List).map((sub) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(sub['label'], style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14)),
                              trailing: HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, color: isDark ? Colors.white24 : Colors.black26, size: 16),
                              onTap: () {
                                _hideKeyboardOnly();
                                _executeCategorySearch(sub['id'], sub['label'], isGroup: false);
                              }
                          )).toList(),
                        ]
                    ),
                  ),
                ),
              ],
            );
          }
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(28.0),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(28.0),
            border: Border.all(color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.6), width: 1.0),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: AnimatedSwitcher(duration: const Duration(milliseconds: 200), child: content),
        ),
      ),
    );
  }

  Widget _buildBottomGlassPanel(bool isDark) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
            padding: const EdgeInsets.only(right: 24, bottom: 4),
            child: Align(
                alignment: Alignment.centerRight,
                child: _AnimatedPressable(
                    onTap: () {
                      setState(() => _followUser = true);
                      double zoom = 14.0;
                      try { zoom = _mapController.camera.zoom; } catch (_) {}
                      double adaptiveOffset = _baseLatitudeOffset * pow(2, 14.0 - zoom);
                      LatLng offsetLocation = LatLng(_currentLocation.latitude + adaptiveOffset, _currentLocation.longitude);
                      _animatedMapMove(offsetLocation, zoom);
                    },
                    child: GlassContainer(
                      useOwnLayer: true, quality: GlassQuality.standard, shape: LiquidRoundedSuperellipse(borderRadius: 100.0), settings: _getGlassSettings(isDark),
                      child: Container(
                          height: 48, width: 48,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), border: Border.all(color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.4), width: 1.0), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05), blurRadius: 12, offset: const Offset(0, 4))]),
                          child: Center(child: HugeIcon(icon: HugeIcons.strokeRoundedLocationShare02, color: _followUser ? Colors.blue : (isDark ? Colors.white70 : _lightModeGray), size: 22, strokeWidth: 2.0))
                      ),
                    )
                )
            )
        ),
        Padding(
            padding: EdgeInsets.only(left: (MediaQuery.of(context).size.width * 0.075) + 8, bottom: 4),
            child: Text(_activeSearchQuery == null ? 'Nearby Jobs' : (_displayedGigs.isNotEmpty ? 'Results for "$_activeSearchQuery"' : 'No Results Found'),
                style: TextStyle(color: isDark ? Colors.white : _lightModeGray, fontSize: 18, fontWeight: FontWeight.bold)
            )
        ),
        SizedBox(height: 135, child: PageView.builder(controller: _pageController, onPageChanged: _onCarouselPageChanged, physics: const ClampingScrollPhysics(), itemCount: _displayedGigs.length, itemBuilder: (context, i) => _AnimatedPressable(onTap: () => _onMapPinTapped(_displayedGigs[i], i), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: _buildCarouselCard(isDark, _displayedGigs[i]))))),
      ]);

  Widget _buildGigPopup(GigModel gig, bool isDark) {
    final frostedGlow = [Shadow(color: Colors.white.withValues(alpha: 0.5), blurRadius: 8), Shadow(color: Colors.black.withValues(alpha: 0.2), offset: const Offset(0.5, 0.5), blurRadius: 0)];
    return TweenAnimationBuilder<double>(
      key: ValueKey("popup_${gig.id}"),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(scale: value, alignment: Alignment.bottomCenter, child: Opacity(opacity: value.clamp(0.0, 1.0), child: child));
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(bottom: -6, child: Transform.rotate(angle: 0.785398, child: ClipRRect(borderRadius: BorderRadius.circular(2), child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0), child: Container(width: 16, height: 16, decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.1), border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.4), width: 1.0), right: BorderSide(color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.4), width: 1.0)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05), blurRadius: 12, offset: const Offset(2, 2))])))))),
            GlassContainer(
              useOwnLayer: true, quality: GlassQuality.standard, shape: LiquidRoundedSuperellipse(borderRadius: 12.0), settings: _getGlassSettings(isDark),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.1), border: Border.all(color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.4), width: 1.0)),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 160, child: Text(gig.title, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: isDark ? Colors.white : _lightModeGray, shadows: isDark ? frostedGlow : []))),
                      const SizedBox(height: 4),
                      Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(gig.formattedBounty, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
                            Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Text("|", style: TextStyle(color: isDark ? Colors.white24 : _lightModeGray.withValues(alpha: 0.2), fontSize: 10))),
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              HugeIcon(icon: HugeIcons.strokeRoundedStore01, color: Colors.blue, size: 10, strokeWidth: 2.5),
                              const SizedBox(width: 3),
                              Text(gig.status, style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                            ])
                          ]
                      ),
                    ]
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkerPin(GigModel gig, bool sel) {
    Color pinColor = Colors.blue;
    bool isUnfocused = _selectedGig != null && !sel;

    Widget pin = AnimatedContainer(
      duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic,
      width: sel ? 44.0 : 35.0, height: sel ? 44.0 : 35.0,
      decoration: BoxDecoration(
        color: sel ? pinColor : pinColor.withValues(alpha: 0.85),
        shape: BoxShape.circle, border: Border.all(color: Colors.white, width: sel ? 2.5 : 1.0),
        boxShadow: [if (!isUnfocused) BoxShadow(color: pinColor.withValues(alpha: sel ? 0.6 : 0.4), blurRadius: sel ? 16 : 8, spreadRadius: sel ? 4 : 1)],
      ),
      child: Center(child: Text(TaskCategory.icon(gig.category), style: TextStyle(fontSize: sel ? 20 : 15))),
    );

    return AnimatedOpacity(duration: const Duration(milliseconds: 300), opacity: isUnfocused ? 0.4 : 1.0, child: OverflowBox(maxWidth: 60, maxHeight: 60, child: pin));
  }

  Widget _buildCarouselCard(bool isDark, GigModel gig) {
    final frostedGlow = [Shadow(color: Colors.white.withValues(alpha: 0.5), blurRadius: 8), Shadow(color: Colors.black.withValues(alpha: 0.2), offset: const Offset(0.5, 0.5), blurRadius: 0)];

    return GlassContainer(
      useOwnLayer: true, quality: GlassQuality.standard, shape: LiquidRoundedSuperellipse(borderRadius: 24.0), settings: _getGlassSettings(isDark),
      child: Container(
        width: 285, padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.4), width: 1.0),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
            children: [
              Container(
                  width: 70, height: 70,
                  decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                  child: Center(child: Text(TaskCategory.icon(gig.category), style: const TextStyle(fontSize: 32)))
              ),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(gig.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: isDark ? Colors.white : _lightModeGray, shadows: isDark ? frostedGlow : [])),
                        const SizedBox(height: 6),
                        Row(children: [
                          HugeIcon(icon: HugeIcons.strokeRoundedLocation01, color: isDark ? Colors.white : _lightModeGray, size: 14, strokeWidth: 2.5),
                          const SizedBox(width: 4),
                          Flexible(child: Text(_getDistanceString(gig), style: TextStyle(fontSize: 12, color: isDark ? Colors.white : _lightModeGray, fontWeight: FontWeight.w600, shadows: isDark ? frostedGlow : []), overflow: TextOverflow.ellipsis))
                        ])
                      ]
                  )
              )
            ]
        ),
      ),
    );
  }

  void _showGigProfile(BuildContext context, GigModel gig) {
    setState(() => _isProfileOpen = true);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final double topSafeArea = MediaQuery.of(context).padding.top;
    final double bottomSafeArea = MediaQuery.of(context).padding.bottom;
    final double screenHeight = MediaQuery.of(context).size.height;
    bool localIsDescExpanded = false;

    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, barrierColor: Colors.transparent, elevation: 0, isScrollControlled: true, useSafeArea: false,
      builder: (context) {
        return LayoutBuilder(builder: (context, constraints) {
          double textAvailableWidth = constraints.maxWidth - 108;
          final TextPainter textPainter = TextPainter(text: TextSpan(text: gig.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), textDirection: ui.TextDirection.ltr, maxLines: 2)..layout(maxWidth: textAvailableWidth);
          int numLines = textPainter.computeLineMetrics().length;
          double baseHeight = numLines > 1 ? 430.0 : 400;
          double adaptiveInitialSize = (baseHeight + bottomSafeArea) / screenHeight;
          adaptiveInitialSize = adaptiveInitialSize.clamp(0.40, 0.85);
          double sheetExtent = adaptiveInitialSize;

          return DraggableScrollableSheet(
            initialChildSize: adaptiveInitialSize, minChildSize: adaptiveInitialSize, maxChildSize: 1.0, expand: false,
            builder: (context, scrollController) {
              return StatefulBuilder(builder: (BuildContext context, StateSetter setSheetState) {
                double currentRadius = ((1.0 - sheetExtent) * 150).clamp(0.0, 32.0);
                return NotificationListener<DraggableScrollableNotification>(
                  onNotification: (notification) {
                    if (sheetExtent != notification.extent) setSheetState(() => sheetExtent = notification.extent);
                    return true;
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(currentRadius)),
                    child: Stack(
                      children: [
                        Positioned.fill(child: GlassContainer(useOwnLayer: true, quality: GlassQuality.standard, shape: LiquidRoundedSuperellipse(borderRadius: currentRadius), settings: _getGlassSettings(isDark, blur: 4), child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.4), width: 1.0), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05), blurRadius: 12, offset: const Offset(0, 4))])))),
                        ListView(
                          controller: scrollController, padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 120),
                          children: [
                            AnimatedOpacity(duration: const Duration(milliseconds: 150), opacity: sheetExtent > 0.95 ? 0.0 : 1.0, child: Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white24 : _lightModeGray.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10))))),
                            const SizedBox(height: 24),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(gig.title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : _lightModeGray), maxLines: 2, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 6),
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Text(gig.category.toUpperCase(), style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                            const SizedBox(width: 12),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue)),
                                              child: Text(gig.status, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildInnerGlassCard(
                              isDark: isDark, radius: 20.0, padding: const EdgeInsets.symmetric(vertical: 18),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(child: _buildStatItem(HugeIcons.strokeRoundedMoney01, gig.formattedBounty, 'Bounty', isDark)),
                                  _buildVerticalDivider(isDark),
                                  Expanded(child: _buildStatItem(HugeIcons.strokeRoundedUserGroup, gig.customerName ?? 'User', 'Customer', isDark)),
                                  _buildVerticalDivider(isDark),
                                  Expanded(child: _buildStatItem(HugeIcons.strokeRoundedLocation01, _getDistanceString(gig), 'Away', isDark)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(flex: 2, child: _buildActionButton(HugeIcons.strokeRoundedRoute01, "Directions", isDark, true, onTap: () => _getDirections(gig))),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildSectionTitle("Task Description", isDark),
                            GestureDetector(
                              onTap: () { setSheetState(() => localIsDescExpanded = !localIsDescExpanded); },
                              child: AnimatedSize(
                                duration: const Duration(milliseconds: 300), curve: Curves.easeInOut, alignment: Alignment.topCenter, clipBehavior: Clip.hardEdge,
                                child: _buildInnerGlassCard(
                                  isDark: isDark, radius: 16.0, padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text("Details", style: TextStyle(color: isDark ? Colors.white : _lightModeGray, fontSize: 14, fontWeight: FontWeight.bold)),
                                          TweenAnimationBuilder<double>(
                                            tween: Tween<double>(begin: 0.0, end: localIsDescExpanded ? 0.5 : 0.0), duration: const Duration(milliseconds: 300), curve: Curves.easeOutBack,
                                            builder: (context, turns, child) { return Transform.rotate(angle: turns * 2 * math.pi, child: child); },
                                            child: HugeIcon(icon: HugeIcons.strokeRoundedArrowDown01, color: isDark ? Colors.white54 : _lightModeGray.withValues(alpha: 0.5), size: 20, strokeWidth: 2.0),
                                          )
                                        ],
                                      ),
                                      if (localIsDescExpanded) ...[
                                        Padding(padding: const EdgeInsets.symmetric(vertical: 12.0), child: Divider(color: isDark ? Colors.white12 : Colors.black12, height: 1)),
                                        Text(gig.description, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13, height: 1.5)),
                                      ]
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildSectionTitle("Location Address", isDark),
                            _buildInnerGlassCard(
                                isDark: isDark, radius: 20.0, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                overrideColor: Colors.blue.withValues(alpha: isDark ? 0.1 : 0.15),
                                overrideBorder: Colors.blue.withValues(alpha: 0.3),
                                child: Text(gig.location, style: const TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.w600))
                            ),
                          ],
                        ),
                        Positioned(
                          bottom: 0, left: 0, right: 0,
                          child: Container(
                            padding: EdgeInsets.only(left: 24, right: 24, bottom: bottomSafeArea + 16, top: 16),
                            decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [isDark ? const Color(0xFF1A1A1A) : const Color(0xFFEBE7E3), isDark ? const Color(0xFF1A1A1A).withValues(alpha: 0.0) : const Color(0xFFEBE7E3).withValues(alpha: 0.0)])),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _AnimatedPressable(
                                    onTap: () {
                                      _searchFocus.unfocus();
                                      Navigator.pop(context);
                                      Navigator.pushNamed(context, '/task-detail', arguments: gig);
                                    },
                                    child: _buildInnerGlassCard(isDark: isDark, radius: 18.0, padding: const EdgeInsets.symmetric(vertical: 18), child: Center(child: Text("View Details", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)))),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _AnimatedPressable(
                                    onTap: () async {
                                      final currentUser = context.read<AuthProvider>().user;
                                      if (currentUser == null) return;
                                      final provider = context.read<GigProvider>();
                                      final success = await provider.acceptGig(gig.id, currentUser.id);
                                      if (success && context.mounted) {
                                          _searchFocus.unfocus();
                                          Navigator.pop(context);
                                          Navigator.pushNamed(context, '/active-job', arguments: gig);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 18),
                                      decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))]),
                                      child: const Center(child: Text("Accept Job", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              });
            },
          );
        });
      },
    ).whenComplete(() {
      if (mounted) setState(() => _isProfileOpen = false);
    });
  }

  Widget _buildInnerGlassCard({required Widget child, required bool isDark, double radius = 16.0, EdgeInsetsGeometry? padding, Color? overrideColor, Color? overrideBorder}) {
    return GlassContainer(
      useOwnLayer: true, quality: GlassQuality.standard, shape: LiquidRoundedSuperellipse(borderRadius: radius), settings: _getGlassSettings(isDark),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: overrideColor ?? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.4)),
          border: Border.all(color: overrideBorder ?? Colors.white.withValues(alpha: isDark ? 0.15 : 0.4), width: 1.0),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.02), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: child,
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(title, style: TextStyle(color: isDark ? Colors.white : _lightModeGray, fontSize: 16, fontWeight: FontWeight.bold)));
  }

  Widget _buildStatItem(dynamic icon, String value, String label, bool isDark) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      HugeIcon(icon: icon, color: Colors.blue, size: 20, strokeWidth: 2.0),
      const SizedBox(height: 8),
      Text(value, style: TextStyle(color: isDark ? Colors.white : _lightModeGray, fontWeight: FontWeight.bold, fontSize: 14)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(color: isDark ? Colors.white38 : _lightModeGray.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.w500)),
    ],
  );

  Widget _buildVerticalDivider(bool isDark) => Container(height: 30, width: 1, color: isDark ? Colors.white.withValues(alpha: 0.1) : _lightModeGray.withValues(alpha: 0.1));

  Widget _buildActionButton(dynamic icon, String? label, bool isDark, bool isPrimary, {VoidCallback? onTap}) {
    Color contentColor = isPrimary ? Colors.white : (isDark ? Colors.white : _lightModeGray);
    return GestureDetector(
      onTap: onTap,
      child: _buildInnerGlassCard(
        isDark: isDark, radius: 14.0, padding: const EdgeInsets.symmetric(vertical: 12),
        overrideColor: isPrimary ? Colors.blue.withValues(alpha: isDark ? 0.3 : 0.7) : null,
        overrideBorder: isPrimary ? Colors.blue.withValues(alpha: isDark ? 0.5 : 0.9) : null,
        child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(icon: icon, color: contentColor, size: 18, strokeWidth: 2.0),
              if (label != null) ...[const SizedBox(width: 8), Text(label, style: TextStyle(color: contentColor, fontWeight: FontWeight.w600))]
            ]
        ),
      ),
    );
  }
}

class _AnimatedPressable extends StatefulWidget {
  final Widget child; final VoidCallback onTap;
  const _AnimatedPressable({required this.child, required this.onTap});
  @override
  State<_AnimatedPressable> createState() => _AnimatedPressableState();
}
class _AnimatedPressableState extends State<_AnimatedPressable> with SingleTickerProviderStateMixin {
  late AnimationController _c; late Animation<double> _s;
  @override
  void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 100)); _s = Tween<double>(begin: 1.0, end: 0.94).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut)); }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) { return GestureDetector(onTapDown: (_) => _c.forward(), onTapUp: (_) { _c.reverse(); widget.onTap(); }, onTapCancel: () => _c.reverse(), child: ScaleTransition(scale: _s, child: widget.child)); }
}

class _PulsingUserMarker extends StatefulWidget {
  const _PulsingUserMarker();
  @override
  State<_PulsingUserMarker> createState() => _PulsingUserMarkerState();
}
class _PulsingUserMarkerState extends State<_PulsingUserMarker> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(); }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Stack(alignment: Alignment.center, children: [
      FadeTransition(opacity: ReverseAnimation(Tween<double>(begin: 0.0, end: 1.0).animate(_c)), child: ScaleTransition(scale: Tween<double>(begin: 1.0, end: 2.5).animate(_c), child: Container(width: 30, height: 30, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withValues(alpha: 0.3))))),
      Container(width: 30, height: 30, decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle, border: Border.all(color: Colors.blue.withValues(alpha: 0.2), width: 1.5)), child: const Center(child: HugeIcon(icon: HugeIcons.strokeRoundedLocationUser01, color: Colors.blue, size: 20, strokeWidth: 2.5))),
    ]);
  }
}
