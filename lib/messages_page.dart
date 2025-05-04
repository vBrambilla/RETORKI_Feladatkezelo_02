import 'package:flutter/material.dart';
import 'header.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(currentPage: '/messages'),
      body: const Center(child: Text('Üzenetek - fejlesztés alatt.')),
    );
  }
}
