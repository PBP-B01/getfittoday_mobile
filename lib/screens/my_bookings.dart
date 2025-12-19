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
                              const _BackButtonRow(),
                              const SizedBox(height: 8),
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
                            if (index == 0) return const _BackButtonRow();
                            if (index == 1) return _Header();
                            final reservation = reservations[index - 2];
                            return _BookingCard(
                              reservation: reservation,
                              onChanged: _refresh,
                              allReservations: reservations,
                            );
                          },
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemCount: reservations.length + 2,
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
              'Daftar semua booking kamu, mulai dari jadwal terdekat.',
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

class _BackButtonRow extends StatelessWidget {
  const _BackButtonRow();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: primaryNavColor,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
  final List<Reservation> allReservations;

  const _BookingCard({
    required this.reservation,
    required this.onChanged,
    required this.allReservations,
  });

  static const List<String> _hourSlots = <String>[
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00',
    '19:00',
    '20:00',
    '21:00',
    '22:00',
  ];

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

  TimeOfDay _timeOf(String label) {
    final parts = label.split(':');
    final h = int.tryParse(parts.first) ?? 0;
    final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return TimeOfDay(hour: h, minute: m);
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(reservation.status);
    final isOngoing = reservation.isOngoing;
    final canCancel = reservation.canCancel;
    final isClosed = reservation.isClosed;
    final start = reservation.startDateTime;
    final end = reservation.endDateTime;
    final Duration? duration =
        (start != null && end != null) ? end.difference(start) : null;

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
            if (canCancel || isClosed) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (canCancel && duration != null)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.blue.shade50,
                        foregroundColor: primaryNavColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: Colors.blue.shade200),
                        ),
                      ),
                      onPressed: () async {
                        final updated = await _showEditDialog(
                          context,
                          initialStart: start!,
                          duration: duration,
                        );
                        if (updated == true) {
                          await onChanged();
                        }
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text(
                        'Edit booking',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  if (canCancel && (duration != null))
                    const SizedBox(width: 8),
                  if (canCancel)
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
                  if (isClosed) ...[
                    if (canCancel) const SizedBox(width: 8),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        foregroundColor: Colors.grey.shade700,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete booking from history?'),
                                content: const Text(
                                  'This will remove the booking from your history. This action cannot be undone.',
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
                                    child: const Text('Yes, delete'),
                                  ),
                                ],
                              ),
                            ) ??
                            false;

                        if (!confirmed) return;

                        final request = context.read<CookieRequest>();
                        try {
                          final response = await request.postJson(
                            '$djangoBaseUrl/booking/delete/${reservation.id}/',
                            jsonEncode(<String, dynamic>{}),
                          );

                          if (response is Map &&
                              response['status'] != null &&
                              response['status']
                                  .toString()
                                  .toLowerCase()
                                  .contains('deleted')) {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Booking removed from history.',
                                  ),
                                  backgroundColor: Colors.green.shade600,
                                ),
                              );
                            await onChanged();
                          } else {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Gagal menghapus booking.',
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
                                  'Error deleting booking: ${e.toString()}',
                                ),
                                backgroundColor: Colors.red.shade400,
                              ),
                            );
                        }
                      },
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text(
                        'Delete history',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<bool?> _showEditDialog(
    BuildContext context, {
    required DateTime initialStart,
    required Duration duration,
  }) async {
    DateTime selectedDate = initialStart;
    TimeOfDay selectedTime =
        TimeOfDay(hour: initialStart.hour, minute: initialStart.minute);

    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final newStart = DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
              selectedTime.hour,
              selectedTime.minute,
            );
            final newEnd = newStart.add(duration);

            String formatDate(DateTime d) =>
                '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
            String formatTime(TimeOfDay t) =>
                '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

            final theme = Theme.of(context);

            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              title: Text(
                'Edit reservation time',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: inputTextColor,
                ),
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reservation.title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: inputTextColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Date',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: inkWeakColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(formatDate(selectedDate)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Time',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: inkWeakColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        final chosen = await showDialog<TimeOfDay>(
                          context: dialogContext,
                          barrierDismissible: true,
                          builder: (context) {
                            final today = DateTime.now();
                            final isToday = selectedDate.year == today.year &&
                                selectedDate.month == today.month &&
                                selectedDate.day == today.day;

                            // Slot yang sudah dipakai (selain booking ini) pada tanggal yang sama.
                            final blocked = allReservations.where((r) {
                              if (r.id == reservation.id) return false;
                              if (r.isClosed) return false;
                              final start = r.startDateTime;
                              if (start == null) return false;
                              final sameDay = start.year == selectedDate.year &&
                                  start.month == selectedDate.month &&
                                  start.day == selectedDate.day;
                              if (!sameDay) return false;
                              return true;
                            }).map((r) {
                              final h = r.startDateTime!.hour;
                              return '${h.toString().padLeft(2, '0')}:00';
                            }).toSet();

                            TimeOfDay tempSelected = selectedTime;

                            return StatefulBuilder(
                              builder: (context, setStateDialog) {
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  contentPadding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                                  actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                  content: ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 420),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Pilih jam',
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 18,
                                            color: inputTextColor,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        Wrap(
                                          spacing: 10,
                                          runSpacing: 10,
                                          children: [
                                            for (final slot in _hourSlots)
                                              Builder(
                                                builder: (context) {
                                                  final isBlocked = blocked.contains(slot);
                                                  final slotTime = _timeOf(slot);
                                                  final isPast = isToday &&
                                                      (slotTime.hour < today.hour ||
                                                          (slotTime.hour == today.hour &&
                                                              slotTime.minute <= today.minute));
                                                  final disabled = isBlocked || isPast;
                                                  final selectedSlot =
                                                      tempSelected.hour == slotTime.hour &&
                                                          tempSelected.minute == slotTime.minute;
                                                  return Opacity(
                                                    opacity: disabled ? 0.35 : 1.0,
                                                    child: ChoiceChip(
                                                      label: Text(
                                                        slot,
                                                        style: GoogleFonts.inter(
                                                          fontWeight: FontWeight.w700,
                                                          color: disabled
                                                              ? Colors.black54
                                                              : selectedSlot
                                                                  ? Colors.white
                                                                  : inputTextColor,
                                                        ),
                                                      ),
                                                      selected: selectedSlot && !disabled,
                                                      selectedColor: primaryNavColor,
                                                      backgroundColor: const Color(0xFFF5F7FB),
                                                      onSelected: disabled
                                                          ? null
                                                          : (_) => setStateDialog(() {
                                                                tempSelected = slotTime;
                                                              }),
                                                    ),
                                                  );
                                                },
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('Batal'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryNavColor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      onPressed: () => Navigator.of(context).pop(tempSelected),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                        if (chosen != null) {
                          setState(() {
                            selectedTime = chosen;
                          });
                        }
                      },
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(formatTime(selectedTime)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'New time: ${formatDate(newStart)} ${formatTime(TimeOfDay(hour: newStart.hour, minute: newStart.minute))}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: inkWeakColor,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: primaryNavColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final startUtc = newStart.toUtc().toIso8601String();
                    final endUtc = newEnd.toUtc().toIso8601String();
                    final request = context.read<CookieRequest>();
                    try {
                      final response = await request.postJson(
                        '$djangoBaseUrl/booking/update/${reservation.id}/',
                        jsonEncode(<String, dynamic>{
                          'start_time': startUtc,
                          'end_time': endUtc,
                        }),
                      );

                      if (response is Map &&
                          (response['id'] != null ||
                              response['status'] != null)) {
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            const SnackBar(
                              content: Text('Booking updated.'),
                              backgroundColor: accentDarkColor,
                            ),
                          );
                        Navigator.of(dialogContext).pop(true);
                      } else {
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            const SnackBar(
                              content: Text('Gagal mengubah booking.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text(
                              'Error updating booking: ${e.toString()}',
                            ),
                            backgroundColor: Colors.red.shade400,
                          ),
                        );
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
