import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; // Jangan lupa import ini
import 'package:getfittoday_mobile/constants.dart';
import 'community_list.dart'; 

class CommunityFormPage extends StatefulWidget {
  const CommunityFormPage({super.key});

  @override
  State<CommunityFormPage> createState() => _CommunityFormPageState();
}

class _CommunityFormPageState extends State<CommunityFormPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Variabel untuk menyimpan input user
  String _name = "";
  String _description = "";
  String _contactInfo = "";
  
  // Variabel untuk Dropdown Lokasi
  int? _selectedFitnessSpotId; 
  List<dynamic> _fitnessSpots = []; 

  // Fetch daftar lokasi saat halaman dibuka
  Future<void> fetchFitnessSpots(CookieRequest request) async {
    final response = await request.get('$djangoBaseUrl/community/api/fitness-spots/');
    setState(() {
      _fitnessSpots = response;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchFitnessSpots(context.read<CookieRequest>());
    });
  }

  // Fungsi Helper untuk Style Input biar rapi dan seragam
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: inkWeakColor),
      filled: true,
      fillColor: inputBackgroundColor, // Warna background input sesuai tema
      prefixIcon: Icon(icon, color: primaryNavColor), // Ikon warna hijau tua
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: cardBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: cardBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: primaryNavColor, width: 2.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Buat Komunitas Baru',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryNavColor, // Warna Header Hijau Tua
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      // Kasih background warna putih biar bersih
      backgroundColor: Colors.white,
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Judul Kecil (Opsional)
              Text(
                "Detail Komunitas",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryNavColor,
                ),
              ),
              const SizedBox(height: 20),

              // INPUT NAMA
              TextFormField(
                decoration: _inputDecoration("Nama Komunitas", Icons.groups),
                style: GoogleFonts.inter(color: inputTextColor),
                onChanged: (String? value) {
                  setState(() {
                    _name = value!;
                  });
                },
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return "Nama tidak boleh kosong!";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // INPUT DESKRIPSI
              TextFormField(
                decoration: _inputDecoration("Deskripsi", Icons.description),
                style: GoogleFonts.inter(color: inputTextColor),
                maxLines: 3,
                onChanged: (String? value) {
                  setState(() {
                    _description = value!;
                  });
                },
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return "Deskripsi tidak boleh kosong!";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // DROPDOWN LOKASI
              DropdownButtonFormField<int>(
                decoration: _inputDecoration("Pilih Lokasi Latihan", Icons.location_on),
                dropdownColor: Colors.white,
                value: _selectedFitnessSpotId,
                items: _fitnessSpots.map<DropdownMenuItem<int>>((item) {
                  return DropdownMenuItem<int>(
                    value: item['id'], 
                    child: Text(
                      item['name'],
                      style: GoogleFonts.inter(color: inputTextColor),
                    ), 
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  setState(() {
                    _selectedFitnessSpotId = newValue;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return "Harus pilih lokasi!";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // INPUT KONTAK
              TextFormField(
                decoration: _inputDecoration("Kontak Info (WA/IG)", Icons.contact_phone),
                style: GoogleFonts.inter(color: inputTextColor),
                onChanged: (String? value) {
                  setState(() {
                    _contactInfo = value!;
                  });
                },
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return "Kontak info tidak boleh kosong!";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // TOMBOL SIMPAN
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryNavColor, // Tombol Hijau Tua (Sesuai Home)
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      // Kirim data ke Django
                      final response = await request.postJson(
                        "$djangoBaseUrl/community/api/create/",
                        jsonEncode(<String, dynamic>{
                          'name': _name,
                          'description': _description,
                          'contact_info': _contactInfo,
                          'fitness_spot_id': _selectedFitnessSpotId, 
                        }),
                      );
                      
                      if (context.mounted) {
                        if (response['status'] == 'success') {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text("Komunitas berhasil dibuat!"),
                            backgroundColor: Colors.green,
                          ));
                          // Kembali ke list dan refresh 
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const CommunityListPage()),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(response['message'] ?? "Gagal menyimpan."),
                            backgroundColor: Colors.red,
                          ));
                        }
                      }
                    }
                  },
                  child: Text(
                    "Simpan Komunitas",
                    style: GoogleFonts.inter(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}