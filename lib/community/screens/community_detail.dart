import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:getfittoday_mobile/constants.dart'; // Pastikan path constants benar

class CommunityDetailPage extends StatefulWidget {
  final int communityId;

  const CommunityDetailPage({super.key, required this.communityId});

  @override
  State<CommunityDetailPage> createState() => _CommunityDetailPageState();
}

class _CommunityDetailPageState extends State<CommunityDetailPage> {
  // Variabel untuk menyimpan data detail dari Django
  Map<String, dynamic>? communityData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Panggil fetch data pas halaman dibuka pertama kali
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final request = context.read<CookieRequest>();
      fetchDetail(request);
    });
  }

  // Fungsi ambil data detail dari API Django
  Future<void> fetchDetail(CookieRequest request) async {
    try {
      final response = await request.get(
        '$djangoBaseUrl/community/api/community/${widget.communityId}/',
      );
      
      if (mounted) {
        setState(() {
          communityData = response;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetch detail: $e");
    }
  }

  // Fungsi Logic Join / Leave
  Future<void> toggleJoin(CookieRequest request, bool hasJoined) async {
    // Tentukan URL: Kalau udah join berarti mau Leave, dan sebaliknya
    String urlType = hasJoined ? "leave" : "join";
    final url = '$djangoBaseUrl/community/ajax/$urlType/${widget.communityId}/';

    try {
      // Kirim request POST ke Django (body kosong karena logic pakai session user & ID di URL)
      final response = await request.post(url, {});
      
      if (mounted) {
        if (response['success'] == true) {
          // Refresh halaman biar datanya update (jumlah member & tombol berubah)
          fetchDetail(request);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(hasJoined ? "Berhasil keluar dari komunitas." : "Berhasil bergabung!"),
              backgroundColor: hasJoined ? Colors.orange : Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['error'] ?? "Gagal memproses permintaan"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    // Tampilan Loading
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Loading...")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Ambil data-data penting dari JSON dengan aman (Safe Null Check)
    final name = communityData?['name'] ?? "Nama Tidak Ada";
    final description = communityData?['description'] ?? "-";
    final contact = communityData?['contact_info'] ?? "-";
    final memberCount = communityData?['members_count'] ?? 0;
    
    // Integrasi Lokasi: Ambil nama fitness spot
    final fitnessSpotName = communityData?['fitness_spot'] != null 
        ? communityData!['fitness_spot']['name'] 
        : "Lokasi tidak diketahui/Online";
    
    // Status User (Diambil dari 'Has Joined' dan 'Is Admin' yang kita set di Django views)
    final bool hasJoined = communityData?['has_joined'] ?? false;
    final bool isAdmin = communityData?['is_admin'] ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Komunitas"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Gambar / Icon Besar
            Container(
              height: 180,
              width: double.infinity,
              color: Colors.blue.shade50,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.groups_rounded, size: 80, color: Colors.blueAccent),
                  const SizedBox(height: 10),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Info Lokasi & Member
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fitnessSpotName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.people, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        "$memberCount Anggota Terdaftar",
                        style: const TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ],
                  ),

                  const Divider(height: 40, thickness: 1),

                  // 3. Tombol Action (Join/Leave)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: isAdmin 
                    ? ElevatedButton.icon(
                        onPressed: null, // Admin gak bisa leave lewat sini
                        icon: const Icon(Icons.admin_panel_settings),
                        label: const Text("Anda adalah Admin"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.black54,
                        ),
                      )
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hasJoined ? Colors.red.shade400 : Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => toggleJoin(request, hasJoined),
                        child: Text(
                          hasJoined ? "Keluar dari Komunitas (Leave)" : "Gabung Komunitas (Join)",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ),

                  const SizedBox(height: 30),
                  
                  // 4. Deskripsi
                  const Text(
                    "Tentang Komunitas",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      description,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 5. Kontak Info
                  const Text(
                    "Kontak Admin",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Icon(Icons.chat, color: Colors.white),
                    ),
                    title: Text(contact, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text("Hubungi via WhatsApp/Instagram"),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}