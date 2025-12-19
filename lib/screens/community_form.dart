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
  final Map<String, dynamic>? existingData;

  const CommunityFormPage({super.key, this.existingData});

  @override
  State<CommunityFormPage> createState() => _CommunityFormPageState();
}

class _CommunityFormPageState extends State<CommunityFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Field Data
  String _name = "";
  String _shortDescription = "";
  String _description = "";
  String _contactInfo = "";
  String _schedule = ""; 
  
  // Data Terpilih
  String? _selectedFitnessSpotId;
  String? _selectedCategory;

  // Controller
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  final List<String> _sportCategories = [
    'Aerobics', 'Aikido', 'American Football', 'Archery', 'Arm Wrestling', 
    'Athletics', 'Badminton', 'Ballet', 'Baseball', 'Basketball', 
    'Beach Volleyball', 'Billiards', 'BMX', 'Bodybuilding', 'Bowling', 
    'Boxing', 'Brazilian Jiu-Jitsu', 'Breakdancing', 'Calisthenics', 
    'Canoeing', 'Capoeira', 'Cardio', 'Cheerleading', 'Chess', 'Climbing', 
    'Cricket', 'CrossFit', 'Cycling', 'Dance', 'Darts', 'Dodgeball', 
    'Dragon Boat', 'E-Sports', 'Equestrian', 'Fencing', 'Figure Skating', 
    'Fishing', 'Floorball', 'Football', 'Frisbee', 'Futsal', 'Golf', 
    'Gym', 'Gymnastics', 'Handball', 'HIIT', 'Hiking', 'Hockey', 
    'Horse Riding', 'Ice Skating', 'Jogging', 'Judo', 'Ju-Jitsu', 'Karate', 
    'Kayaking', 'Kendo', 'Kickboxing', 'Krav Maga', 'Kung Fu', 'Lacrosse', 
    'Marathon', 'Martial Arts', 'Meditation', 'MMA', 'Motocross', 
    'Mountain Biking', 'Muay Thai', 'Netball', 'Obstacle Racing', 'Paddle', 
    'Padel', 'Parkour', 'Pickleball', 'Pilates', 'Ping Pong', 'Pole Dance', 
    'Polo', 'Powerlifting', 'Rafting', 'Rock Climbing', 'Roller Skating', 
    'Rowing', 'Rugby', 'Running', 'Sailing', 'Scuba Diving', 'Sepak Takraw', 
    'Shooting', 'Skateboarding', 'Skating', 'Skiing', 'Slacklining', 
    'Snorkeling', 'Snowboarding', 'Soccer', 'Softball', 'Spinning', 'Squash', 
    'Street Workout', 'Surfing', 'Swimming', 'Table Tennis', 'Taekwondo', 
    'Tai Chi', 'Tennis', 'Track & Field', 'Trail Running', 'Trampoline', 
    'Triathlon', 'TRX', 'Ultimate Frisbee', 'Volleyball', 'Walking', 
    'Water Polo', 'Weightlifting', 'Windsurfing', 'Wrestling', 'Wushu', 
    'Yoga', 'Zumba'
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
    
    // 1. AUTO-FILL
    if (widget.existingData != null) {
      final data = widget.existingData!;
      _name = data['name'] ?? "";
      _shortDescription = data['short_description'] ?? "";
      _description = data['description'] ?? "";
      _contactInfo = data['contact_info'] ?? "";
      _schedule = data['schedule'] ?? "";
      
      if (data['category'] != null) {
        _selectedCategory = data['category'];
        _categoryController.text = _selectedCategory!;
      }
    }

    // 2. FETCH SPOTS
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchFitnessSpots();
    });
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> fetchFitnessSpots() async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.get('$djangoBaseUrl/community/api/fitness-spots/');
      setState(() {
        _fitnessSpots = List<Map<String, dynamic>>.from(response);
        _isLoadingSpots = false;

        // Auto-fill Lokasi
        if (widget.existingData != null) {
          final spotData = widget.existingData!['fitness_spot'];
          if (spotData != null && spotData['place_id'] != null) {
             final foundSpot = _fitnessSpots.firstWhere(
               (s) => s['id'] == spotData['place_id'], 
               orElse: () => {}
             );
             if (foundSpot.isNotEmpty) {
               _selectedFitnessSpotId = spotData['place_id'];
               _locationController.text = foundSpot['name']; 
             }
          }
        }
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
    final isEditing = widget.existingData != null;

    ImageProvider? imageProvider;
    if (_imageBytes != null) {
      imageProvider = MemoryImage(_imageBytes!);
    } else if (_imageFile != null) {
      imageProvider = FileImage(_imageFile!);
    } else if (isEditing && widget.existingData!['image'] != null) {
      imageProvider = NetworkImage("$djangoBaseUrl${widget.existingData!['image']}");
    }

    return Scaffold(
      backgroundColor: Colors.transparent, 
      appBar: AppBar(
        title: Text(isEditing ? "Edit Community" : "Create Community", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: primaryNavColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      // BODY GRADIENT
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF2FF), Color(0xFFBFD6F2)],
          ),
        ),
        child: _isLoadingSpots
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // UPLOAD GAMBAR
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                              image: imageProvider != null ? DecorationImage(image: imageProvider, fit: BoxFit.cover) : null,
                            ),
                            child: imageProvider == null
                                ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, size: 40, color: Colors.grey.shade400), const SizedBox(height: 8), Text("Tap to upload photo", style: GoogleFonts.inter(color: Colors.grey))])
                                : null,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // NAMA
                        TextFormField(
                          initialValue: _name,
                          decoration: _inputDecoration("Community Name", Icons.group),
                          onChanged: (val) => _name = val,
                          validator: (val) => val!.isEmpty ? "Required" : null,
                        ),
                        const SizedBox(height: 16),

                        // TAGLINE
                        TextFormField(
                          initialValue: _shortDescription,
                          decoration: _inputDecoration("Short Description (Tagline)", Icons.short_text, helperText: "Example: Casual Sunday Runners"),
                          onChanged: (val) => _shortDescription = val,
                          validator: (val) => val!.isEmpty ? "Required" : null,
                        ),
                        const SizedBox(height: 16),

                        // SEARCHABLE DROPDOWN KATEGORI 
                        _buildSearchableField<String>(
                          controller: _categoryController,
                          label: "Sport Category",
                          icon: Icons.fitness_center,
                          options: _sportCategories,
                          onSelected: (val) {
                            setState(() {
                              _selectedCategory = val;
                              _categoryController.text = val;
                            });
                          },
                          displayStringForOption: (option) => option,
                        ),
                        
                        const SizedBox(height: 16),

                        // DESKRIPSI
                        TextFormField(
                          initialValue: _description,
                          decoration: _inputDecoration("Full Description", Icons.description),
                          maxLines: 3,
                          onChanged: (val) => _description = val,
                          validator: (val) => val!.isEmpty ? "Required" : null,
                        ),
                        const SizedBox(height: 16),

                        // KONTAK
                        TextFormField(
                          initialValue: _contactInfo,
                          decoration: _inputDecoration("Contact (WA/IG)", Icons.contact_phone),
                          onChanged: (val) => _contactInfo = val,
                          validator: (val) => val!.isEmpty ? "Required" : null,
                        ),
                        const SizedBox(height: 16),

                        // JADWAL 
                        TextFormField(
                          initialValue: _schedule,
                          decoration: _inputDecoration(
                            "Training Schedule", 
                            Icons.calendar_today, 
                            helperText: "Format: Day HH:MM - Activity\nExample: Monday 08:00-09:00 - Cardio (Use Enter for new line)",
                          ),
                          maxLines: 3,
                          onChanged: (val) => _schedule = val,
                          validator: (val) => val!.isEmpty ? "Required" : null,
                        ),
                        const SizedBox(height: 16),

                        // SEARCHABLE DROPDOWN LOKASI 
                        _buildSearchableField<Map<String, dynamic>>(
                          controller: _locationController,
                          label: "Training Location",
                          icon: Icons.location_on,
                          options: _fitnessSpots,
                          onSelected: (val) {
                            setState(() {
                              _selectedFitnessSpotId = val['id'];
                              _locationController.text = val['name'];
                            });
                          },
                          displayStringForOption: (option) => option['name'],
                        ),

                        const SizedBox(height: 32),

                        // TOMBOL SUBMIT
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryNavColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                // Validasi Manual Dropdown
                                if (_selectedCategory == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Category not selected!")));
                                  return;
                                }
                                if (_selectedFitnessSpotId == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Location not selected!")));
                                  return;
                                }

                                try {
                                  String? imageBase64;
                                  if (kIsWeb) {
                                    if (_imageBytes != null) imageBase64 = "data:image/jpeg;base64,${base64Encode(_imageBytes!)}";
                                  } else {
                                    if (_imageFile != null) {
                                      List<int> imageBytes = await _imageFile!.readAsBytes();
                                      imageBase64 = "data:image/jpeg;base64,${base64Encode(imageBytes)}";
                                    }
                                  }

                                  String url;
                                  if (isEditing) {
                                    url = "$djangoBaseUrl/community/api/edit/${widget.existingData!['id']}/";
                                  } else {
                                    url = "$djangoBaseUrl/community/api/create/";
                                  }

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
                                      "image": imageBase64 ?? "", 
                                    }
                                  );

                                  if (response['status'] == 'success') {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEditing ? "Update successful!" : "Creation successful!"), backgroundColor: Colors.green));
                                      Navigator.pop(context); 
                                    }
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: ${response['message']}"), backgroundColor: Colors.red));
                                    }
                                  }
                                } catch (e) {
                                  print("Error submit: $e");
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                                }
                              }
                            },
                            child: Text(isEditing ? "Save Changes" : "Create Community", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  // Widget Searchable Autocomplete
  Widget _buildSearchableField<T extends Object>({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required List<T> options,
    required Function(T) onSelected,
    required String Function(T) displayStringForOption,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Autocomplete<T>(
          displayStringForOption: displayStringForOption,
          
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text == '') {
              return options; 
            }
            return options.where((T option) {
              return displayStringForOption(option)
                  .toLowerCase()
                  .contains(textEditingValue.text.toLowerCase());
            });
          },
          onSelected: onSelected,
          
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                color: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                ),
                child: Container(
                  width: constraints.biggest.width, 
                  constraints: const BoxConstraints(maxHeight: 250), 
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: options.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
                    itemBuilder: (BuildContext context, int index) {
                      final T option = options.elementAt(index);
                      return ListTile(
                        dense: true,
                        title: Text(displayStringForOption(option), style: GoogleFonts.inter(fontSize: 14)),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },

          fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
            if (controller.text.isNotEmpty && textEditingController.text.isEmpty) {
               textEditingController.text = controller.text;
            }
            return TextFormField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: _inputDecoration(label, icon, helperText: "Type to search or select from list").copyWith(
                suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.grey), 
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return "Required";
                final isValid = options.any((op) => displayStringForOption(op) == val);
                if (!isValid) return "Select valid data from the list";
                return null;
              },
            );
          },
        );
      }
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, {String? helperText}) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(color: Colors.grey.shade600),
      helperText: helperText,
      helperStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 11),
      helperMaxLines: 2,
      prefixIcon: Icon(icon, color: primaryNavColor),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryNavColor, width: 1.5)),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }
}