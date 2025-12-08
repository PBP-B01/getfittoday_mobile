import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:getfittoday_mobile/constants.dart';
import 'package:getfittoday_mobile/widgets/site_navbar.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/community.dart';
import 'community_detail.dart';
import 'community_form.dart';

class CommunityListPage extends StatefulWidget {
  const CommunityListPage({super.key});

  @override
  State<CommunityListPage> createState() => _CommunityListPageState();
}

class _CommunityListPageState extends State<CommunityListPage> {
  bool isAllCommunities = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  // Fungsi navigasi ke form (dipakai di tombol baru)
  void _navigateToAddForm() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CommunityFormPage()),
    );
    setState(() {}); // Refresh setelah balik dari form
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const SiteNavBar(active: NavDestination.community),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // --- SEARCH BAR + ADD BUTTON (SEJAJAR) ---
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value.toLowerCase();
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Search community...',
                              hintStyle: GoogleFonts.inter(color: Colors.grey),
                              prefixIcon: const Icon(Icons.search, color: Colors.grey),
                              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12), // Lebih bulat
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // TOMBOL ADD (+) PINDAH KE SINI
                        InkWell(
                          onTap: _navigateToAddForm,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: primaryNavColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.add, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // --- TOGGLE BUTTONS ---
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12), // Konsisten bulatnya
                      ),
                      child: Row(
                        children: [
                          _buildToggleButton("All Communities", isAllCommunities, () {
                            setState(() => isAllCommunities = true);
                          }),
                          _buildToggleButton("My Communities", !isAllCommunities, () {
                            setState(() => isAllCommunities = false);
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- LIST DATA ---
                    FutureBuilder(
                      future: fetchCommunities(request),
                      builder: (context, AsyncSnapshot snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        } else if (snapshot.hasError) {
                          return Center(child: Text("Error: ${snapshot.error}"));
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: Text("Belum ada komunitas."),
                          );
                        } else {
                          List<Community> allData = snapshot.data!;
                          List<Community> tabFiltered;
                          if (isAllCommunities) {
                            tabFiltered = allData;
                          } else {
                            tabFiltered = allData.where((c) => c.isMember).toList();
                          }

                          List<Community> finalData;
                          if (_searchQuery.isEmpty) {
                            finalData = tabFiltered;
                          } else {
                            finalData = tabFiltered.where((c) {
                              final name = c.name.toLowerCase();
                              final category = (c.category ?? "").toLowerCase();
                              return name.contains(_searchQuery) || category.contains(_searchQuery);
                            }).toList();
                          }

                          if (finalData.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 40),
                              child: Text(
                                _searchQuery.isNotEmpty 
                                    ? "Tidak ditemukan."
                                    : (isAllCommunities ? "Belum ada komunitas." : "Kamu belum bergabung."),
                                style: GoogleFonts.inter(color: Colors.grey),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: finalData.length, 
                            itemBuilder: (_, index) {
                              Community community = finalData[index];
                              return _buildCommunityCard(context, community);
                            },
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      // FloatingActionButton sudah dihapus dari sini
    );
  }

  Widget _buildToggleButton(String text, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? primaryNavColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: isActive ? Colors.white : Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommunityCard(BuildContext context, Community community) {
    String? imageUrl;
    if (community.image != null && community.image!.isNotEmpty) {
      imageUrl = "$djangoBaseUrl${community.image}";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start, // Biar sejajar atas
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey.shade300,
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.groups, size: 30, color: Colors.white);
                          },
                        )
                      : const Icon(Icons.groups, size: 30, color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      community.name,
                      style: GoogleFonts.inter(
                        fontSize: 18, // Sedikit diperbesar
                        fontWeight: FontWeight.bold,
                        color: inputTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // 👇 INI DIA! DESKRIPSI SINGKAT (TAGLINE) 👇
                    Text(
                      community.shortDescription.isNotEmpty ? community.shortDescription : community.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    // 👆 ----------------------------------- 👆
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 18, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                "${community.membersCount} Members",
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.sports_soccer, size: 18, color: Colors.grey), // Bisa diganti icon dinamis nanti
              const SizedBox(width: 6),
              Text(
                community.category ?? "General",
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CommunityDetailPage(communityId: community.id),
                  ),
                ).then((_) => setState(() {}));
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: primaryNavColor, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                "View",
                style: GoogleFonts.inter(
                  color: primaryNavColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}