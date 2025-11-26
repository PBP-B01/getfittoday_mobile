import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GetFit Today',
      theme: ThemeData(
        primaryColor: const Color(0xFF005960),
        scaffoldBackgroundColor: const Color(0xFFEBF3FA),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const CommunityEventsPage(),
    );
  }
}

class CommunityEventsPage extends StatelessWidget {
  const CommunityEventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryTeal = const Color(0xFF005960);
    final Color accentYellow = const Color(0xFFFFC107);
    final Color textDarkBlue = const Color(0xFF0D47A1);
    final Color buttonGray = const Color(0xFF6C757D);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryTeal,
        elevation: 0,
        titleSpacing: 16,
        title: const Text(
          'GETFIT.TODAY',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 0.5),
        ),
        actions: [
          CircleAvatar(radius: 18, backgroundColor: accentYellow, child: const Icon(Icons.person, color: Colors.black, size: 24)),
          const SizedBox(width: 12),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(border: Border.all(color: Colors.white54, width: 1.5), borderRadius: BorderRadius.circular(6)),
            child: IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () {},
                child: const Text("← Kembali ke asdasd", style: TextStyle(color: Colors.black87, fontSize: 14)),
              ),
            ),

            Center(
              child: Text('Community Events', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: textDarkBlue)),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 80,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(backgroundColor: accentYellow, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
                            child: const Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Semua", style: TextStyle(fontWeight: FontWeight.bold)), Text("Event", style: TextStyle(fontWeight: FontWeight.bold))]),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 80,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(backgroundColor: buttonGray, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
                            child: const Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Event yang Saya", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), Text("Kelola", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))]),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add, color: Colors.black87),
                      label: const Text("Buat Event Baru", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: accentYellow, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: ExpansionTile(
                initiallyExpanded: true,
                shape: const RoundedRectangleBorder(side: BorderSide.none),
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),

                controlAffinity: ListTileControlAffinity.leading,
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                title: const Text(
                  "Filter Panel",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF0D47A1)),
                ),
                children: [
                  const Divider(height: 1, thickness: 0.5, color: Colors.black12),
                  const SizedBox(height: 16),

                  _buildInputLabel("Nama Event"),
                  _buildTextField(hint: "Cari nama event..."),

                  const SizedBox(height: 12),
                  _buildInputLabel("Lokasi"),
                  _buildTextField(hint: "Masukkan lokasi..."),

                  const SizedBox(height: 12),
                  _buildInputLabel("Tanggal"),
                  _buildDropdownField(value: "Terbaru Ditambahkan"),

                  const SizedBox(height: 12),
                  _buildInputLabel("Komunitas"),
                  _buildTextField(hint: "Cari komunitas..."),

                  const SizedBox(height: 12),
                  _buildInputLabel("Status Event"),
                  _buildDropdownField(value: "Semua Event"),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 45,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C757D),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text("Reset", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 45,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentYellow,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text("Terapkan Filter", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            _buildEventCard(
              title: "w", description: "iji", date: "2025-11-14 15:31", location: "ygbyby", organizer: "Junior Smash Club", participants: "0 peserta terdaftar", status: "Event Selesai", isRegistrationOpen: false,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0D47A1),
        ),
      ),
    );
  }

  Widget _buildTextField({required String hint}) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildDropdownField({required String value}) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(value, style: const TextStyle(color: Colors.black87, fontSize: 14)),
          const Icon(Icons.keyboard_arrow_down, color: Colors.black54, size: 20),
        ],
      ),
    );
  }

  Widget _buildEventCard({required String title, required String description, required String date, required String location, required String organizer, String? participants, required String status, required bool isRegistrationOpen}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.all(20.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0D47A1))), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(20)), child: Text(status, style: TextStyle(fontSize: 11, color: Colors.grey.shade800, fontWeight: FontWeight.bold)))]),
          const SizedBox(height: 8), Text(description, style: const TextStyle(color: Colors.black54)), const SizedBox(height: 16),
          _buildMetaItem(Icons.calendar_today, date, Colors.blue), const SizedBox(height: 8), _buildMetaItem(Icons.location_on, location, Colors.redAccent), const SizedBox(height: 8), _buildMetaItem(Icons.business, organizer, Colors.green), if (participants != null) ...[const SizedBox(height: 8), _buildMetaItem(Icons.people, participants, Colors.deepPurple)],
        ])),
        const Divider(height: 1, color: Colors.black12),
        Padding(padding: const EdgeInsets.all(16.0), child: SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: isRegistrationOpen ? () {} : null, style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade400, disabledBackgroundColor: const Color(0xFFAAAAAA), disabledForegroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0), child: Text(isRegistrationOpen ? "Daftar Sekarang" : "Pendaftaran Ditutup", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))))
      ]),
    );
  }

  Widget _buildMetaItem(IconData icon, String text, Color iconColor) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 18, color: iconColor), const SizedBox(width: 10), Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: Colors.black87)))]);
  }
}