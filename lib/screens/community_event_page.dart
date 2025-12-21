import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import 'package:getfittoday_mobile/widgets/event_card.dart';
import 'package:getfittoday_mobile/widgets/site_navbar.dart';
import 'package:getfittoday_mobile/constants.dart';
import 'create_event_form.dart';
import 'edit_event_form.dart';

class CommunityEventsPage extends StatefulWidget {
  final int communityId;
  final String communityName;
  final bool isAdmin;

  const CommunityEventsPage({
    super.key,
    required this.communityId,
    required this.communityName,
    required this.isAdmin,
  });

  @override
  State<CommunityEventsPage> createState() => _CommunityEventsPageState();
}

class _CommunityEventsPageState extends State<CommunityEventsPage> {
  String _selectedTab = 'community_only';

  List<Map<String, dynamic>> _allEvents = [];
  List<Map<String, dynamic>> _filteredEvents = [];
  List<String> _availableCommunities = [];
  bool _isLoading = true;

  Key _filterPanelKey = UniqueKey();
  final TextEditingController _searchController = TextEditingController();
  String _sortOption = 'Waktu Acara (Terdekat)';
  String? _filterCommunity;
  String _filterStatus = 'Semua';

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchEvents() async {
    setState(() => _isLoading = true);
    final request = context.read<CookieRequest>();

    try {
      final response = await request.get('http://localhost:8000/event/api/list/');
      List<Map<String, dynamic>> listData = [];
      Set<String> communities = {};

      for (var d in response) {
        if (d != null) {
          var event = Map<String, dynamic>.from(d);
          listData.add(event);
          if (event['community_name'] != null) {
            communities.add(event['community_name']);
          }
        }
      }

      if (mounted) {
        setState(() {
          _allEvents = listData;
          _availableCommunities = communities.toList()..sort();
          _applyFilterLogic();
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error Fetching: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilterLogic() {
    List<Map<String, dynamic>> temp = List.from(_allEvents);

    if (_selectedTab == 'community_only') {
      temp = temp.where((e) => e['community_name'] == widget.communityName).toList();
    }

    if (_searchController.text.isNotEmpty) {
      temp = temp.where((e) {
        final title = (e['name'] ?? '').toString().toLowerCase();
        final search = _searchController.text.toLowerCase();
        return title.contains(search);
      }).toList();
    }

    if (_filterCommunity != null && _filterCommunity != "Semua Komunitas") {
      temp = temp.where((e) => e['community_name'] == _filterCommunity).toList();
    }

    if (_filterStatus != 'Semua') {
      bool wantActive = _filterStatus == 'Aktif';
      temp = temp.where((e) {
        bool isActive = e['is_active'] ?? false;
        return wantActive ? isActive : !isActive;
      }).toList();
    }

    temp.sort((a, b) {
      DateTime dateA = DateTime.parse(a['date'] ?? DateTime.now().toString());
      DateTime dateB = DateTime.parse(b['date'] ?? DateTime.now().toString());
      int idA = a['id'] ?? 0;
      int idB = b['id'] ?? 0;

      switch (_sortOption) {
        case 'Waktu Acara (Terdekat)': return dateA.compareTo(dateB);
        case 'Waktu Acara (Terjauh)': return dateB.compareTo(dateA);
        case 'Baru Ditambahkan': return idB.compareTo(idA);
        default: return dateA.compareTo(dateB);
      }
    });

    setState(() {
      _filteredEvents = temp;
    });
  }

  void _onApplyFilter() {
    setState(() {
      _selectedTab = 'all_global';
      _applyFilterLogic();
      _filterPanelKey = UniqueKey();
    });
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text("Filter berhasil diterapkan!"),
          ],
        ),
        backgroundColor: Colors.blueAccent,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _onResetFilter() {
    setState(() {
      _searchController.clear();
      _sortOption = 'Waktu Acara (Terdekat)';
      _filterCommunity = null;
      _filterStatus = 'Semua';
      _applyFilterLogic();
    });
  }

  Future<void> _handleJoinEvent(int eventId) async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.post('http://localhost:8000/event/api/join/$eventId/', {});
      if (mounted) {
        if (response['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Berhasil Join!"), backgroundColor: Colors.green));
          _fetchEvents();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? "Gagal"), backgroundColor: Colors.red));
        }
      }
    } catch (e) { print("Error Join: $e"); }
  }

  Future<void> _handleLeaveEvent(int eventId) async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.post('http://localhost:8000/event/api/leave/$eventId/', {});
      if (mounted) {
        if (response['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Berhasil keluar event."), backgroundColor: Colors.orange));
          _fetchEvents();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? "Gagal"), backgroundColor: Colors.red));
        }
      }
    } catch (e) { print("Error Leave: $e"); }
  }

  void _showCreateEventForm() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CreateEventForm(
        initialCommunityId: widget.communityId,
        onSuccess: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Event dibuat!"), backgroundColor: Colors.green));
          _fetchEvents();
        },
      ),
    );
  }

  void _showEditEventForm(Map<String, dynamic> eventData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditEventForm(
        eventData: eventData,
        onSuccess: () => _fetchEvents(),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    const Color headerColor = Color(0xFF005960);
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            Container(
              height: 100,
              padding: const EdgeInsets.fromLTRB(20, 40, 10, 10),
              color: headerColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Menu", style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 28), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _buildDrawerItem(Icons.home, "Home", onTap: () => Navigator.pushNamed(context, '/home')),
            _buildDrawerItem(Icons.groups, "Community", isActive: true, onTap: () => Navigator.pushNamed(context, '/community')),
            _buildDrawerItem(Icons.store, "Store", onTap: null, trailing: "Soon"),
            _buildDrawerItem(Icons.calendar_today, "Booking", onTap: () => Navigator.pushNamed(context, '/booking')),
            _buildDrawerItem(Icons.description, "Blogs & Events", onTap: null, trailing: "Soon"),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, {VoidCallback? onTap, String? trailing, bool isActive = false}) {
    const Color iconColor = Color(0xFF005960);
    const Color highlightColor = Color(0xFFFFC107);

    return ListTile(
      leading: Icon(
          icon,
          color: isActive ? highlightColor : iconColor,
          size: 26
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          color: const Color(0xFF002147),
          fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
          fontSize: 16,
        ),
      ),
      trailing: trailing != null
          ? Text(trailing, style: GoogleFonts.inter(color: Colors.grey, fontSize: 12))
          : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  void _showUserMenu(BuildContext context) {
    final request = context.read<CookieRequest>();
    String username = request.jsonData['username'] ?? 'User';
    const Color primaryColor = Color(0xFF005960);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(MediaQuery.of(context).size.width, 80, 0, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFFE8EFF5),
      items: <PopupMenuEntry>[
        PopupMenuItem(
          enabled: false,
          height: 40,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Signed in as", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
              Text(username, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF002147), fontSize: 14)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(height: 40, onTap: () => Navigator.pushNamed(context, '/booking'), child: Text("My bookings", style: GoogleFonts.inter(color: primaryColor, fontWeight: FontWeight.w600))),
        PopupMenuItem(
          height: 40,
          onTap: () async {
            final response = await request.logout('http://localhost:8000/auth/logout_flutter/');
            if (context.mounted && response['status']) Navigator.pushReplacementNamed(context, '/login');
          },
          child: Text("Logout", style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    final Color primaryNavColor = const Color(0xFF005960);
    final Color accentYellow = const Color(0xFFFFC107);
    final Color buttonGray = const Color(0xFF6C757D);
    final Color backgroundBlue = const Color(0xFFE3F2FD);

    return Scaffold(
      backgroundColor: backgroundBlue,
      drawer: isMobile ? _buildDrawer(context) : null,
      appBar: isMobile
          ? AppBar(
        backgroundColor: primaryNavColor,
        elevation: 0,
        title: GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/home');
          },
          child: Text(
            'GETFIT.TODAY',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () => _showUserMenu(context),
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                  radius: 20,
                  backgroundColor: accentYellow,
                  child: const Icon(Icons.person, color: Colors.black)
              ),
            ),
          ),
        ],
      )
          : null,
      body: Column(
        children: [
          if (!isMobile) const SiteNavBar(active: NavDestination.community),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_back, size: 16),
                            const SizedBox(width: 4),
                            Text("Kembali ke ${widget.communityName}", style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      Center(child: Text('Community Events', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: const Color(0xFF0D47A1)))),
                      const SizedBox(height: 24),

                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFilterButton(
                                    label: "Semua\nEvent",
                                    isActive: _selectedTab == 'all_global',
                                    activeColor: accentYellow, inactiveColor: buttonGray,
                                    onTap: () {
                                      setState(() {
                                        _selectedTab = 'all_global';
                                        _applyFilterLogic();
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildFilterButton(
                                    label: "Event\nKomunitas Ini",
                                    isActive: _selectedTab == 'community_only',
                                    activeColor: accentYellow, inactiveColor: buttonGray,
                                    onTap: () {
                                      setState(() {
                                        _selectedTab = 'community_only';
                                        _applyFilterLogic();
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            if (widget.isAdmin) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity, height: 40,
                                child: ElevatedButton(
                                  onPressed: _showCreateEventForm,
                                  style: ElevatedButton.styleFrom(backgroundColor: accentYellow, elevation: 0, padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.add, color: Colors.black87, size: 18), const SizedBox(width: 6), Text("Buat Event Baru", style: GoogleFonts.inter(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14))]),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]),
                        child: ExpansionTile(
                          key: _filterPanelKey,
                          initiallyExpanded: false,
                          shape: const Border(),
                          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                          controlAffinity: ListTileControlAffinity.leading,
                          collapsedIconColor: const Color(0xFF0D47A1),
                          iconColor: const Color(0xFF0D47A1),
                          title: Text("Filter Panel", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: const Color(0xFF0D47A1))),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel("Nama Event"),
                                  const SizedBox(height: 8),
                                  TextField(controller: _searchController, decoration: _inputDecoration("Cari nama event...")),
                                  const SizedBox(height: 16),
                                  _buildLabel("Urutkan Berdasarkan"),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: _sortOption,
                                    decoration: _inputDecoration(""),
                                    items: ["Waktu Acara (Terdekat)", "Waktu Acara (Terjauh)", "Baru Ditambahkan"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                    onChanged: (v) => setState(() => _sortOption = v!),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildLabel("Komunitas"),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: _filterCommunity,
                                    isExpanded: true,
                                    hint: const Text("Pilih Komunitas"),
                                    decoration: _inputDecoration(""),
                                    items: [
                                      const DropdownMenuItem(value: null, child: Text("Semua Komunitas")),
                                      ..._availableCommunities.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis)))
                                    ],
                                    onChanged: (v) => setState(() => _filterCommunity = v),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildLabel("Status Event"),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: _filterStatus,
                                    decoration: _inputDecoration(""),
                                    items: ["Semua", "Aktif", "Selesai"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                    onChanged: (v) => setState(() => _filterStatus = v!),
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Expanded(child: ElevatedButton(onPressed: _onResetFilter, style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade600, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)), child: const Text("Reset"))),
                                      const SizedBox(width: 12),
                                      Expanded(child: ElevatedButton(onPressed: _onApplyFilter, style: ElevatedButton.styleFrom(backgroundColor: accentYellow, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 12)), child: const Text("Terapkan Filter", style: TextStyle(fontWeight: FontWeight.bold)))),
                                    ],
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),

                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (_filteredEvents.isEmpty)
                        Center(
                          child: Column(
                            children: [
                              const SizedBox(height: 40),
                              Icon(Icons.event_busy, size: 60, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text("Tidak ada event yang cocok.", style: TextStyle(color: Colors.grey.shade600)),
                            ],
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _filteredEvents.length,
                          itemBuilder: (context, index) {
                            final event = _filteredEvents[index];
                            return EventCard(
                              event: event,
                              onJoinTap: () => _handleJoinEvent(event['id']),
                              onLeaveTap: () => _handleLeaveEvent(event['id']),
                              onEditTap: () => _showEditEventForm(event),
                            );
                          },
                        ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton({required String label, required bool isActive, required Color activeColor, required Color inactiveColor, required VoidCallback onTap}) {
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(backgroundColor: isActive ? activeColor : inactiveColor, foregroundColor: isActive ? Colors.black87 : Colors.white, padding: const EdgeInsets.all(8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        child: Center(child: Text(label, textAlign: TextAlign.center, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14))),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87));
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
    );
  }
}
