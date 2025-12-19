import 'dart:convert'; // Tambahan untuk jsonEncode
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/community_service.dart';

class CreateEventForm extends StatefulWidget {
  final int initialCommunityId;
  final VoidCallback onSuccess;

  const CreateEventForm({
    super.key,
    required this.initialCommunityId,
    required this.onSuccess,
  });

  @override
  State<CreateEventForm> createState() => _CreateEventFormState();
}

class _CreateEventFormState extends State<CreateEventForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  // State
  int? _selectedCommunityId;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  List<Map<String, dynamic>> _adminCommunities = [];
  bool _isLoading = false;
  bool _isFetching = true;
  String? _fetchError;

  // Pastikan URL ini sama dengan Backend kamu
  final String baseUrl = "http://localhost:8000";

  @override
  void initState() {
    super.initState();
    _selectedCommunityId = widget.initialCommunityId;
    _fetchCommunities();
  }

  Future<void> _fetchCommunities() async {
    final request = context.read<CookieRequest>();
    try {
      // Kita pakai fungsi service yang sudah ada
      final data = await fetchAdminCommunities(request);

      if (mounted) {
        setState(() {
          _adminCommunities = data;

          if (data.isEmpty) {
            _fetchError = "Anda belum menjadi admin di komunitas manapun.";
            _selectedCommunityId = null;
          } else {
            _fetchError = null;
            // Cek apakah ID awal masih valid di list yang baru diambil
            bool exists = data.any((c) => c['id'] == _selectedCommunityId);
            if (!exists) {
              _selectedCommunityId = data.first['id']; // Default pilih yang pertama
            }
          }
          _isFetching = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() {
        _isFetching = false;
        _fetchError = "Gagal mengambil data komunitas.";
      });
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime(2030)
    );
    if (date == null) return;
    if (!mounted) return;

    final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now()
    );
    if (time == null) return;

    setState(() {
      _selectedDate = date;
      _selectedTime = time;
      final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      // Tampilan di Textfield (User Friendly)
      _dateController.text = DateFormat('dd MMM yyyy, HH:mm').format(dt);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedCommunityId == null) return;

    setState(() => _isLoading = true);
    final request = context.read<CookieRequest>();

    // 1. Gabungkan Date dan Time
    final dateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute
    );

    // 2. Format Tanggal untuk Django (PENTING: Sesuaikan dengan strptime di views.py)
    // Format: "YYYY-MM-DD HH:MM:SS"
    final formattedDate = DateFormat("yyyy-MM-dd HH:mm:ss").format(dateTime);

    try {
      // 3. Kirim Data Langsung (Biar aman format JSON-nya)
      final response = await request.postJson(
        "$baseUrl/event/api/create/",
        jsonEncode({
          "name": _nameController.text,
          "description": _descController.text,
          "location": _locationController.text,
          "date": formattedDate,
          "community_id": _selectedCommunityId, // Sesuaikan key ini dengan backend
        }),
      );

      if (mounted) {
        if (response['status'] == 'success') {
          Navigator.pop(context);
          widget.onSuccess();
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Event berhasil dibuat!"), backgroundColor: Colors.green)
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response['message'] ?? "Gagal menyimpan event"))
          );
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Styling Input
    final inputBorder = OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.blue.withOpacity(0.2)));
    final inputDecoration = (String hint, {IconData? icon}) => InputDecoration(
        hintText: hint, prefixIcon: icon != null ? Icon(icon, size: 20, color: Colors.grey) : null, filled: true, fillColor: const Color(0xFFF8F9FA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), border: inputBorder, enabledBorder: inputBorder, focusedBorder: inputBorder.copyWith(borderSide: const BorderSide(color: Color(0xFF005960), width: 1.5))
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Buat Event", style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF0D47A1))),
                const SizedBox(height: 24),

                _label("Nama Event"),
                TextFormField(controller: _nameController, decoration: inputDecoration("Nama event"), validator: (v) => v!.isEmpty ? "Wajib diisi" : null),
                const SizedBox(height: 16),

                _label("Komunitas"),
                // Logic Dropdown: Loading -> Kosong -> Ada Isi
                _isFetching
                    ? const Center(child: LinearProgressIndicator())
                    : _adminCommunities.isEmpty
                    ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                  child: Text(_fetchError ?? "Anda bukan Admin di komunitas manapun.", style: GoogleFonts.inter(color: Colors.red.shade800, fontSize: 13)),
                )
                    : DropdownButtonFormField<int>(
                  value: _selectedCommunityId,
                  decoration: inputDecoration("Pilih Komunitas"),
                  isExpanded: true,
                  items: _adminCommunities.map((c) => DropdownMenuItem(value: c['id'] as int, child: Text(c['name'], overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (val) => setState(() => _selectedCommunityId = val),
                  validator: (v) => v == null ? "Pilih komunitas" : null,
                ),
                const SizedBox(height: 16),

                _label("Tanggal & Waktu"),
                TextFormField(controller: _dateController, readOnly: true, onTap: _pickDateTime, decoration: inputDecoration("Pilih waktu...", icon: Icons.calendar_today_rounded), validator: (v) => v!.isEmpty ? "Wajib diisi" : null),
                const SizedBox(height: 16),

                _label("Lokasi Event"),
                TextFormField(controller: _locationController, decoration: inputDecoration("Lokasi Event"), validator: (v) => v!.isEmpty ? "Wajib diisi" : null),
                const SizedBox(height: 16),

                _label("Deskripsi"),
                TextFormField(controller: _descController, maxLines: 3, decoration: inputDecoration("Deskripsi"), validator: (v) => v!.isEmpty ? "Wajib diisi" : null),
                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: Text("Batal", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.grey))),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      // Matikan tombol jika user tidak punya akses komunitas
                      onPressed: (_isLoading || _adminCommunities.isEmpty) ? null : _submit,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC107), foregroundColor: Colors.black),
                      child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text("Simpan", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0D47A1))));
}