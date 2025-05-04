import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String currentPage;

  const AppHeader({super.key, required this.currentPage});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white, // Fehér háttér
      elevation: 0, // Nincs árnyék alapértelmezett állapotban
      scrolledUnderElevation: 0, // Nincs árnyék scrollozáskor sem
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      leadingWidth: 56.0, // Finomhangolás a "Vissza" nyíl szélességére
      titleSpacing: 0.0, // Nincs felesleges eltolás a title-ban
      title: SizedBox(
        height: 90, // Nagyobb magasság a logó teljes megjelenítéséhez
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0), // Felső margó
            child: Row(
              children: [
                Image.asset(
                  'assets/logo.png',
                  height: 40, // Eredeti érték, ami működött
                  fit:
                      BoxFit
                          .contain, // Biztosítja, hogy a kép teljes egészében látható legyen
                ),
                const SizedBox(width: 8),
                Text(
                  'Feladatkezelő',
                  style: GoogleFonts.openSans(
                    color: const Color(0xFF8A7E8D),
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        SizedBox(
          height: 90, // Szinkronizált magasság a középpontok igazításához
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0), // Felső margó
              child: TextButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: Text(
                  'Kijelentkezés',
                  style: GoogleFonts.openSans(color: const Color(0xFF8A7E8D)),
                ),
              ),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Wrap(
            spacing: 16.0, // Gombok közötti távolság
            runSpacing: 8.0, // Sorok közötti távolság
            alignment: WrapAlignment.spaceBetween, // Szélesség kihasználása
            children: [
              _buildNavButton(context, 'Főoldal', Icons.home, '/dashboard'),
              _buildNavButton(
                context,
                'Közös munkatáblák',
                Icons.group_work,
                '/team_board',
              ),
              _buildNavButton(
                context,
                'Személyes munkatábla',
                Icons.person,
                '/personal_board',
              ),
              _buildNavButton(
                context,
                'Naptár',
                Icons.calendar_today,
                '/calendar',
              ),
              _buildNavButton(context, 'Üzenetek', Icons.message, '/messages'),
              _buildNavButton(
                context,
                'Értesítések',
                Icons.notifications,
                '/notifications',
              ),
              _buildNavButton(
                context,
                'Archivált elemek',
                Icons.archive,
                '/archived',
              ),
              _buildNavButton(
                context,
                'Profil',
                Icons.account_circle,
                '/profile',
              ),
              _buildNavButton(
                context,
                'Felhasználók kezelése',
                Icons.supervisor_account,
                '/user_management',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton(
    BuildContext context,
    String title,
    IconData icon,
    String route,
  ) {
    bool isActive = currentPage == route;
    return SizedBox(
      width: 120, // Fix szélesség a középpontok egyenlő távolságához
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Stack(
              children: [
                Icon(
                  icon,
                  color:
                      isActive
                          ? const Color(0xFFD9BB8A)
                          : const Color(0xFF8A7E8D),
                ),
                if ((title == 'Üzenetek' || title == 'Értesítések') &&
                    false) // TODO: olvasatlan jelzés
                  const Positioned(
                    right: 0,
                    top: 0,
                    child: Icon(
                      Icons.circle,
                      color: Color(0xFFD9BB8A),
                      size: 10,
                    ),
                  ),
              ],
            ),
            iconSize: 28,
            onPressed: () {
              if (route != currentPage) {
                Navigator.pushNamed(context, route);
              }
            },
          ),
          Flexible(
            child: Text(
              title,
              style: GoogleFonts.openSans(
                color:
                    isActive
                        ? const Color(0xFFD9BB8A)
                        : const Color(0xFF8A7E8D),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(150); // Nagyobb magasság a túllógás elkerüléséhez
}
