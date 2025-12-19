import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:getfittoday_mobile/constants.dart';
import 'package:getfittoday_mobile/widgets/site_navbar.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/community.dart';
import '../../screens/community_detail.dart';
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

  void _navigateToAddForm() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CommunityFormPage()),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEAF2FF),
              Color(0xFFBFD6F2),
            ],
          ),
        ),
        child: Column(
          children: [
            const SiteNavBar(active: NavDestination.community),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
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
                                hintText: 'Search community name or sport...',
                                hintStyle: GoogleFonts.inter(color: Colors.grey),
                                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: _navigateToAddForm,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: primaryNavColor,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              ),
                              child: const Icon(Icons.add, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.5)),
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
                            return Padding(
                              padding: const EdgeInsets.only(top: 40),
                              child: Text(
                                "No communities available.",
                                style: GoogleFonts.inter(color: Colors.grey[700]),
                              ),
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
                                      ? "No results found."
                                      : (isAllCommunities ? "No communities available." : "You haven't joined any community yet."),
                                  style: GoogleFonts.inter(color: Colors.grey[700]),
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
      ),
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
              color: isActive ? Colors.white : Colors.grey[700],
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC8DDF6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D2B3F).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey.shade100,
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.groups, size: 30, color: Colors.grey);
                          },
                        )
                      : const Icon(Icons.groups, size: 30, color: Colors.grey),
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1B2B5A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      community.shortDescription.isNotEmpty ? community.shortDescription : community.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7A99)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 18, color: Color(0xFF6B7A99)),
              const SizedBox(width: 6),
              Text(
                "${community.membersCount} Members",
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF6B7A99)),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.fitness_center, size: 18, color: Color(0xFF6B7A99)),
              const SizedBox(width: 6),
              Text(
                community.category ?? "General",
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF6B7A99)),
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
                backgroundColor: Colors.white,
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
