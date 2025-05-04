import 'package:flutter/material.dart';
import 'header.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(currentPage: '/calendar'),
      body: const Center(child: Text('Naptár - fejlesztés alatt.')),
    );
  }
}
