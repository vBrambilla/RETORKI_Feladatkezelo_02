import 'package:flutter/material.dart';
import 'header.dart';

class ArchivedPage extends StatelessWidget {
  const ArchivedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(currentPage: '/archived'),
      body: const Center(child: Text('Archivált elemek - fejlesztés alatt.')),
    );
  }
}
