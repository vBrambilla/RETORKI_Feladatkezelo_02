import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'header.dart';

class TeamBoardPage extends StatefulWidget {
  const TeamBoardPage({super.key});

  @override
  _TeamBoardPageState createState() => _TeamBoardPageState();
}

class _TeamBoardPageState extends State<TeamBoardPage> {
  String _sortBy = 'name';
  bool _sortAscending = true;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  List<String> _selectedParticipants = [];
  List<String> _allUsers = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').get();
      setState(() {
        _allUsers =
            snapshot.docs
                .map((doc) => doc['email'] as String)
                .where(
                  (email) => email != FirebaseAuth.instance.currentUser?.email,
                )
                .toList();
      });
    } catch (e) {
      print('Hiba a felhasználók lekérdezésekor: $e');
      setState(() {
        _allUsers = [];
      });
    }
  }

  Future<void> _createTeamBoard() async {
    if (_titleController.text.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A munkatábla neve legalább 3 karakter kell legyen!'),
        ),
      );
      return;
    }
    if (_descriptionController.text.length > 800) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A leírás maximum 800 karakter lehet!')),
      );
      return;
    }
    if (_selectedParticipants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Legalább egy résztvevőt ki kell választani!'),
        ),
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    await FirebaseFirestore.instance.collection('team_boards').add({
      'title': _titleController.text,
      'description':
          _descriptionController.text.isNotEmpty
              ? _descriptionController.text
              : null,
      'participants': [currentUser.email, ..._selectedParticipants],
      'lastModified': Timestamp.now(),
      'createdBy': currentUser.email,
    });

    _titleController.clear();
    _descriptionController.clear();
    _selectedParticipants.clear();
    Navigator.of(context).pop();
  }

  Future<void> _updateTeamBoard(
    String boardId,
    Map<String, dynamic> existingData,
  ) async {
    if (_titleController.text.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A munkatábla neve legalább 3 karakter kell legyen!'),
        ),
      );
      return;
    }
    if (_descriptionController.text.length > 800) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A leírás maximum 800 karakter lehet!')),
      );
      return;
    }
    if (_selectedParticipants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Legalább egy résztvevőt ki kell választani!'),
        ),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('team_boards')
        .doc(boardId)
        .update({
          'title': _titleController.text,
          'description':
              _descriptionController.text.isNotEmpty
                  ? _descriptionController.text
                  : null,
          'participants': _selectedParticipants,
          'lastModified': Timestamp.now(),
        });

    _titleController.clear();
    _descriptionController.clear();
    _selectedParticipants.clear();
    Navigator.of(context).pop();
  }

  Future<void> _archiveTeamBoard(
    String boardId,
    Map<String, dynamic> boardData,
  ) async {
    bool confirm = await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            title: Text(
              'Archiválás megerősítése',
              style: GoogleFonts.openSans(
                color: const Color(0xFF8A7E8D),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Biztos, hogy archiválod a teljes munkatáblát?',
              style: GoogleFonts.openSans(
                color: const Color(0xFF8A7E8D),
                fontSize: 16,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Nem',
                  style: GoogleFonts.openSans(color: const Color(0xFF8A7E8D)),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Igen',
                  style: GoogleFonts.openSans(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD9BB8A),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('archived_team_boards')
          .add(boardData);
      await FirebaseFirestore.instance
          .collection('team_boards')
          .doc(boardId)
          .delete();
      Navigator.of(context).pop();
    }
  }

  void _showCreateBoardDialog({
    String? boardId,
    Map<String, dynamic>? existingData,
  }) {
    if (existingData != null) {
      _titleController.text = existingData['title'];
      _descriptionController.text = existingData['description'] ?? '';
      _selectedParticipants = List<String>.from(existingData['participants']);
    } else {
      _titleController.clear();
      _descriptionController.clear();
      _selectedParticipants.clear();
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text(
                existingData == null
                    ? 'Új munkatábla létrehozása'
                    : 'Munkatábla szerkesztése',
                style: GoogleFonts.openSans(
                  color: const Color(0xFF8A7E8D),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Munkatábla neve (minimum 3 karakter)',
                      ),
                    ),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Leírás (opcionális, max 800 karakter)',
                      ),
                      maxLength: 800,
                    ),
                    const SizedBox(height: 16),
                    const Text('Résztvevők kiválasztása:'),
                    if (_allUsers.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Nincsenek elérhető felhasználók.',
                          style: GoogleFonts.openSans(
                            color: const Color(0xFF8A7E8D),
                            fontSize: 14,
                          ),
                        ),
                      )
                    else
                      ..._allUsers.map((user) {
                        return CheckboxListTile(
                          title: Text(user),
                          value: _selectedParticipants.contains(user),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedParticipants.add(user);
                              } else {
                                _selectedParticipants.remove(user);
                              }
                            });
                          },
                        );
                      }),
                  ],
                ),
              ),
              actions: [
                if (existingData != null)
                  TextButton(
                    onPressed: () => _archiveTeamBoard(boardId!, existingData),
                    child: Text(
                      'Archiválás',
                      style: GoogleFonts.openSans(color: Colors.red),
                    ),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Mégse',
                    style: GoogleFonts.openSans(color: const Color(0xFF8A7E8D)),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (existingData == null) {
                      _createTeamBoard();
                    } else {
                      _updateTeamBoard(boardId!, existingData);
                    }
                  },
                  child: Text(
                    existingData == null ? 'Létrehozás' : 'Mentés',
                    style: GoogleFonts.openSans(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD9BB8A),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(currentPage: '/team_board'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Közös munkatáblák',
                  style: GoogleFonts.openSans(
                    color: const Color(0xFF8A7E8D),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _showCreateBoardDialog(),
                  child: Text(
                    'Új munkatábla',
                    style: GoogleFonts.openSans(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD9BB8A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('Rendezés: '),
                DropdownButton<String>(
                  value: _sortBy,
                  items: const [
                    DropdownMenuItem(value: 'name', child: Text('Név szerint')),
                    DropdownMenuItem(
                      value: 'lastModified',
                      child: Text('Utolsó módosítás szerint'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value!;
                    });
                  },
                  dropdownColor: Colors.white,
                ),
                IconButton(
                  icon: Icon(
                    _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                    color: const Color(0xFF8A7E8D),
                  ),
                  onPressed: () {
                    setState(() {
                      _sortAscending = !_sortAscending;
                    });
                  },
                ),
              ],
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('team_boards')
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Hiba történt az adatok betöltésekor.'),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final boards = snapshot.data!.docs;
                  boards.sort((a, b) {
                    if (_sortBy == 'name') {
                      return _sortAscending
                          ? a['title'].compareTo(b['title'])
                          : b['title'].compareTo(a['title']);
                    } else {
                      return _sortAscending
                          ? a['lastModified'].compareTo(b['lastModified'])
                          : b['lastModified'].compareTo(a['lastModified']);
                    }
                  });

                  return ListView.builder(
                    itemCount: boards.length,
                    itemBuilder: (context, index) {
                      final board = boards[index];
                      final participants =
                          board['participants'] as List<dynamic>;
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 16.0),
                        color: Colors.white,
                        child: ListTile(
                          title: InkWell(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/team_board_details',
                                arguments: board.id,
                              );
                            },
                            child: Text(
                              board['title'],
                              style: GoogleFonts.openSans(
                                color: const Color(0xFFD9BB8A), // Arany szín
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                board['description'] ?? '',
                                style: GoogleFonts.openSans(
                                  color: const Color(0xFF8A7E8D),
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Résztvevők (${participants.length}): ${participants.join(', ')}',
                                style: GoogleFonts.openSans(
                                  color: const Color(0xFF8A7E8D),
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Utolsó módosítás: ${board['lastModified'].toDate().toString().substring(0, 16)}',
                                style: GoogleFonts.openSans(
                                  color: const Color(0xFF8A7E8D),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Color(0xFF8A7E8D),
                                ),
                                onPressed: () {
                                  _showCreateBoardDialog(
                                    boardId: board.id,
                                    existingData:
                                        board.data() as Map<String, dynamic>,
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_forward,
                                  color: Color(0xFFD9BB8A),
                                ),
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/team_board_details',
                                    arguments: board.id,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
