import 'package:flutter/material.dart';
import 'header.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(currentPage: '/profile'),
      body: const Center(child: Text('Profil - fejlesztés alatt.')),
    );
  }
}
