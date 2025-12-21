import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:getfittoday_mobile/constants.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/community_event_page.dart';
import '../screens/community_form.dart';

class CommunityDetailPage extends StatefulWidget {
  final int communityId;

  const CommunityDetailPage({super.key, required this.communityId});

  @override
  State<CommunityDetailPage> createState() => _CommunityDetailPageState();
}

class _CommunityDetailPageState extends State<CommunityDetailPage> {
  Map<String, dynamic>? communityData;
  bool isLoading = true;

  int _selectedTabIndex = 0;
  final List<String> _tabs = ["About", "Schedule", "Members"];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final request = context.read<CookieRequest>();
      fetchDetail(request);
    });
  }

  Future<void> fetchDetail(CookieRequest request) async {
    try {
      final response = await request.get('$djangoBaseUrl/community/api/community/${widget.communityId}/');
      if (mounted) {
        setState(() {
          communityData = response;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching detail: $e");
    }
  }

  Future<void> toggleJoin(CookieRequest request, bool hasJoined) async {
    String urlType = hasJoined ? "leave" : "join";
    final url = '$djangoBaseUrl/community/ajax/$urlType/${widget.communityId}/';
    try {
      final response = await request.post(url, {});
      if (mounted && response['success'] == true) {
        fetchDetail(request);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(hasJoined ? "Successfully left." : "Successfully joined!"),
            backgroundColor: hasJoined ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> deleteCommunity() async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.post('$djangoBaseUrl/community/api/delete/${widget.communityId}/', {});
      if (mounted) {
        if (response['status'] == 'success') {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Community deleted successfully."), backgroundColor: Colors.red));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'])));
        }
      }
    } catch (e) {
      print("Error deleting: $e");
    }
  }

  Future<void> promoteMember(String username) async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.post(
        '$djangoBaseUrl/community/api/promote/${widget.communityId}/',
        {"username": username}
      );
      if (mounted) {
        if (response['status'] == 'success') {
          fetchDetail(request);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Successfully promoted to Admin!"), backgroundColor: Colors.green));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'])));
        }
      }
    } catch (e) {
      print("Error promoting: $e");
    }
  }

  void showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Community?"),
        content: const Text("This action cannot be undone. All data will be lost."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              deleteCommunity();
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String formatDate(String? dateString) {
    if (dateString == null) return "-";
    try {
      DateTime date = DateTime.parse(dateString);
      const List<String> months = [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
      ];
      return "${months[date.month - 1]} ${date.year}";
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final name = communityData?['name'] ?? "No Name";
    final shortDescription = communityData?['short_description'] ?? "";
    final category = communityData?['category'] ?? "General";
    final description = communityData?['description'] ?? "-";
    final contact = communityData?['contact_info'] ?? "-";
    final memberCount = communityData?['members_count'] ?? 0;
    final fitnessSpotName = communityData?['fitness_spot'] != null
        ? communityData!['fitness_spot']['name']
        : "Online";

    final String established = formatDate(communityData?['created_at']);

    final String? imagePath = communityData?['image'];
    final bool hasJoined = communityData?['has_joined'] ?? false;
    final bool isCommunityAdmin = communityData?['is_admin'] ?? false;
    final bool isSuperAdmin = communityData?['is_superadmin'] ?? false;
    final bool canManage = communityData?['can_manage'] ?? (isCommunityAdmin || isSuperAdmin);

    final String rawSchedule = communityData?['schedule'] ?? "";
    final List<dynamic> membersList = communityData?['members'] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFBFD6F2),
      body: Stack(
        children: [
          SizedBox(
            height: 250,
            width: double.infinity,
            child: (imagePath != null && imagePath.isNotEmpty)
                ? Image.network(
                    "$djangoBaseUrl$imagePath",
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Image.network(
                      "https://images.unsplash.com/photo-1571902943202-507ec2618e8f",
                      fit: BoxFit.cover,
                    ),
                  )
                : Image.network(
                    "https://images.unsplash.com/photo-1571902943202-507ec2618e8f",
                    fit: BoxFit.cover,
                  ),
          ),
          Container(
            height: 250,
            width: double.infinity,
            color: Colors.black.withOpacity(0.4),
          ),

          SingleChildScrollView(
            child: Column(
              children: [
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Detail Community",
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 4, offset: const Offset(0, 2))
                                ],
                              ),
                            ),
                          ],
                        ),

                        if (canManage)
                          Container(
                            decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
                            child: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: Colors.white),
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CommunityFormPage(existingData: communityData),
                                    ),
                                  );
                                  if (mounted) {
                                    final request = context.read<CookieRequest>();
                                    fetchDetail(request);
                                  }
                                } else if (value == 'delete') {
                                  showDeleteConfirmation();
                                }
                              },
                              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                const PopupMenuItem<String>(
                                  value: 'edit',
                                  child: ListTile(leading: Icon(Icons.edit), title: Text('Edit Community')),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'delete',
                                  child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Delete Community', style: TextStyle(color: Colors.red))),
                                ),
                              ],
                            ),
                          )
                        else
                          const SizedBox(width: 48),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 130),

                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFEAF2FF), Color(0xFFBFD6F2)],
                    ),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(4),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey.shade200,
                                child: (imagePath != null && imagePath.isNotEmpty)
                                    ? Image.network(
                                        "$djangoBaseUrl$imagePath",
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, err, stack) => const Icon(Icons.groups, size: 30, color: primaryNavColor),
                                      )
                                    : const Icon(Icons.groups, size: 30, color: primaryNavColor),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                if (shortDescription.isNotEmpty)
                                  Text(shortDescription, style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 14)),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(Icons.person, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text("$memberCount Members", style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade700)),
                                    const SizedBox(width: 16),
                                    const Icon(Icons.fitness_center, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(category, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade700)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: canManage ? null : () => toggleJoin(request, hasJoined),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canManage ? Colors.grey : (hasJoined ? Colors.red.shade400 : primaryNavColor),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            canManage ? "You are Admin" : (hasJoined ? "Leave Community" : "Join Community"),
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CommunityEventsPage(
                                  communityId: widget.communityId,
                                  communityName: name,
                                  canManage: canManage,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.calendar_month, size: 18),
                          label: Text("See Upcoming Events", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryNavColor,
                            side: const BorderSide(color: primaryNavColor),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(_tabs.length, (index) {
                            final isActive = _selectedTabIndex == index;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedTabIndex = index;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 24),
                                padding: const EdgeInsets.only(bottom: 8),
                                decoration: isActive
                                    ? const BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(color: primaryNavColor, width: 3),
                                        ),
                                      )
                                    : null,
                                child: Text(
                                  _tabs[index],
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                                    color: isActive ? primaryNavColor : Colors.grey,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),

                      const Divider(color: Colors.white70, thickness: 2),
                      const SizedBox(height: 24),

                      _buildTabContent(description, category, fitnessSpotName, contact, rawSchedule, membersList, canManage, established),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(String desc, String sportType, String location, String contact, String rawSchedule, List<dynamic> members, bool isAdmin, String established) {
    switch (_selectedTabIndex) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("About", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(desc, style: GoogleFonts.inter(color: Colors.grey.shade700, height: 1.5, fontSize: 15)),
            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFC8DDF6)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                children: [
                  _buildInfoRow("Sport Type", sportType, "Location", location),
                  const SizedBox(height: 20),
                  _buildInfoRow("Contact", contact, "Established", established),
                ],
              ),
            ),
          ],
        );

      case 1:
        if (rawSchedule.isEmpty) {
          return Center(child: Padding(padding: const EdgeInsets.all(20.0), child: Text("No training schedule available.", style: GoogleFonts.inter(color: Colors.grey))));
        }
        List<String> scheduleItems = rawSchedule.split('\n');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Routine Training Schedule", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ...scheduleItems.map((item) {
               if (item.trim().isEmpty) return const SizedBox.shrink();
               String timePart = "Schedule";
               String titlePart = item;

               if (item.contains(" - ")) {
                 final idx = item.indexOf(" - ");
                 timePart = item.substring(0, idx).trim();
                 titlePart = item.substring(idx + 3).trim();
               } else if (item.contains("-")) {
                 final parts = item.split("-");
                 if (parts.length > 1) {
                    timePart = parts[0].trim();
                    titlePart = parts.sublist(1).join("-").trim();
                 }
               }
               return _buildScheduleItem(timePart, titlePart, location);
            }).toList(),
          ],
        );

      case 2:
        if (members.isEmpty) {
           return Center(child: Padding(padding: const EdgeInsets.all(20.0), child: Text("No members yet.", style: GoogleFonts.inter(color: Colors.grey))));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Admins & Members", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ...members.map((m) {
              return _buildMemberItem(
                m['username'],
                m['is_admin'] ? "Admin" : "Member",
                true,
                isAdmin
              );
            }).toList(),
            const SizedBox(height: 40),
          ],
        );

      default:
        return const SizedBox();
    }
  }

  Widget _buildInfoRow(String label1, String val1, String label2, String val2) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label1, style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13)), const SizedBox(height: 6), Text(val1, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15))])),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label2, style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13)), const SizedBox(height: 6), Text(val2, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15))])),
      ],
    );
  }

  Widget _buildScheduleItem(String timePart, String title, String loc) {
    List<String> parts = timePart.split(' ');
    String topText = parts.isNotEmpty ? parts[0] : "";
    String bottomText = parts.length > 1 ? parts.sublist(1).join(' ') : "";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8DDF6)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: const BoxConstraints(minWidth: 80),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFB2DFDB))
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (topText.isNotEmpty)
                  Text(topText, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF00695C))),
                if (bottomText.isNotEmpty)
                  Text(bottomText, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF00695C))),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF1B2B5A))),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Expanded(child: Text(loc, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis)),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberItem(String name, String role, bool isOnline, bool isCurrentUserAdmin) {
    final bool isMemberAdmin = role == "Admin";
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(radius: 24, backgroundColor: Colors.grey.shade200, child: Text(name.isNotEmpty ? name[0].toUpperCase() : "?", style: const TextStyle(color: primaryNavColor, fontWeight: FontWeight.bold, fontSize: 18))),
              if (isOnline) Positioned(right: 0, bottom: 0, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)), const SizedBox(height: 2), Text(role, style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13))])),
          if (isMemberAdmin)
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.orange.shade200)), child: Text("ADMIN", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange.shade800)))
          else if (isCurrentUserAdmin)
            IconButton(icon: const Icon(Icons.arrow_upward, color: primaryNavColor, size: 20), onPressed: () => promoteMember(name)),
        ],
      ),
    );
  }
}
