import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:getfittoday_mobile/constants.dart';
import 'package:getfittoday_mobile/models/fitness_spot.dart';
import 'package:getfittoday_mobile/models/reservation.dart';
import 'package:getfittoday_mobile/services/fitness_spot_service.dart';
import 'package:getfittoday_mobile/services/reservation_service.dart';
import 'package:getfittoday_mobile/widgets/site_navbar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

class BookingReservationPage extends StatefulWidget {
  const BookingReservationPage({super.key});

  @override
  State<BookingReservationPage> createState() => _BookingReservationPageState();
}

class _BookingReservationPageState extends State<BookingReservationPage> {
  final _formKey = GlobalKey<FormState>();
  final _classController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final FocusNode _locationFocusNode = FocusNode();
  final _locationService = FitnessSpotService();
  final _reservationService = ReservationService();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedTimeLabel;
  String _selectedDuration = '1 Jam';
  FitnessSpot? _selectedLocation;
  bool _filterTopRated = false;
  bool _sortByNearest = true;
  Position? _userPosition;

  late Future<List<Reservation>> _reservationsFuture;
  late Future<void> _locationsFuture;
  bool _futureInitialized = false;
  List<FitnessSpot> _allLocations = const [];
  List<FitnessSpot> _locations = const [];
  List<Reservation> _myReservations = const [];

  final List<String> _timeSlots =
      List.generate(15, (index) => '${(index + 8).toString().padLeft(2, '0')}:00');
  final List<String> _durations = const [
    '30 Menit',
    '1 Jam',
    '1.5 Jam',
    '2 Jam',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _dateController.text = _formatDate(_selectedDate!);
  }

  @override
  void dispose() {
    _classController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _locationFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_futureInitialized) {
      final request = context.read<CookieRequest>();
      _reloadReservations(request);
      _locationsFuture = _loadLocations(request);
      _futureInitialized = true;
    }
  }

  Future<void> _reloadReservations(CookieRequest request) async {
    final future = _fetchReservations(request);
    setState(() {
      _reservationsFuture = future;
    });
    try {
      final result = await future;
      if (mounted) {
        setState(() => _myReservations = result);
      }
    } catch (_) {
      // handled by UI FutureBuilder
    }
  }

  Future<List<Reservation>> _fetchReservations(CookieRequest request) {
    return _reservationService.fetchMine(request);
  }

  Future<void> _loadLocations(CookieRequest request) async {
    final results = await _locationService.fetchFitnessSpots(request);
    List<FitnessSpot> enriched = results;
    try {
      _userPosition ??= await _getUserPosition();
      if (_userPosition != null) {
        enriched = results
            .map((spot) => _withDistanceFromUser(spot, _userPosition!))
            .toList();
      }
    } catch (_) {
      // Jika gagal dapat lokasi, gunakan data apa adanya.
    }
    enriched.sort(_locationComparator);
    if (!mounted) return;
    setState(() {
      _allLocations = enriched;
      // Saat pertama kali load, jangan aktifkan filter rating dulu.
      _locations = _applyLocationFilters(enriched, topRatedOnly: _filterTopRated);
    });
  }

  int _locationComparator(FitnessSpot a, FitnessSpot b) {
    if (_sortByNearest) {
      final aDist = a.distanceKm;
      final bDist = b.distanceKm;
      if (aDist != null && bDist != null) {
        return aDist.compareTo(bDist);
      }
      if (aDist != null) return -1;
      if (bDist != null) return 1;
    }
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  List<FitnessSpot> _applyLocationFilters(
    List<FitnessSpot> source, {
    required bool topRatedOnly,
  }) {
    var list = List<FitnessSpot>.from(source);
    if (topRatedOnly) {
      list = list.where((loc) => (loc.rating ?? 0) >= 4.5).toList();
    }
    list.sort(_locationComparator);
    return list;
  }

  Future<Position?> _getUserPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition();
    } catch (_) {
      return null;
    }
  }

  FitnessSpot _withDistanceFromUser(FitnessSpot spot, Position position) {
    final meters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      spot.latitude,
      spot.longitude,
    );
    final km = meters / 1000.0;

    return FitnessSpot(
      name: spot.name,
      latitude: spot.latitude,
      longitude: spot.longitude,
      address: spot.address,
      rating: spot.rating,
      placeId: spot.placeId,
      ratingCount: spot.ratingCount,
      website: spot.website,
      phoneNumber: spot.phoneNumber,
      types: spot.types,
      distanceKm: km,
      description: spot.description,
    );
  }

  void _showLocationFilterSheet() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        bool sortNearest = _sortByNearest;
        bool topRated = _filterTopRated;
        return StatefulBuilder(
          builder: (context, setModalState) {
            final media = MediaQuery.of(context);
            final maxWidth =
                media.size.width > 520 ? 420.0 : media.size.width * 0.9;
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Material(
                    color: Colors.white,
                    elevation: 10,
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Filter lokasi',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: inputTextColor,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  size: 20,
                                  color: inkWeakColor,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => Navigator.of(dialogContext).pop(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Urutkan',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: inkWeakColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () {
                                  setModalState(() {
                                    sortNearest = !sortNearest;
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: sortNearest
                                        ? primaryNavColor
                                        : Colors.black26,
                                  ),
                                  backgroundColor: sortNearest
                                      ? primaryNavColor.withOpacity(0.06)
                                      : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: Icon(
                                  Icons.near_me,
                                  size: 18,
                                  color: sortNearest
                                      ? primaryNavColor
                                      : inkWeakColor,
                                ),
                                label: Text(
                                  'Terdekat',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: sortNearest
                                        ? primaryNavColor
                                        : inputTextColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Rating',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: inkWeakColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () {
                                  setModalState(() {
                                    topRated = !topRated;
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: topRated
                                        ? primaryNavColor
                                        : Colors.black26,
                                  ),
                                  backgroundColor: topRated
                                      ? primaryNavColor.withOpacity(0.06)
                                      : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                              ),
                              icon: Icon(
                                Icons.star,
                                size: 18,
                                color: topRated
                                    ? Colors.amber[700]
                                    : inkWeakColor,
                              ),
                              label: Text(
                                  '4.5+',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: topRated
                                        ? primaryNavColor
                                        : inputTextColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _sortByNearest = sortNearest;
                                    _filterTopRated = topRated;
                                    _locations = _applyLocationFilters(
                                      _allLocations,
                                      topRatedOnly: topRated,
                                    );
                                  });
                                  // Paksa RawAutocomplete menghitung ulang opsi
                                  // berdasarkan daftar lokasi terbaru.
                                  _locationController.value =
                                      _locationController.value.copyWith(
                                    text: _locationController.text,
                                  );
                                  Navigator.of(dialogContext).pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryNavColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Terapkan'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  int _durationInMinutes() {
    switch (_selectedDuration) {
      case '30 Menit':
        return 30;
      case '1 Jam':
        return 60;
      case '1.5 Jam':
        return 90;
      case '2 Jam':
      default:
        return 120;
    }
  }

  Set<String> _disabledSlotsForSelected() {
    if (_selectedDate == null || _myReservations.isEmpty) return <String>{};

    final date = _selectedDate!;
    final selectedLoc =
        (_selectedLocation?.name ?? _locationController.text).trim().toLowerCase();
    final durationMinutes = _durationInMinutes();

    bool sameDay(DateTime dt) =>
        dt.year == date.year && dt.month == date.month && dt.day == date.day;

    bool locationMatch(Reservation r) {
      if (selectedLoc.isEmpty) return true;
      final loc = r.location.toLowerCase();
      return loc.contains(selectedLoc) || selectedLoc.contains(loc);
    }

    final disabled = <String>{};
    for (final slot in _timeSlots) {
      final tod = _timeOf(slot);
      final slotStart = DateTime(date.year, date.month, date.day, tod.hour, tod.minute);
      final slotEnd = slotStart.add(Duration(minutes: durationMinutes));

      final conflict = _myReservations.any((r) {
        if (r.isClosed) return false;
        if (!locationMatch(r)) return false;
        final rs = r.startDateTime;
        final re = r.endDateTime ??
            (rs != null ? rs.add(const Duration(hours: 1)) : null);
        if (rs == null || re == null) return false;
        if (!sameDay(rs)) return false;
        return rs.isBefore(slotEnd) && re.isAfter(slotStart);
      });

      if (conflict) disabled.add(slot);
    }

    return disabled;
  }

  String _formatDate(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  TimeOfDay _timeOf(String label) {
    final parts = label.split(':');
    final h = int.tryParse(parts.first) ?? 0;
    final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return TimeOfDay(hour: h, minute: m);
  }

  bool get _hasSelectedLocation => _selectedLocation != null;

  void _showLocationRequired() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Pilih lokasi terlebih dahulu sebelum memilih tanggal atau jam.'),
          backgroundColor: accentDarkColor,
        ),
      );
  }

  Future<void> _submit(CookieRequest request) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('Lengkapi tanggal dan waktu booking.'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      return;
    }

    final titleValue = _classController.text.isNotEmpty
        ? _classController.text
        : (_locationController.text.isNotEmpty
            ? _locationController.text
            : 'Booking');

    final start = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    int durationMinutes;
    durationMinutes = _durationInMinutes();

    final end = start.add(Duration(minutes: durationMinutes));

    final resourceId = _selectedLocation?.placeId.isNotEmpty == true
        ? _selectedLocation!.placeId
        : _locationController.text;

    final resourceLabel =
        _selectedLocation?.name ?? _locationController.text ?? titleValue;

    final payload = {
      'resource_id': resourceId,
      'resource_label': resourceLabel,
      // Kirim dalam UTC agar backend (yang menganggap naive sebagai UTC) tetap benar
      'start_time': start.toUtc().toIso8601String(),
      'end_time': end.toUtc().toIso8601String(),
      'title': titleValue,
      'notes': _notesController.text,
    };

    try {
      final response = await request.postJson(
        '$djangoBaseUrl$bookingCreateEndpoint',
        jsonEncode(payload),
      );

      final success = response is Map &&
          (response['status'] == 'success' ||
              response['success'] == true ||
              response['id'] != null);
      final message = () {
        if (response is Map) {
          if (response['message'] != null) {
            return response['message'].toString();
          }
          if (response['detail'] != null) {
            return response['detail'].toString();
          }
        }
        return success
            ? 'Booking created.'
            : 'Gagal membuat booking, cek konfigurasi endpoint.';
      }();

      if (!mounted) return;

      if (success) {
        _classController.clear();
        _locationController.clear();
        _notesController.clear();
        _dateController.clear();
        _timeController.clear();
        setState(() {
          final now = DateTime.now();
          _selectedDate = DateTime(now.year, now.month, now.day);
          _selectedTime = null;
          _selectedTimeLabel = null;
          _reloadReservations(request);
          _dateController.text = _formatDate(_selectedDate!);
        });
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: success ? accentDarkColor : Colors.red.shade400,
          ),
        );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Booking error: ${e.toString().split(":").last.trim()}',
            ),
            backgroundColor: Colors.red.shade400,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [gradientStartColor, gradientEndColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            const SiteNavBar(active: NavDestination.booking),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 16.0,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: primaryNavColor,
                          ),
                          onPressed: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            } else {
                              Navigator.pushReplacementNamed(context, '/home');
                            }
                          },
                          icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                          label: const Text('Back'),
                        ),
                        const SizedBox(height: 4),
                        const _HeroInfoCard(),
                        const SizedBox(height: 16),
                        Center(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFDFE9F7), Colors.white],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(18.0),
                              border: Border.all(
                                color: const Color(0xFFAEC6E8),
                                width: 1.5,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color.fromARGB(32, 13, 43, 63),
                                  offset: Offset(0, 14),
                                  blurRadius: 32,
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 20,
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'BOOK LOCATION',
                                      style: GoogleFonts.inter(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: primaryNavColor,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: 640,
                                      child: FutureBuilder<void>(
                                        future: _locationsFuture,
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const Padding(
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 8.0),
                                              child: LinearProgressIndicator(
                                                minHeight: 6,
                                                color: primaryNavColor,
                                              ),
                                            );
                                          }
                                          if (snapshot.hasError) {
                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Gagal memuat lokasi. Tap ulang untuk coba lagi.',
                                                  style: GoogleFonts.inter(
                                                    color: Colors.red.shade600,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                ElevatedButton.icon(
                                                  onPressed: () {
                                                    final request =
                                                        context.read<
                                                            CookieRequest>();
                                                    setState(() {
                                                      _locationsFuture =
                                                          _loadLocations(
                                                              request);
                                                    });
                                                  },
                                                  icon: const Icon(Icons.refresh),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        primaryNavColor,
                                                  ),
                                                  label: const Text('Coba lagi'),
                                                ),
                                              ],
                                            );
                                          }

                                          return Row(
                                            children: [
                                              Expanded(
                                                child: LocationSearchField(
                                                  controller: _locationController,
                                                  focusNode: _locationFocusNode,
                                                  locations: _locations,
                                                  onSelected: (loc) {
                                                    setState(() {
                                                      _selectedLocation = loc;
                                                      if (loc == null) {
                                                        _selectedTime = null;
                                                        _selectedTimeLabel = null;
                                                        _timeController.clear();
                                                      }
                                                    });
                                                  },
                                                  comparator: _locationComparator,
                                                  filterTopRated: _filterTopRated,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              SizedBox(
                                                height: 48,
                                                child: OutlinedButton(
                                                  onPressed: _showLocationFilterSheet,
                                                  style: OutlinedButton.styleFrom(
                                                    side: BorderSide(
                                                      color: (_filterTopRated || !_sortByNearest)
                                                          ? primaryNavColor
                                                          : Colors.black87,
                                                    ),
                                                    backgroundColor:
                                                        (_filterTopRated || !_sortByNearest)
                                                            ? primaryNavColor.withOpacity(0.06)
                                                            : Colors.white,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.filter_list,
                                                        size: 20,
                                                        color: (_filterTopRated || !_sortByNearest)
                                                            ? primaryNavColor
                                                            : inputTextColor,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        'Filter',
                                                        style: GoogleFonts.inter(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w700,
                                                          color: inputTextColor,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        final isWide = constraints.maxWidth > 720;
                                        final hasLocation = _hasSelectedLocation;
                                        final disabledSlots =
                                            _disabledSlotsForSelected();
                                        final calendar = _CalendarCard(
                                          enabled: hasLocation,
                                          onRequireLocation:
                                              _showLocationRequired,
                                          selectedDate:
                                              _selectedDate ?? DateTime.now(),
                                          onChanged: (date) {
                                            setState(() {
                                              _selectedDate = date;
                                              _dateController.text =
                                                  _formatDate(date);
                                              _selectedTimeLabel = null;
                                              _selectedTime = null;
                                              _timeController.clear();
                                            });
                                          },
                                        );
                                        final timePanel = _TimeSlotCard(
                                          durations: _durations,
                                          enabled: hasLocation,
                                          onRequireLocation:
                                              _showLocationRequired,
                                          selectedDuration: _selectedDuration,
                                          onDurationChanged: (val) {
                                            setState(() => _selectedDuration = val);
                                          },
                                          timeSlots: _timeSlots,
                                          selectedLabel: _selectedTimeLabel,
                                          selectedDate: _selectedDate,
                                          disabledSlots: disabledSlots,
                                          onTimeSelected: (label) {
                                            setState(() {
                                              _selectedTimeLabel = label;
                                              _selectedTime = _timeOf(label);
                                              _timeController.text = label;
                                            });
                                          },
                                        );

                                        if (isWide) {
                                          return Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(child: calendar),
                                              const SizedBox(width: 12),
                                              Expanded(child: timePanel),
                                            ],
                                          );
                                        }
                                        return Column(
                                          children: [
                                            calendar,
                                            const SizedBox(height: 12),
                                            timePanel,
                                          ],
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 18),
                                    SizedBox(
                                      width: 640,
                                      child: TextFormField(
                                        controller: _notesController,
                                        decoration: const InputDecoration(
                                          labelText: 'Catatan (opsional)',
                                          hintText: 'Preferensi pelatih atau lainnya',
                                        ),
                                        maxLines: 2,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    SizedBox(
                                      width: 220,
                                      child: ElevatedButton(
                                        onPressed: () => _submit(request),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryNavColor,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                          textStyle: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          elevation: 6,
                                        ),
                                        child: const Text('Confirm Booking'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _ReservationsSection(future: _reservationsFuture),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroInfoCard extends StatelessWidget {
  const _HeroInfoCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(30, 0, 0, 0),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              bottomLeft: Radius.circular(14),
            ),
            child: SizedBox(
              height: 78,
              width: 110,
              child: Image.asset(
                'assets/gym_image.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking & Reservation',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: primaryNavColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pilih lokasi, tanggal, dan waktu yang tersedia.',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: inkWeakColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  final bool enabled;
  final VoidCallback onRequireLocation;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onChanged;

  const _CalendarCard({
    required this.enabled,
    required this.onRequireLocation,
    required this.selectedDate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorderColor, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(25, 12, 36, 64),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
    );

    final content = Theme(
      data: theme.copyWith(
        useMaterial3: true,
        colorScheme: theme.colorScheme.copyWith(
          primary: primaryNavDarkerColor,
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: inputTextColor,
        ),
        datePickerTheme: DatePickerThemeData(
          dayShape: MaterialStateProperty.all(const CircleBorder()),
          dayBackgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return primaryNavDarkerColor;
            }
            if (states.contains(MaterialState.hovered)) {
              return primaryNavColor.withOpacity(0.1);
            }
            return Colors.transparent;
          }),
          dayForegroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.white;
            }
            return inputTextColor;
          }),
          dayOverlayColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.pressed)) {
              return primaryNavColor.withOpacity(0.2);
            }
            if (states.contains(MaterialState.hovered)) {
              return primaryNavColor.withOpacity(0.12);
            }
            return null;
          }),
          todayBorder: BorderSide(
            color: primaryNavColor.withOpacity(0.2),
          ),
          todayForegroundColor: MaterialStateProperty.all(primaryNavColor),
        ),
      ),
      child: CalendarDatePicker(
        firstDate: DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        ),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        initialDate: selectedDate,
        onDateChanged: onChanged,
      ),
    );

    final cardWithPicker = DecoratedBox(
      decoration: card.decoration,
      child: content,
    );

    if (enabled) return cardWithPicker;

    return Stack(
      children: [
        Opacity(
          opacity: 0.5,
          child: AbsorbPointer(
            absorbing: true,
            child: cardWithPicker,
          ),
        ),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onRequireLocation,
            ),
          ),
        ),
      ],
    );
  }
}

class _TimeSlotCard extends StatelessWidget {
  final List<String> durations;
  final bool enabled;
  final VoidCallback onRequireLocation;
  final String selectedDuration;
  final ValueChanged<String> onDurationChanged;
  final List<String> timeSlots;
  final String? selectedLabel;
  final DateTime? selectedDate;
  final ValueChanged<String> onTimeSelected;
  final Set<String> disabledSlots;

  const _TimeSlotCard({
    required this.durations,
    required this.enabled,
    required this.onRequireLocation,
    required this.selectedDuration,
    required this.onDurationChanged,
    required this.timeSlots,
    required this.selectedLabel,
    required this.selectedDate,
    required this.onTimeSelected,
    required this.disabledSlots,
  });

  @override
  Widget build(BuildContext context) {
    final panel = DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorderColor, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(25, 12, 36, 64),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: selectedDuration,
              decoration: const InputDecoration(
                labelText: 'Durasi',
              ),
              items: durations
                  .map(
                    (d) => DropdownMenuItem<String>(
                      value: d,
                      child: Text(d),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) onDurationChanged(val);
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Waktu tersedia',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: inputTextColor,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final slot in timeSlots)
                  _TimeSlotChip(
                    label: slot,
                    selected: enabled && selectedLabel == slot,
                    disabled: !enabled ||
                        _isPastSlot(slot) ||
                        disabledSlots.contains(slot),
                    onTap: () {
                      if (!enabled) {
                        onRequireLocation();
                        return;
                      }
                      onTimeSelected(slot);
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );

    if (enabled) return panel;

    return Stack(
      children: [
        Opacity(
          opacity: 0.55,
          child: AbsorbPointer(
            absorbing: true,
            child: panel,
          ),
        ),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onRequireLocation,
            ),
          ),
        ),
      ],
    );
  }

  bool _isPastSlot(String label) {
    if (selectedDate == null) return false;
    final now = DateTime.now();
    final isToday = selectedDate!.year == now.year &&
        selectedDate!.month == now.month &&
        selectedDate!.day == now.day;
    if (!isToday) return false;

    final slotTime = _timeOf(label);
    final nowTod = TimeOfDay.fromDateTime(now);
    if (slotTime.hour < nowTod.hour) return true;
    if (slotTime.hour == nowTod.hour && slotTime.minute <= nowTod.minute) {
      return true;
    }
    return false;
  }

  TimeOfDay _timeOf(String label) {
    final parts = label.split(':');
    final h = int.tryParse(parts.first) ?? 0;
    final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return TimeOfDay(hour: h, minute: m);
  }
}

class _TimeSlotChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  const _TimeSlotChip({
    required this.label,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSelected = selected && !disabled;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Opacity(
        opacity: disabled ? 0.45 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: effectiveSelected ? primaryNavColor : const Color(0xFFF5F7FB),
            border: Border.all(
              color: effectiveSelected ? primaryNavColor : cardBorderColor,
              width: 1.2,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: effectiveSelected
                ? [
                    BoxShadow(
                      color: primaryNavColor.withOpacity(0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              color: effectiveSelected ? Colors.white : inputTextColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReservationsSection extends StatelessWidget {
  final Future<List<Reservation>> future;

  const _ReservationsSection({required this.future});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: cardBorderColor),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(32, 13, 43, 63),
            offset: Offset(0, 12),
            blurRadius: 28,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upcoming Bookings',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: primaryNavColor,
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<Reservation>>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: CircularProgressIndicator.adaptive(),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      'Gagal memuat data. Pastikan endpoint di Django sudah aktif.\n${snapshot.error}',
                      style: GoogleFonts.inter(
                        color: Colors.red.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }

                final allReservations = snapshot.data ?? [];
                final reservations = allReservations
                    .where((r) => r.isOngoing)
                    .toList();
                if (reservations.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.event_busy,
                          color: inkWeakColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Belum ada booking aktif. Yuk mulai reservasi pertama kamu!',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: inkWeakColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reservations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final r = reservations[index];
                    return _ReservationCard(reservation: r);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final Reservation reservation;

  const _ReservationCard({required this.reservation});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'confirmed':
      case 'success':
        return Colors.green.shade500;
      case 'rejected':
      case 'cancelled':
        return Colors.red.shade400;
      default:
        return Colors.orange.shade500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(reservation.status);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    reservation.title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: inputTextColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.7)),
                  ),
                  child: Text(
                    reservation.status,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.place, size: 16, color: inkWeakColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reservation.location,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: inkWeakColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: inkWeakColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reservation.scheduleDisplay,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: inkWeakColor,
                    ),
                  ),
                ),
              ],
            ),
            if (reservation.notes != null && reservation.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes, size: 16, color: inkWeakColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reservation.notes!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: inkWeakColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class LocationSearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final List<FitnessSpot> locations;
  final ValueChanged<FitnessSpot?>? onSelected;
  final int Function(FitnessSpot, FitnessSpot) comparator;
  final bool filterTopRated;
  final double minRating;

  const LocationSearchField({
    super.key,
    required this.controller,
    this.focusNode,
    required this.locations,
    required this.onSelected,
    required this.comparator,
    this.filterTopRated = false,
    this.minRating = 4.5,
  });

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<FitnessSpot>(
      textEditingController: controller,
      focusNode: focusNode,
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        var filtered = query.isEmpty
            ? List<FitnessSpot>.from(locations)
            : locations
                .where(
                  (loc) =>
                      loc.name.toLowerCase().contains(query) ||
                      (loc.address?.toLowerCase().contains(query) ?? false) ||
                      (loc.description?.toLowerCase().contains(query) ??
                          false),
                )
                .toList();
        filtered.sort(comparator);
        return filtered;
      },
      displayStringForOption: (opt) => opt.name,
      onSelected: (loc) {
        controller.text = loc.name;
        onSelected?.call(loc);
      },
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: 'Cari lokasi...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black87, width: 1.1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryNavColor, width: 1.3),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Lokasi wajib diisi';
            }
            return null;
          },
          onChanged: (val) => onSelected?.call(null),
          onFieldSubmitted: (val) => onFieldSubmitted(),
        );
      },
      optionsViewBuilder: (context, onSelectedOption, options) {
        final theme = Theme.of(context);
        final opts = options.toList();
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 280,
                maxWidth: 640,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: opts.length,
                separatorBuilder: (_, __) =>
                    Container(height: 1, color: cardBorderColor.withOpacity(0.4)),
                itemBuilder: (context, index) {
                  final loc = opts[index];
                  final distance = _distanceText(loc.distanceKm);
                  final rating = loc.rating;
                  return InkWell(
                    onTap: () => onSelectedOption(loc),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        loc.name,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: inputTextColor,
                                        ),
                                      ),
                                    ),
                                    if (distance != null) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        distance,
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color:
                                              inkWeakColor.withOpacity(0.7),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (loc.address != null &&
                                    loc.address!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2.0),
                                    child: Text(
                                      loc.address!,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: inkWeakColor,
                                      ),
                                    ),
                                  ),
                                if (rating != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          size: 14,
                                          color: Colors.amber,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          rating.toStringAsFixed(1),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: inputTextColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  String? _distanceText(double? km) {
    if (km == null) return null;
    if (km >= 10) return '${km.toStringAsFixed(0)} km';
    return '${km.toStringAsFixed(1)} km';
  }
}
