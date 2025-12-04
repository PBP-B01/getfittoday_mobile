import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:getfittoday_mobile/constants.dart';
import 'package:getfittoday_mobile/models/reservation.dart';
import 'package:getfittoday_mobile/services/reservation_service.dart';
import 'package:getfittoday_mobile/widgets/site_navbar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  final _reservationService = ReservationService();
  late Future<List<Reservation>> _future;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final request = context.read<CookieRequest>();
      _future = _reservationService.fetchMine(request);
      _initialized = true;
    }
  }

  Future<void> _refresh() async {
    final request = context.read<CookieRequest>();
    setState(() {
      _future = _reservationService.fetchMine(request);
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
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
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: FutureBuilder<List<Reservation>>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(
                            child: CircularProgressIndicator.adaptive(),
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Gagal memuat booking. Pastikan sudah login dan endpoint Django aktif.',
                                style: GoogleFonts.inter(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: _refresh,
                                icon: const Icon(Icons.refresh),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryNavColor,
                                  foregroundColor: Colors.white,
                                ),
                                label: const Text('Coba lagi'),
                              ),
                            ],
                          ),
                        );
                      }

                      final reservations = snapshot.data ?? [];
                      if (reservations.isEmpty) {
                        return RefreshIndicator(
                          onRefresh: _refresh,
                          child: ListView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 18,
                            ),
                            children: [
                              _Header(),
                              const SizedBox(height: 12),
                              _EmptyState(onRefresh: _refresh),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 18,
                          ),
                          itemBuilder: (context, index) {
                            if (index == 0) return _Header();
                            final reservation = reservations[index - 1];
                            return _BookingCard(
                              reservation: reservation,
                              onChanged: _refresh,
                            );
                          },
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemCount: reservations.length + 1,
                        ),
                      );
                    },
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

class _Header extends StatelessWidget {
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Bookings',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: primaryNavColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Semua booking kamu ditampilkan dengan prioritas ongoing di bagian atas, diurutkan berdasarkan jam.',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: inkWeakColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.event_busy, color: inkWeakColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Belum ada booking. Yuk buat reservasi pertama kamu!',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: inkWeakColor,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/booking');
              },
              icon: const Icon(Icons.add),
              label: const Text('Booking sekarang'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Reservation reservation;
  final Future<void> Function() onChanged;

  const _BookingCard({
    required this.reservation,
    required this.onChanged,
  });

  Color _statusColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('approve') || normalized.contains('confirm')) {
      return Colors.green.shade500;
    }
    if (normalized.contains('reject') || normalized.contains('cancel')) {
      return Colors.red.shade400;
    }
    if (normalized.contains('closed') || normalized.contains('done')) {
      return Colors.grey.shade600;
    }
    return Colors.orange.shade600;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(reservation.status);
    final isOngoing = reservation.isOngoing;
    final canCancel = reservation.canCancel;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorderColor),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(20, 12, 36, 64),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
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
                if (isOngoing) const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.7)),
                  ),
                  child: Text(
                    reservation.status,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
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
            const SizedBox(height: 6),
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
            if (canCancel) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red.shade600,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: Colors.red.shade200),
                      ),
                    ),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Cancel booking?'),
                              content: const Text(
                                'Are you sure you want to cancel this booking?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('No'),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Yes, cancel'),
                                ),
                              ],
                            ),
                          ) ??
                          false;

                      if (!confirmed) return;

                      final request = context.read<CookieRequest>();
                      try {
                        final response = await request.postJson(
                          '$djangoBaseUrl/booking/cancel/${reservation.id}/',
                          jsonEncode(<String, dynamic>{}),
                        );

                        if (response is Map &&
                            response['status'] != null &&
                            response['status']
                                .toString()
                                .toLowerCase()
                                .contains('cancel')) {
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: const Text('Booking cancelled.'),
                                backgroundColor: Colors.red.shade600,
                              ),
                            );
                          await onChanged();
                        } else {
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Gagal membatalkan booking.',
                                ),
                                backgroundColor: Colors.red.shade400,
                              ),
                            );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error cancelling booking: ${e.toString()}',
                              ),
                              backgroundColor: Colors.red.shade400,
                            ),
                          );
                      }
                    },
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text(
                      'Cancel booking',
                      style: TextStyle(fontWeight: FontWeight.w700),
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
