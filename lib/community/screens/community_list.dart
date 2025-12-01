import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:getfittoday_mobile/constants.dart';
import 'package:getfittoday_mobile/widgets/site_navbar.dart'; // Import Navbar Temanmu
import '../models/community.dart';
import 'community_detail.dart';
import 'community_form.dart';

class CommunityListPage extends StatefulWidget {
  const CommunityListPage({super.key});

  @override
  State<CommunityListPage> createState() => _CommunityListPageState();
}

class _CommunityListPageState extends State<CommunityListPage> {
  
  Future<List<Community>> fetchCommunities(CookieRequest request) async {
    final response = await request.get('$djangoBaseUrl/community/api/communities/');
    var data = response;
    List<Community> listCommunity = [];
    for (var d in data) {
      if (d != null) {
        listCommunity.add(Community.fromJson(d));
      }
    }
    return listCommunity;
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      // ❌ KITA HAPUS APPBAR BIRU BIASA
      // appBar: AppBar(...), 
      
      // ✅ KITA GANTI BODY PAKE KOLOM (NAVBAR DI ATAS)
      body: Column(
        children: [
          // 1. INI NAVBAR DJANGO (Warna Hijau Tua)
          const SiteNavBar(
            active: NavDestination.community, // Biar tulisan COMMUNITY-nya tebal/aktif
          ),
          
          // 2. Konten List Community
          Expanded(
            child: Container(
              // Kasih background gradient tipis biar sama kayak Home (Opsional)
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [gradientStartColor, gradientEndColor],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: FutureBuilder(
                future: fetchCommunities(request),
                builder: (context, AsyncSnapshot snapshot) {
                  if (snapshot.data == null) {
                    return const Center(child: CircularProgressIndicator());
                  } else {
                    if (snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          "Belum ada komunitas.",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      );
                    } else {
                      return ListView.builder(
                        padding: const EdgeInsets.only(top: 10, bottom: 80), // Padding bawah biar ga ketutup FAB
                        itemCount: snapshot.data!.length,
                        itemBuilder: (_, index) {
                          Community community = snapshot.data![index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    community.name,
                                    style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, color: Colors.red, size: 16),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          community.fitnessSpot?.name ?? "Lokasi Online/Tidak diketahui",
                                          style: const TextStyle(color: Colors.grey),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryNavColor, // Pakai warna tema
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => CommunityDetailPage(communityId: community.id),
                                          ),
                                        ).then((_) => setState(() {}));
                                      },
                                      child: const Text("Lihat Detail"),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }
                  }
                },
              ),
            ),
          ),
        ],
      ),
      
      // Floating Action Button tetep ada
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CommunityFormPage()),
          );
          setState(() {}); 
        },
        backgroundColor: accentColor, // Pakai warna tema kuning
        foregroundColor: inputTextColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}