import 'package:flutter/material.dart';
import 'header.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(currentPage: '/notifications'),
      body: const Center(child: Text('Értesítések - fejlesztés alatt.')),
    );
  }
}
