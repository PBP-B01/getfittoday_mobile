import 'package:flutter/material.dart';
import 'package:getfittoday_mobile/constants.dart';
import 'package:getfittoday_mobile/models/location_point.dart';
import 'package:getfittoday_mobile/services/location_service.dart';
import 'package:getfittoday_mobile/widgets/site_navbar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

class MyHomePage extends StatefulWidget {
  final String title;

  const MyHomePage({super.key, this.title = 'GETFIT.TODAY'});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<List<LocationPoint>> _locationsFuture;
  bool _initialized = false;
  final _locationService = const LocationService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final request = context.read<CookieRequest>();
      _locationsFuture = _locationService.fetchLocations(request);
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [gradientStartColor, gradientEndColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            SiteNavBar(
              active: NavDestination.home,
              brandTitle: widget.title,
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 24.0,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '"YOUR ONE-STOP SOLUTION TO GET FIT"',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _LocationsPanel(future: _locationsFuture),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationsPanel extends StatelessWidget {
  final Future<List<LocationPoint>> future;

  const _LocationsPanel({required this.future});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LocationPoint>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 18.0),
            child: Center(child: CircularProgressIndicator.adaptive()),
          );
        }
        if (snapshot.hasError) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorderColor),
            ),
            child: Text(
              'Gagal memuat data lokasi. Periksa endpoint homeLocationsEndpoint di constants.dart\n${snapshot.error}',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.red.shade600,
              ),
            ),
          );
        }

        final locations = snapshot.data ?? [];
        if (locations.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorderColor),
            ),
            child: Text(
              'Belum ada lokasi. Tambahkan lokasi di Django, lalu refresh.',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: inkWeakColor,
              ),
            ),
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorderColor),
            boxShadow: const [
              BoxShadow(
                color: Color.fromARGB(32, 13, 43, 63),
                offset: Offset(0, 10),
                blurRadius: 26,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lokasi dari Django',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: primaryNavColor,
                ),
              ),
              const SizedBox(height: 10),
              ...locations.take(6).map(
                (loc) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.place, size: 18, color: inkWeakColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.name,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                                color: inputTextColor,
                              ),
                            ),
                            if (loc.address != null && loc.address!.isNotEmpty)
                              Text(
                                loc.address!,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: inkWeakColor,
                                ),
                              ),
                            if (loc.category != null &&
                                loc.category!.isNotEmpty)
                              Text(
                                loc.category!,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: primaryNavColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (locations.length > 6)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    '+${locations.length - 6} lokasi lainnya siap dipakai modul lain.',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: accentDarkColor,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
