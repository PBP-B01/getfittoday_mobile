import 'package:flutter/material.dart';
import 'package:getfittoday_mobile/constants.dart';
import 'package:google_fonts/google_fonts.dart';

class MyHomePage extends StatelessWidget {
  final String title;

  const MyHomePage({super.key, this.title = 'GETFIT.TODAY'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 24,
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [gradientStartColor, gradientEndColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '"YOUR ONE-STOP SOLUTION TO GET FIT"',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 32),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18.0),
                      border: Border.all(color: cardBorderColor),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromARGB(48, 13, 43, 63),
                          offset: Offset(0, 12),
                          blurRadius: 28,
                        ),
                        BoxShadow(
                          color: Color.fromARGB(32, 13, 43, 63),
                          offset: Offset(0, 40),
                          blurRadius: 80,
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 420,
                      child: Center(
                        child: Text(
                          'Content placeholder',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: inkWeakColor,
                          ),
                        ),
                      ),
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
}
