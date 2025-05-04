import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Hozzáadjuk a lokalizációs csomagot
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Importáljuk az intl csomagot
import 'package:intl/date_symbol_data_local.dart'; // Dátumformázási adatok inicializálásához
import 'firebase_options.dart';
import 'login_page.dart';
import 'dashboard_page.dart';
import 'personal_board_page.dart';
import 'team_board_page.dart';
import 'team_board_details.dart';
import 'calendar_page.dart';
import 'messages_page.dart';
import 'notifications_page.dart';
import 'archived_page.dart';
import 'profile_page.dart';
import 'user_management_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Inicializáljuk a magyar dátumformázást
  await initializeDateFormatting('hu', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RETÖRKI Feladatkezelő',
      theme: ThemeData(
        primaryColor: const Color(0xFFD9BB8A), // Arany
        scaffoldBackgroundColor: Colors.white, // Fehér háttér
        textTheme: TextTheme(
          bodyMedium: GoogleFonts.openSans(), // Folyószöveg: Open Sans
          titleLarge: GoogleFonts.merriweather(), // Hangsúlyos: Merriweather
        ),
        iconTheme: const IconThemeData(color: Color(0xFFD9BB8A)),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFFD9BB8A), // Arany gombok
          ),
        ),
      ),
      // Hozzáadjuk a lokalizációs delegate-eket
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Támogatott nyelvek (magyar)
      supportedLocales: const [Locale('hu', 'HU')],
      locale: const Locale('hu', 'HU'), // Alapértelmezett nyelv: magyar
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/team_board': (context) => const TeamBoardPage(),
        '/team_board_details': (context) => const TeamBoardDetailsPage(),
        '/personal_board': (context) => const PersonalBoardPage(),
        '/calendar': (context) => const CalendarPage(),
        '/messages': (context) => const MessagesPage(),
        '/notifications': (context) => const NotificationsPage(),
        '/archived': (context) => const ArchivedPage(),
        '/profile': (context) => const ProfilePage(),
        '/user_management': (context) => const UserManagementPage(),
      },
    );
  }
}
