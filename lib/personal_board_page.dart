import 'package:flutter/material.dart';
import 'header.dart';

class PersonalBoardPage extends StatelessWidget {
  const PersonalBoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(currentPage: '/personal_board'),
      body: const Center(
        child: Text('Személyes munkatábla - fejlesztés alatt.'),
      ),
    );
  }
}
