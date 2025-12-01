import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:getfittoday_mobile/constants.dart';
import 'package:getfittoday_mobile/models/fitness_spot.dart';
import 'package:getfittoday_mobile/services/fitness_spot_service.dart';
import 'package:getfittoday_mobile/widgets/site_navbar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

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

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedTimeLabel;
  String _selectedDuration = '1 Jam';
  FitnessSpot? _selectedLocation;

  late Future<List<Reservation>> _reservationsFuture;
  late Future<void> _locationsFuture;
  bool _futureInitialized = false;
  List<FitnessSpot> _locations = const [];

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
      _reservationsFuture = _fetchReservations(request);
      _locationsFuture = _loadLocations(request);
      _futureInitialized = true;
    }
  }

  Future<List<Reservation>> _fetchReservations(CookieRequest request) async {
    dynamic raw;
    try {
      raw = await request.get('$djangoBaseUrl$bookingListEndpoint') as dynamic;
    } catch (e) {
      throw FormatException(
        'Response bukan JSON. Pastikan $bookingListEndpoint mengembalikan JSON. Error: $e',
      );
    }

    if (raw is String && raw.trim().startsWith('<')) {
      throw const FormatException(
        'Response HTML terdeteksi (mungkin endpoint salah atau belum login). Pastikan endpoint mengembalikan JSON.',
      );
    }

    List<dynamic> dataList = [];
    if (raw is List) {
      dataList = raw;
    } else if (raw is Map && raw['data'] is List) {
      dataList = raw['data'];
    } else if (raw is Map && raw['results'] is List) {
      dataList = raw['results'];
    }

    return dataList
        .whereType<Map<String, dynamic>>()
        .map((json) => Reservation.fromJson(json))
        .toList();
  }

  Future<void> _loadLocations(CookieRequest request) async {
    final results = await _locationService.fetchFitnessSpots(request);
    results.sort(_locationComparator);
    if (!mounted) return;
    setState(() {
      _locations = results;
    });
  }

  int _locationComparator(FitnessSpot a, FitnessSpot b) {
    final aDist = a.distanceKm;
    final bDist = b.distanceKm;
    if (aDist != null && bDist != null) {
      return aDist.compareTo(bDist);
    }
    if (aDist != null) return -1;
    if (bDist != null) return 1;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
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

    final payload = {
      'title': titleValue,
      'location': _locationController.text,
      'date': _formatDate(_selectedDate!),
      'time': _formatTime(_selectedTime!),
      'notes': _notesController.text,
    };

    try {
      final response = await request.postJson(
        '$djangoBaseUrl$bookingCreateEndpoint',
        jsonEncode(payload),
      );

      final success = (response is Map &&
          (response['status'] == 'success' || response['success'] == true));
      final message = (response is Map && response['message'] != null)
          ? response['message'].toString()
          : success
              ? 'Booking created.'
              : 'Gagal membuat booking, cek konfigurasi endpoint.';

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
          _reservationsFuture = _fetchReservations(request);
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

                                          return LocationSearchField(
                                            controller: _locationController,
                                            focusNode: _locationFocusNode,
                                            locations: _locations,
                                            onSelected: (loc) {
                                              setState(() {
                                                _selectedLocation = loc;
                                              });
                                            },
                                            comparator: _locationComparator,
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        final isWide = constraints.maxWidth > 720;
                                        final calendar = _CalendarCard(
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
                                          selectedDuration: _selectedDuration,
                                          onDurationChanged: (val) {
                                            setState(() => _selectedDuration = val);
                                          },
                                          timeSlots: _timeSlots,
                                          selectedLabel: _selectedTimeLabel,
                                          selectedDate: _selectedDate,
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

class Reservation {
  final int? id;
  final String title;
  final String location;
  final String status;
  final String scheduleDisplay;
  final String? notes;

  Reservation({
    required this.id,
    required this.title,
    required this.location,
    required this.status,
    required this.scheduleDisplay,
    this.notes,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    final date = json['date']?.toString();
    final time = json['time']?.toString();
    final schedule =
        [date, time].where((e) => e != null && e.isNotEmpty).join(' Â· ');
    return Reservation(
      id: json['id'] as int?,
      title: json['title']?.toString() ??
          json['class_name']?.toString() ??
          'Booking',
      location: json['location']?.toString() ?? 'Lokasi belum diisi',
      status: json['status']?.toString().toUpperCase() ?? 'PENDING',
      scheduleDisplay: schedule.isEmpty ? 'Jadwal belum diisi' : schedule,
      notes: json['notes']?.toString(),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onChanged;

  const _CalendarCard({
    required this.selectedDate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
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
      child: Theme(
        data: theme.copyWith(
          useMaterial3: false,
          colorScheme: theme.colorScheme.copyWith(
            primary: primaryNavColor,
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
              color: primaryNavColor.withOpacity(0.1),
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
      ),
    );
  }
}

class _TimeSlotCard extends StatelessWidget {
  final List<String> durations;
  final String selectedDuration;
  final ValueChanged<String> onDurationChanged;
  final List<String> timeSlots;
  final String? selectedLabel;
  final DateTime? selectedDate;
  final ValueChanged<String> onTimeSelected;

  const _TimeSlotCard({
    required this.durations,
    required this.selectedDuration,
    required this.onDurationChanged,
    required this.timeSlots,
    required this.selectedLabel,
    required this.selectedDate,
    required this.onTimeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
                    selected: selectedLabel == slot,
                    disabled: _isPastSlot(slot),
                    onTap: () => onTimeSelected(slot),
                  ),
              ],
            ),
          ],
        ),
      ),
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
              'Reservasi Saya',
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

                final reservations = snapshot.data ?? [];
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
                            'Belum ada booking. Yuk mulai reservasi pertama kamu!',
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

  const LocationSearchField({
    super.key,
    required this.controller,
    this.focusNode,
    required this.locations,
    required this.onSelected,
    required this.comparator,
  });

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<FitnessSpot>(
      textEditingController: controller,
      focusNode: focusNode,
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        final filtered = query.isEmpty
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
                                Text(
                                  loc.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: inputTextColor,
                                  ),
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
                              ],
                            ),
                          ),
                          if (distance != null)
                            Text(
                              distance,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: inkWeakColor,
                                fontWeight: FontWeight.w700,
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
