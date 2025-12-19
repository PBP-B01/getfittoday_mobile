import 'package:flutter/material.dart';
import 'package:getfittoday_mobile/constants.dart';
import 'package:getfittoday_mobile/screens/booking_reservation.dart';
import 'package:getfittoday_mobile/screens/home.dart';
import 'package:getfittoday_mobile/screens/login.dart';
import 'package:getfittoday_mobile/screens/register.dart';
import 'package:getfittoday_mobile/screens/products_entry_list.dart';
import 'package:getfittoday_mobile/screens/my_bookings.dart';
import 'package:getfittoday_mobile/state/auth_state.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:getfittoday_mobile/utils/maps_loader.dart' if (dart.library.html) 'package:getfittoday_mobile/utils/maps_loader_web.dart';

Future<void> main() async {
  await dotenv.load(fileName: "assets/.env");
  await loadGoogleMaps();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryNavColor,
      primary: primaryNavColor,
      secondary: accentColor,
      surface: Colors.white,
      background: gradientStartColor,
      onPrimary: Colors.white,
      onSecondary: const Color(0xFF0B2E55),
    );

    return MultiProvider(
      providers: [
        Provider<CookieRequest>(create: (_) => CookieRequest()),
        ChangeNotifierProvider<AuthState>(create: (_) => AuthState()),
      ],
      child: MaterialApp(
        title: 'GetFitToday',
        theme: ThemeData(
          colorScheme: colorScheme,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: AppBarTheme(
            backgroundColor: primaryNavColor,
            foregroundColor: Colors.white,
            elevation: 0,
            titleTextStyle: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: Colors.white,
            ),
          ),
          textTheme: GoogleFonts.interTextTheme(
            ThemeData.light().textTheme,
          ).apply(
            bodyColor: inputTextColor,
            displayColor: inputTextColor,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: inputBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: cardBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: cardBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: cardBorderStrongColor),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
          ),
        ),
        home: const LoginPage(),
        routes: {
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
          '/home': (context) => const MyHomePage(),
          '/booking': (context) => const BookingReservationPage(),
          '/store' : (context) => const ProductEntryListPage(),
          '/my-bookings': (context) => const MyBookingsPage(),
        },
      ),
    );
  }
}
