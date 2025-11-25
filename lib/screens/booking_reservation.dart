import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:getfittoday_mobile/constants.dart';
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
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  late Future<List<Reservation>> _reservationsFuture;
  bool _futureInitialized = false;

  @override
  void dispose() {
    _classController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_futureInitialized) {
      final request = context.read<CookieRequest>();
      _reservationsFuture = _fetchReservations(request);
      _futureInitialized = true;
    }
  }

  Future<List<Reservation>> _fetchReservations(CookieRequest request) async {
    final raw =
        await request.get('$djangoBaseUrl$bookingListEndpoint') as dynamic;

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

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = _formatTime(picked);
      });
    }
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

    final payload = {
      'title': _classController.text,
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

      final success =
          (response is Map && (response['status'] == 'success' || response['success'] == true));
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
          _selectedDate = null;
          _selectedTime = null;
          _reservationsFuture = _fetchReservations(request);
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 22.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Booking Reservation',
                          style: GoogleFonts.inter(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Terhubung langsung ke Django app booking-reservation kamu. Sesuaikan endpoint di constants.dart jika perlu.',
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                            color: inkWeakColor,
                          ),
                        ),
                        const SizedBox(height: 22),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 900;
                            final children = [
                              Expanded(
                                flex: 1,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16.0),
                                    border: Border.all(color: cardBorderColor),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color.fromARGB(36, 13, 43, 63),
                                        offset: Offset(0, 12),
                                        blurRadius: 28,
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Form(
                                      key: _formKey,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Buat Booking Baru',
                                            style: GoogleFonts.inter(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: primaryNavColor,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          TextFormField(
                                            controller: _classController,
                                            decoration: const InputDecoration(
                                              labelText: 'Nama kelas / aktivitas',
                                              hintText: 'Contoh: HIIT di Margocity',
                                            ),
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Nama kelas wajib diisi';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 12),
                                          TextFormField(
                                            controller: _locationController,
                                            decoration: const InputDecoration(
                                              labelText: 'Lokasi',
                                              hintText: 'Studio atau kota',
                                            ),
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Lokasi wajib diisi';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 12),
                                          GestureDetector(
                                            onTap: _selectDate,
                                            child: AbsorbPointer(
                                              child: TextFormField(
                                                decoration: const InputDecoration(
                                                  labelText: 'Tanggal',
                                                  hintText: 'Pilih tanggal',
                                                ),
                                                controller: _dateController,
                                                validator: (_) {
                                                  if (_selectedDate == null) {
                                                    return 'Tanggal wajib diisi';
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          GestureDetector(
                                            onTap: _selectTime,
                                            child: AbsorbPointer(
                                              child: TextFormField(
                                                decoration: const InputDecoration(
                                                  labelText: 'Waktu',
                                                  hintText: 'Pilih waktu',
                                                ),
                                                controller: _timeController,
                                                validator: (_) {
                                                  if (_selectedTime == null) {
                                                    return 'Waktu wajib diisi';
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          TextFormField(
                                            controller: _notesController,
                                            decoration: const InputDecoration(
                                              labelText: 'Catatan (opsional)',
                                              hintText: 'Preferensi pelatih atau lainnya',
                                            ),
                                            maxLines: 3,
                                          ),
                                          const SizedBox(height: 18),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton.icon(
                                              onPressed: () => _submit(request),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: accentColor,
                                                foregroundColor: inputTextColor,
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 14,
                                                ),
                                                textStyle: const TextStyle(
                                                  fontSize: 15.5,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                shadowColor:
                                                    accentDarkColor.withOpacity(0.3),
                                                elevation: 8,
                                              ),
                                              icon: const Icon(Icons.add_circle),
                                              label: const Text('Submit Booking'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: isWide ? 16 : 0, height: isWide ? 0 : 16),
                              Expanded(
                                flex: 1,
                                child: DecoratedBox(
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
                                          future: _reservationsFuture,
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return const Padding(
                                                padding: EdgeInsets.all(16.0),
                                                child: Center(
                                                  child:
                                                      CircularProgressIndicator.adaptive(),
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
                                              separatorBuilder: (_, __) =>
                                                  const SizedBox(height: 10),
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
                                ),
                              ),
                            ];

                            if (isWide) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: children,
                              );
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: children,
                            );
                          },
                        ),
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
        [date, time].where((e) => e != null && e.isNotEmpty).join(' · ');
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
