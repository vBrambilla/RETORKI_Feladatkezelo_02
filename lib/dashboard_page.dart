import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'header.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Felhasználó';

    return Scaffold(
      appBar: const AppHeader(currentPage: '/dashboard'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Üdvözöllek, $displayName!',
              style: GoogleFonts.merriweather(
                fontSize: 24,
                color: const Color(0xFF8A7E8D),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Friss teendők',
                        style: GoogleFonts.merriweather(
                          fontSize: 18,
                          color: const Color(0xFF8A7E8D),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Még nincs adat.'),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Közelgő határidők',
                        style: GoogleFonts.merriweather(
                          fontSize: 18,
                          color: const Color(0xFF8A7E8D),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Még nincs adat.'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFFD9BB8A),
        child: Text('AI', style: GoogleFonts.openSans(color: Colors.white)),
      ),
    );
  }
}
