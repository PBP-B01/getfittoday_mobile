import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class EditEventForm extends StatefulWidget {
  final Map<String, dynamic> eventData;
  final VoidCallback onSuccess;

  const EditEventForm({
    super.key,
    required this.eventData,
    required this.onSuccess,
  });

  @override
  State<EditEventForm> createState() => _EditEventFormState();
}

class _EditEventFormState extends State<EditEventForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _descController;
  late TextEditingController _dateController;
  late TextEditingController _communityController;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.eventData['name']);
    _locationController = TextEditingController(text: widget.eventData['location']);
    _descController = TextEditingController(text: widget.eventData['description']);
    _communityController = TextEditingController(text: widget.eventData['community_name'] ?? '-');

    try {
      String rawDate = widget.eventData['date'];
      if (!rawDate.endsWith('Z')) rawDate += 'Z';
      DateTime dt = DateTime.parse(rawDate).toLocal();

      _selectedDate = dt;
      _selectedTime = TimeOfDay.fromDateTime(dt);
      _dateController = TextEditingController(text: DateFormat('dd MMM yyyy, HH:mm').format(dt));
    } catch (e) {
      _dateController = TextEditingController();
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
        context: context,
        initialDate: _selectedDate ?? DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2030)
    );
    if (date == null) return;
    if (!mounted) return;

    final time = await showTimePicker(
        context: context,
        initialTime: _selectedTime ?? TimeOfDay.now()
    );
    if (time == null) return;

    setState(() {
      _selectedDate = date;
      _selectedTime = time;
      final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _dateController.text = DateFormat('dd MMM yyyy, HH:mm').format(dt);
    });
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final request = context.read<CookieRequest>();
    final dt = DateTime(
        _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
        _selectedTime!.hour, _selectedTime!.minute
    );
    final formattedDate = DateFormat("yyyy-MM-dd HH:mm:ss").format(dt);

    try {
      final response = await request.postJson(
        "http://localhost:8000/event/api/edit/${widget.eventData['id']}/",
        jsonEncode({
          "name": _nameController.text,
          "description": _descController.text,
          "location": _locationController.text,
          "date": formattedDate,
        }),
      );

      if (mounted) {
        if (response['status'] == 'success') {
          Navigator.pop(context);
          widget.onSuccess();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Event berhasil diupdate!"), backgroundColor: Colors.green));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'])));
        }
      }
    } catch (e) {
      print("Error Update: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDelete() async {
    bool confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
            title: const Text("Hapus Event?"),
            content: const Text("Tindakan ini tidak bisa dibatalkan."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Hapus", style: TextStyle(color: Colors.red))),
            ]
        )
    ) ?? false;

    if (!confirm) return;

    setState(() => _isLoading = true);
    final request = context.read<CookieRequest>();

    try {
      final response = await request.post(
          "http://localhost:8000/event/api/delete/${widget.eventData['id']}/",
          {}
      );

      if (mounted) {
        if (response['status'] == 'success') {
          Navigator.pop(context);
          widget.onSuccess();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Event berhasil dihapus."), backgroundColor: Colors.red));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'])));
        }
      }
    } catch (e) {
      print("Error Delete: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inputBorder = OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.blue.withOpacity(0.2)));
    final inputDecoration = (String hint, {IconData? icon}) => InputDecoration(
        labelText: hint, prefixIcon: icon != null ? Icon(icon, size: 20, color: Colors.grey) : null, filled: true, fillColor: const Color(0xFFF8F9FA),
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
                Text("Edit Event", style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF0D47A1))),
                const SizedBox(height: 24),

                TextFormField(controller: _nameController, decoration: inputDecoration("Nama Event"), validator: (v) => v!.isEmpty ? "Wajib diisi" : null),
                const SizedBox(height: 16),

                TextFormField(controller: _communityController, readOnly: true, decoration: inputDecoration("Komunitas"), style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),

                TextFormField(controller: _dateController, readOnly: true, onTap: _pickDateTime, decoration: inputDecoration("Tanggal & Waktu", icon: Icons.calendar_today), validator: (v) => v!.isEmpty ? "Wajib diisi" : null),
                const SizedBox(height: 16),

                TextFormField(controller: _locationController, decoration: inputDecoration("Lokasi"), validator: (v) => v!.isEmpty ? "Wajib diisi" : null),
                const SizedBox(height: 16),

                TextFormField(controller: _descController, maxLines: 3, decoration: inputDecoration("Deskripsi"), validator: (v) => v!.isEmpty ? "Wajib diisi" : null),
                const SizedBox(height: 32),

                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: _handleDelete,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        child: const Text("Hapus Event", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),

                      Row(
                        children: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700, backgroundColor: Colors.grey.shade200, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                              child: const Text("Batal", style: TextStyle(fontWeight: FontWeight.bold))
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _handleUpdate,
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC107), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                            child: const Text("Update", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      )
                    ],
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
