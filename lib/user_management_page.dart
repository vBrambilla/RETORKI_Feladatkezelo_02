import 'package:flutter/material.dart';
import 'header.dart';

class UserManagementPage extends StatelessWidget {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(currentPage: '/user_management'),
      body: const Center(
        child: Text('Felhasználók kezelése - fejlesztés alatt.'),
      ),
    );
  }
}
