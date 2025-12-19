import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  // Callback untuk aksi Join dan Leave yang akan ditangani oleh parent page
  final VoidCallback? onJoinTap;
  final VoidCallback? onLeaveTap;
  final VoidCallback? onEditTap;

  const EventCard({
    super.key,
    required this.event,
    this.onJoinTap,
    this.onLeaveTap,
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    // --- FORMAT TANGGAL (Sama seperti sebelumnya) ---
    String formattedDate = event['date'] ?? '-';
    try {
      String rawDate = event['date'] ?? '';
      if (rawDate.isNotEmpty && !rawDate.endsWith('Z')) rawDate += 'Z';
      DateTime dateObj = DateTime.parse(rawDate).toLocal();
      formattedDate = DateFormat('EEEE, d MMM yyyy, HH:mm', 'id_ID').format(dateObj);
    } catch (e) {
      print("Error parsing date: $e");
    }
    // --------------------------------------------------

    // AMBIL STATUS DARI BACKEND
    bool canEdit = event['can_edit'] ?? false;
    // Pastikan backend mengirim field 'is_joined' (boolean)
    bool isJoined = event['is_joined'] ?? false;
    // Logic status event (sementara)
    bool isFinished = event['is_active'] == false;
    String eventName = event['name'] ?? "Tanpa Nama";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER (Judul & Status) ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  eventName,
                  style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0D47A1)),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isFinished ? Colors.grey.shade200 : const Color(0xFFE8F5E9), // Hijau muda kalau terbuka
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isFinished ? "Pendaftaran Ditutup" : "Pendaftaran Dibuka",
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isFinished ? Colors.grey.shade700 : Colors.green.shade700,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // --- DESKRIPSI ---
          Text(
            event['description'] ?? "-",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 14),
          ),
          const Divider(height: 24),

          // --- DETAIL INFO ---
          _iconText(Icons.calendar_today_rounded, formattedDate, Colors.blue.shade700),
          const SizedBox(height: 8),
          _iconText(Icons.location_on_rounded, event['location'] ?? '-', Colors.red.shade700),
          const SizedBox(height: 8),
          _iconText(Icons.apartment_rounded, event['community_name'] ?? 'Unknown', Colors.green.shade700),
          const SizedBox(height: 8),
          _iconText(Icons.people_alt_rounded, "${event['participant_count'] ?? 0} peserta terdaftar", Colors.purple.shade700),

          const SizedBox(height: 20),

          // --- AREA TOMBOL AKSI (BAGIAN YANG DIUBAH) ---
          Row(
            children: [
              // 1. TOMBOL EDIT (Hanya muncul jika Admin)
              if (canEdit) ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: onEditTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107), // Kuning
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text("Edit", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
                const SizedBox(width: 12), // Jarak antar tombol
              ],

// 2. TOMBOL JOIN / LEAVE (Muncul untuk semua user)
              Expanded(
                // Jika Admin, dia berbagi ruang. Jika User biasa, dia memenuhi Row.
                flex: canEdit ? 1 : 2,
                child: isJoined
                // A. KONDISI SUDAH JOIN -> Tombol "Leave Event" (Oranye)
                // (User tetap bisa leave meskipun event sudah lewat, logis kan?)
                    ? ElevatedButton(
                  onPressed: () {
                    _showLeaveConfirmationDialog(context, eventName);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text("Leave Event", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
                )
                    :
                // B. KONDISI BELUM JOIN
                // Cek dulu: Apakah event sudah selesai/lewat?
                isFinished
                // B1. Event Lewat -> Tombol Mati (Abu-abu)
                    ? ElevatedButton(
                  onPressed: null, // DISABLED
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                      "Join Event",
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.grey.shade600)
                  ),
                )
                // B2. Event Masih Buka -> Tombol Join (Hijau)
                    : ElevatedButton(
                  onPressed: onJoinTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853), // Hijau segar
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text("Join Event", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPER UNTUK ICON & TEKS ---
  Widget _iconText(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500))),
      ],
    );
  }

  // --- FUNGSI MENAMPILKAN MODAL KONFIRMASI LEAVE ---
  Future<void> _showLeaveConfirmationDialog(BuildContext context, String eventName) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User harus memilih tombol
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 5,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Tinggi menyesuaikan konten
              children: [
                // Icon Peringatan
                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 50),
                const SizedBox(height: 16),
                // Judul
                Text(
                  "Konfirmasi Keluar",
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF0D47A1)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // Isi Pesan
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: GoogleFonts.inter(fontSize: 15, color: Colors.grey.shade700, height: 1.4),
                    children: [
                      const TextSpan(text: "Yakin ingin keluar dari event "),
                      TextSpan(
                        text: '"$eventName"',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.black87),
                      ),
                      const TextSpan(text: "?"),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                // Tombol Aksi
                Row(
                  children: [
                    // Tombol Batal (Abu-abu)
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(), // Tutup Dialog
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey.shade700,
                            side: BorderSide(color: Colors.grey.shade400, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text("Batal", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Tombol Keluar (Merah - Sesuai Request)
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // 1. Tutup Dialog dulu
                            if (onLeaveTap != null) {
                              onLeaveTap!(); // 2. Jalankan aksi Leave ke Backend
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD32F2F), // Merah
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text("Keluar", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}