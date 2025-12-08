import 'dart:convert';
import 'dart:io'; 
import 'dart:typed_data'; 
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:getfittoday_mobile/constants.dart';
import 'package:google_fonts/google_fonts.dart';

class CommunityFormPage extends StatefulWidget {
  // 👇 INI PERUBAHANNYA: Terima data lama (opsional)
  final Map<String, dynamic>? existingData;

  const CommunityFormPage({super.key, this.existingData});

  @override
  State<CommunityFormPage> createState() => _CommunityFormPageState();
}

class _CommunityFormPageState extends State<CommunityFormPage> {
  final _formKey = GlobalKey<FormState>();

  String _name = "";
  String _shortDescription = "";
  String _description = "";
  String _contactInfo = "";
  String _schedule = ""; 
  String? _selectedFitnessSpotId;
  String? _selectedCategory;

  final List<String> _sportCategories = [
    'Running', 'Futsal', 'Basketball', 'Badminton', 
    'Tennis', 'Cycling', 'Yoga', 'General',
  ];

  File? _imageFile;          
  Uint8List? _imageBytes;    
  String? _imageName;        

  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _fitnessSpots = [];
  bool _isLoadingSpots = true;

  @override
  void initState() {
    super.initState();
    
    // 👇 LOGIKA AUTO-FILL (KALAU EDIT) 👇
    if (widget.existingData != null) {
      final data = widget.existingData!;
      _name = data['name'] ?? "";
      _shortDescription = data['short_description'] ?? "";
      _description = data['description'] ?? "";
      _contactInfo = data['contact_info'] ?? "";
      _schedule = data['schedule'] ?? "";
      
      // Category
      if (_sportCategories.contains(data['category'])) {
        _selectedCategory = data['category'];
      } else {
        _selectedCategory = "General";
      }

      // Location (Fitness Spot)
      // Kita set nanti setelah fetchFitnessSpots selesai biar ID-nya cocok
    }
    // 👆 ---------------------------- 👆

    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchFitnessSpots();
    });
  }

  Future<void> fetchFitnessSpots() async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.get('$djangoBaseUrl/community/api/fitness-spots/');
      setState(() {
        _fitnessSpots = List<Map<String, dynamic>>.from(response);
        _isLoadingSpots = false;

        // 👇 LANJUTAN AUTO-FILL LOKASI 👇
        if (widget.existingData != null) {
          final spotData = widget.existingData!['fitness_spot'];
          if (spotData != null && spotData['place_id'] != null) {
             // Cari apakah ID lokasi lama ada di daftar lokasi yang baru ditarik
             final found = _fitnessSpots.any((s) => s['id'] == spotData['place_id']);
             if (found) {
               _selectedFitnessSpotId = spotData['place_id'];
             }
          }
        }
        // 👆 ------------------------ 👆
      });
    } catch (e) {
      print("Error fetching spots: $e");
      setState(() => _isLoadingSpots = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      var bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageName = pickedFile.name;
        if (!kIsWeb) {
          _imageFile = File(pickedFile.path);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final isEditing = widget.existingData != null; // Cek mode

    ImageProvider? imageProvider;
    if (_imageBytes != null) {
      imageProvider = MemoryImage(_imageBytes!);
    } else if (_imageFile != null) {
      imageProvider = FileImage(_imageFile!);
    } else if (isEditing && widget.existingData!['image'] != null) {
      // Tampilkan gambar lama dari URL jika sedang edit & belum ganti gambar
      imageProvider = NetworkImage("$djangoBaseUrl${widget.existingData!['image']}");
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isEditing ? "Edit Komunitas" : "Buat Komunitas", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: primaryNavColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoadingSpots
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // INPUT GAMBAR
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                          image: imageProvider != null
                              ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                              : null,
                        ),
                        child: imageProvider == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, size: 40, color: Colors.grey.shade400),
                                  const SizedBox(height: 8),
                                  Text("Tap untuk upload foto", style: GoogleFonts.inter(color: Colors.grey)),
                                ],
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // FORM FIELDS (Pake initialValue kalau perlu, tapi kita udah set variable di initState)
                    TextFormField(
                      initialValue: _name, // Auto-fill
                      decoration: _inputDecoration("Nama Komunitas", Icons.group),
                      onChanged: (val) => _name = val,
                      validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: _shortDescription, // Auto-fill
                      decoration: _inputDecoration("Deskripsi Singkat (Tagline)", Icons.short_text, helperText: "Contoh: Komunitas lari santai Jakarta"),
                      onChanged: (val) => _shortDescription = val,
                      validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: _inputDecoration("Kategori Olahraga", Icons.sports),
                      dropdownColor: Colors.white,
                      value: _selectedCategory, // Auto-fill
                      items: _sportCategories.map((item) {
                        return DropdownMenuItem<String>(
                          value: item,
                          child: Text(item, style: GoogleFonts.inter(color: inputTextColor)),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedCategory = val),
                      validator: (val) => val == null ? "Wajib pilih kategori" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: _description, // Auto-fill
                      decoration: _inputDecoration("Deskripsi Lengkap", Icons.description),
                      maxLines: 3,
                      onChanged: (val) => _description = val,
                      validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: _contactInfo, // Auto-fill
                      decoration: _inputDecoration("Kontak (WA/IG)", Icons.contact_phone),
                      onChanged: (val) => _contactInfo = val,
                      validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: _schedule, // Auto-fill
                      decoration: _inputDecoration("Jadwal Latihan", Icons.calendar_today, helperText: "Format: Hari Jam - Nama Kegiatan (Pisahkan dengan Enter)"),
                      maxLines: 3,
                      onChanged: (val) => _schedule = val,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: _inputDecoration("Lokasi Latihan", Icons.location_on),
                      dropdownColor: Colors.white,
                      value: _selectedFitnessSpotId, // Auto-fill
                      items: _fitnessSpots.map((item) {
                        return DropdownMenuItem<String>(
                          value: item['id'],
                          child: Text(
                            item['name'],
                            style: GoogleFonts.inter(color: inputTextColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedFitnessSpotId = val),
                      validator: (val) => val == null ? "Wajib pilih lokasi" : null,
                    ),
                    const SizedBox(height: 32),

                    // TOMBOL SUBMIT PINTAR
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryNavColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            try {
                              // 1. SIAPKAN GAMBAR
                              String? imageBase64;
                              if (kIsWeb) {
                                if (_imageBytes != null) {
                                  imageBase64 = "data:image/jpeg;base64,${base64Encode(_imageBytes!)}";
                                }
                              } else {
                                if (_imageFile != null) {
                                  List<int> imageBytes = await _imageFile!.readAsBytes();
                                  imageBase64 = "data:image/jpeg;base64,${base64Encode(imageBytes)}";
                                }
                              }

                              // 2. TENTUKAN URL (CREATE vs EDIT)
                              String url;
                              if (isEditing) {
                                url = "$djangoBaseUrl/community/api/edit/${widget.existingData!['id']}/";
                              } else {
                                url = "$djangoBaseUrl/community/api/create/";
                              }

                              // 3. KIRIM REQUEST JSON
                              final response = await request.post(
                                url,
                                {
                                  "name": _name,
                                  "short_description": _shortDescription,
                                  "category": _selectedCategory!,
                                  "description": _description,
                                  "contact_info": _contactInfo,
                                  "fitness_spot_id": _selectedFitnessSpotId!,
                                  "schedule": _schedule,
                                  "image": imageBase64 ?? "", // Kalau edit dan gak ganti gambar, kirim string kosong (Django paham)
                                }
                              );

                              if (response['status'] == 'success') {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(isEditing ? "Berhasil update!" : "Berhasil buat!"),
                                    backgroundColor: Colors.green,
                                  ));
                                  Navigator.pop(context); // Kembali ke halaman sebelumnya
                                }
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text("Gagal: ${response['message']}"),
                                    backgroundColor: Colors.red,
                                  ));
                                }
                              }
                            } catch (e) {
                              print("Error submit: $e");
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                            }
                          }
                        },
                        child: Text(
                          isEditing ? "Simpan Perubahan" : "Buat Komunitas", 
                          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, {String? helperText}) {
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      helperMaxLines: 2,
      prefixIcon: Icon(icon, color: Colors.grey),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }
}