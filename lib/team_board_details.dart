import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'header.dart';

class TeamBoardDetailsPage extends StatefulWidget {
  const TeamBoardDetailsPage({super.key});

  @override
  State<TeamBoardDetailsPage> createState() => _TeamBoardDetailsPageState();
}

class Subtask {
  final String id;
  final String title;
  final bool completed;
  final String? completedBy;
  final Timestamp? completedAt;

  Subtask({
    required this.id,
    required this.title,
    required this.completed,
    this.completedBy,
    this.completedAt,
  });

  factory Subtask.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Subtask(
      id: doc.id,
      title: data['title'] as String,
      completed: data['completed'] as bool,
      completedBy: data['completedBy'] as String?,
      completedAt: data['completedAt'] as Timestamp?,
    );
  }
}

class Message {
  final String userEmail;
  final String message;
  final Timestamp timestamp;

  Message({
    required this.userEmail,
    required this.message,
    required this.timestamp,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      userEmail: data['userEmail'] as String,
      message: data['message'] as String,
      timestamp: data['timestamp'] as Timestamp,
    );
  }
}

class AttachedFile {
  final String fileName;
  final int size;
  final String? description;
  final String uploadedBy;
  final Timestamp uploadedAt;

  AttachedFile({
    required this.fileName,
    required this.size,
    this.description,
    required this.uploadedBy,
    required this.uploadedAt,
  });

  factory AttachedFile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AttachedFile(
      fileName: data['fileName'] as String,
      size: data['size'] as int,
      description: data['description'] as String?,
      uploadedBy: data['uploadedBy'] as String,
      uploadedAt: data['uploadedAt'] as Timestamp,
    );
  }
}

class Task {
  final String id;
  final String title;
  final String? description;
  final List<String> participants;
  final String priority;
  final Timestamp deadline;
  final bool completed;
  final String? completedBy;
  final Timestamp? completedAt;
  final List<Subtask> subtasks;
  final List<Message> messages;
  final List<AttachedFile> files;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.participants,
    required this.priority,
    required this.deadline,
    required this.completed,
    this.completedBy,
    this.completedAt,
    required this.subtasks,
    required this.messages,
    required this.files,
  });

  factory Task.fromFirestore(
    DocumentSnapshot doc,
    List<Subtask> subtasks,
    List<Message> messages,
    List<AttachedFile> files,
  ) {
    final data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      title: data['title'] as String,
      description: data['description'] as String?,
      participants: List<String>.from(data['participants']),
      priority: data['priority'] as String,
      deadline: data['deadline'] as Timestamp,
      completed: data['completed'] as bool,
      completedBy: data['completedBy'] as String?,
      completedAt: data['completedAt'] as Timestamp?,
      subtasks: subtasks,
      messages: messages,
      files: files,
    );
  }
}

class _TeamBoardDetailsPageState extends State<TeamBoardDetailsPage> {
  late String boardId;
  List<Task> tasks = [];
  List<String> _allUsers = [];
  String _sortBy = 'name';
  bool _sortAscending = true;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _subtaskController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _fileDescriptionController =
      TextEditingController();
  List<String> _selectedParticipants = [];
  String? _selectedPriority;
  DateTime? _selectedDeadline;
  TimeOfDay? _selectedTime;
  List<Subtask> _currentSubtasks = [];
  List<Message> _currentMessages = [];
  List<AttachedFile> _currentFiles = [];
  bool _isCompleted = false;
  bool _isArchived = false;
  String? _completedBy;
  Timestamp? _completedAt;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    boardId = ModalRoute.of(context)!.settings.arguments as String;
    _fetchUsers();
    _fetchTasks();
  }

  Future<void> _fetchUsers() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    setState(() {
      _allUsers = snapshot.docs.map((doc) => doc['email'] as String).toList();
    });
  }

  void _fetchTasks() {
    FirebaseFirestore.instance
        .collection('team_boards')
        .doc(boardId)
        .collection('tasks')
        .snapshots()
        .listen((snapshot) async {
          final List<Task> allTasks = [];
          for (var doc in snapshot.docs) {
            final subtasksSnapshot =
                await FirebaseFirestore.instance
                    .collection('team_boards')
                    .doc(boardId)
                    .collection('tasks')
                    .doc(doc.id)
                    .collection('subtasks')
                    .get();
            final messagesSnapshot =
                await FirebaseFirestore.instance
                    .collection('team_boards')
                    .doc(boardId)
                    .collection('tasks')
                    .doc(doc.id)
                    .collection('messages')
                    .get();
            final filesSnapshot =
                await FirebaseFirestore.instance
                    .collection('team_boards')
                    .doc(boardId)
                    .collection('tasks')
                    .doc(doc.id)
                    .collection('files')
                    .get();
            final subtasks =
                subtasksSnapshot.docs
                    .map((subDoc) => Subtask.fromFirestore(subDoc))
                    .toList();
            final messages =
                messagesSnapshot.docs
                    .map((msgDoc) => Message.fromFirestore(msgDoc))
                    .toList();
            final files =
                filesSnapshot.docs
                    .map((fileDoc) => AttachedFile.fromFirestore(fileDoc))
                    .toList();
            allTasks.add(Task.fromFirestore(doc, subtasks, messages, files));
          }

          allTasks.sort((a, b) {
            if (_sortBy == 'name') {
              return _sortAscending
                  ? a.title.compareTo(b.title)
                  : b.title.compareTo(a.title);
            } else if (_sortBy == 'priority') {
              const priorityOrder = {'high': 1, 'medium': 2, 'low': 3};
              return _sortAscending
                  ? priorityOrder[a.priority]!.compareTo(
                    priorityOrder[b.priority]!,
                  )
                  : priorityOrder[b.priority]!.compareTo(
                    priorityOrder[a.priority]!,
                  );
            } else {
              return _sortAscending
                  ? a.deadline.compareTo(b.deadline)
                  : b.deadline.compareTo(a.deadline);
            }
          });

          setState(() {
            tasks = allTasks;
          });
        });
  }

  Future<void> _createTask() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('A feladat neve kötelező!')));
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
    if (_selectedPriority == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Válassz prioritást!')));
      return;
    }
    if (_selectedDeadline == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Válassz határidőt (dátum, óra, perc)!')),
      );
      return;
    }

    final deadline = DateTime(
      _selectedDeadline!.year,
      _selectedDeadline!.month,
      _selectedDeadline!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final taskRef = await FirebaseFirestore.instance
        .collection('team_boards')
        .doc(boardId)
        .collection('tasks')
        .add({
          'title': _titleController.text,
          'description':
              _descriptionController.text.isNotEmpty
                  ? _descriptionController.text
                  : null,
          'participants': _selectedParticipants,
          'priority': _selectedPriority,
          'deadline': Timestamp.fromDate(deadline),
          'completed': false,
        });

    for (var subtask in _currentSubtasks) {
      await FirebaseFirestore.instance
          .collection('team_boards')
          .doc(boardId)
          .collection('tasks')
          .doc(taskRef.id)
          .collection('subtasks')
          .add({'title': subtask.title, 'completed': subtask.completed});
    }

    for (var message in _currentMessages) {
      await FirebaseFirestore.instance
          .collection('team_boards')
          .doc(boardId)
          .collection('tasks')
          .doc(taskRef.id)
          .collection('messages')
          .add({
            'userEmail': message.userEmail,
            'message': message.message,
            'timestamp': message.timestamp,
          });
    }

    for (var file in _currentFiles) {
      await FirebaseFirestore.instance
          .collection('team_boards')
          .doc(boardId)
          .collection('tasks')
          .doc(taskRef.id)
          .collection('files')
          .add({
            'fileName': file.fileName,
            'size': file.size,
            'description': file.description,
            'uploadedBy': file.uploadedBy,
            'uploadedAt': file.uploadedAt,
          });
    }

    _resetForm();
    Navigator.of(context).pop();
  }

  Future<void> _updateTask(Task task) async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('A feladat neve kötelező!')));
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
    if (_selectedPriority == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Válassz prioritást!')));
      return;
    }
    if (_selectedDeadline == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Válassz határidőt (dátum, óra, perc)!')),
      );
      return;
    }

    final deadline = DateTime(
      _selectedDeadline!.year,
      _selectedDeadline!.month,
      _selectedDeadline!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final taskRef = FirebaseFirestore.instance
        .collection('team_boards')
        .doc(boardId)
        .collection('tasks')
        .doc(task.id);

    await taskRef.update({
      'title': _titleController.text,
      'description':
          _descriptionController.text.isNotEmpty
              ? _descriptionController.text
              : null,
      'participants': _selectedParticipants,
      'priority': _selectedPriority,
      'deadline': Timestamp.fromDate(deadline),
      'completed': _isCompleted,
      if (_isCompleted && _completedBy != null && _completedAt != null)
        'completedBy': _completedBy,
      if (_isCompleted && _completedAt != null) 'completedAt': _completedAt,
    });

    final subtaskCollection = taskRef.collection('subtasks');
    final existingSubtasks = await subtaskCollection.get();
    for (var subtask in existingSubtasks.docs) {
      await subtask.reference.delete();
    }
    for (var subtask in _currentSubtasks) {
      await subtaskCollection.add({
        'title': subtask.title,
        'completed': subtask.completed,
        if (subtask.completed && subtask.completedBy != null)
          'completedBy': subtask.completedBy,
        if (subtask.completed && subtask.completedAt != null)
          'completedAt': subtask.completedAt,
      });
    }

    final messageCollection = taskRef.collection('messages');
    final existingMessages = await messageCollection.get();
    for (var message in existingMessages.docs) {
      await message.reference.delete();
    }
    for (var message in _currentMessages) {
      await messageCollection.add({
        'userEmail': message.userEmail,
        'message': message.message,
        'timestamp': message.timestamp,
      });
    }

    final fileCollection = taskRef.collection('files');
    final existingFiles = await fileCollection.get();
    for (var file in existingFiles.docs) {
      await file.reference.delete();
    }
    for (var file in _currentFiles) {
      await fileCollection.add({
        'fileName': file.fileName,
        'size': file.size,
        'description': file.description,
        'uploadedBy': file.uploadedBy,
        'uploadedAt': file.uploadedAt,
      });
    }

    if (_isArchived) {
      final taskData = (await taskRef.get()).data() as Map<String, dynamic>;
      await FirebaseFirestore.instance
          .collection('archived_tasks')
          .add(taskData);
      await taskRef.delete();
    }

    _resetForm();
    Navigator.of(context).pop();
  }

  Future<void> _updateSubtask(
    String taskId,
    Subtask subtask,
    bool newValue,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    await FirebaseFirestore.instance
        .collection('team_boards')
        .doc(boardId)
        .collection('tasks')
        .doc(taskId)
        .collection('subtasks')
        .doc(subtask.id)
        .update({
          'completed': newValue,
          if (newValue) 'completedBy': currentUser.email,
          if (newValue) 'completedAt': Timestamp.now(),
        });
  }

  Future<void> _archiveTask(Task task) async {
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
              'Biztos, hogy archiválod a feladatot?',
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
      final taskData =
          (await FirebaseFirestore.instance
                      .collection('team_boards')
                      .doc(boardId)
                      .collection('tasks')
                      .doc(task.id)
                      .get())
                  .data()
              as Map<String, dynamic>;
      await FirebaseFirestore.instance
          .collection('archived_tasks')
          .add(taskData);
      await FirebaseFirestore.instance
          .collection('team_boards')
          .doc(boardId)
          .collection('tasks')
          .doc(task.id)
          .delete();
    }
  }

  void _resetForm() {
    _titleController.clear();
    _descriptionController.clear();
    _subtaskController.clear();
    _messageController.clear();
    _fileDescriptionController.clear();
    _selectedParticipants.clear();
    _selectedPriority = null;
    _selectedDeadline = null;
    _selectedTime = null;
    _currentSubtasks.clear();
    _currentMessages.clear();
    _currentFiles.clear();
    _isCompleted = false;
    _isArchived = false;
    _completedBy = null;
    _completedAt = null;
  }

  String _getPriorityText(String priority) {
    const Map<String, String> priorityMap = {
      'high': 'Magas',
      'medium': 'Közepes',
      'low': 'Alacsony',
    };
    return priorityMap[priority] ?? priority;
  }

  void _showTaskDialog({
    Task? task,
    Subtask? subtask,
    bool isSubtask = false,
    String? parentTaskId,
  }) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    bool canEdit = true;
    if (task != null) {
      canEdit =
          task.participants.contains(currentUser.email) ||
          currentUser.email == 'superadmin@retorki.hu';
    } else if (subtask != null) {
      canEdit =
          true; // Mivel a részfeladat szerkesztését mindenki végezheti, aki a szülő feladathoz hozzáfér
    }

    if (isSubtask && subtask != null) {
      _titleController.text = subtask.title;
      _isCompleted = subtask.completed;
      _completedBy = subtask.completedBy;
      _completedAt = subtask.completedAt;
    } else if (task != null) {
      _titleController.text = task.title;
      _descriptionController.text = task.description ?? '';
      _selectedParticipants = List.from(task.participants);
      _selectedPriority = task.priority;
      final deadline = task.deadline.toDate();
      _selectedDeadline = deadline;
      _selectedTime = TimeOfDay(hour: deadline.hour, minute: deadline.minute);
      _currentSubtasks = List.from(task.subtasks);
      _currentMessages = List.from(task.messages);
      _currentFiles = List.from(task.files);
      _isCompleted = task.completed;
      _isArchived = false;
      _completedBy = task.completedBy;
      _completedAt = task.completedAt;
    } else {
      _resetForm();
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text(
                isSubtask
                    ? (subtask == null
                        ? 'Új részfeladat'
                        : 'Részfeladat szerkesztése')
                    : (task == null ? 'Új feladat' : 'Feladat szerkesztése'),
                style: GoogleFonts.openSans(
                  color: const Color(0xFF8A7E8D),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.8,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isSubtask) ...[
                        TextField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Feladat neve (kötelező)',
                          ),
                          enabled: canEdit,
                          style: GoogleFonts.openSans(
                            color:
                                canEdit ? const Color(0xFF8A7E8D) : Colors.grey,
                          ),
                        ),
                        TextField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Leírás (opcionális)',
                          ),
                          maxLength: 800,
                          enabled: canEdit,
                          style: GoogleFonts.openSans(
                            color:
                                canEdit ? const Color(0xFF8A7E8D) : Colors.grey,
                          ),
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
                        else ...[
                          TextButton(
                            onPressed:
                                canEdit
                                    ? () {
                                      List<String> tempSelectedParticipants =
                                          List.from(_selectedParticipants);
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return StatefulBuilder(
                                            builder: (context, dialogSetState) {
                                              return AlertDialog(
                                                backgroundColor: Colors.white,
                                                title: Text(
                                                  'Résztvevők kiválasztása',
                                                  style: GoogleFonts.openSans(
                                                    color: const Color(
                                                      0xFF8A7E8D,
                                                    ),
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                content: Container(
                                                  width:
                                                      MediaQuery.of(
                                                        context,
                                                      ).size.width *
                                                      0.6,
                                                  height:
                                                      MediaQuery.of(
                                                        context,
                                                      ).size.height *
                                                      0.4,
                                                  child: ListView.builder(
                                                    itemCount: _allUsers.length,
                                                    itemBuilder: (
                                                      context,
                                                      index,
                                                    ) {
                                                      final user =
                                                          _allUsers[index];
                                                      return ListTile(
                                                        leading: Checkbox(
                                                          value:
                                                              tempSelectedParticipants
                                                                  .contains(
                                                                    user,
                                                                  ),
                                                          onChanged: (
                                                            bool? value,
                                                          ) {
                                                            dialogSetState(() {
                                                              if (value ==
                                                                  true) {
                                                                if (!tempSelectedParticipants
                                                                    .contains(
                                                                      user,
                                                                    )) {
                                                                  tempSelectedParticipants
                                                                      .add(
                                                                        user,
                                                                      );
                                                                }
                                                              } else {
                                                                tempSelectedParticipants
                                                                    .remove(
                                                                      user,
                                                                    );
                                                              }
                                                            });
                                                          },
                                                          activeColor:
                                                              const Color(
                                                                0xFFD9BB8A,
                                                              ),
                                                          checkColor:
                                                              Colors.white,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  4,
                                                                ),
                                                          ),
                                                        ),
                                                        title: Text(
                                                          user,
                                                          style:
                                                              GoogleFonts.openSans(
                                                                color:
                                                                    const Color(
                                                                      0xFF8A7E8D,
                                                                    ),
                                                                fontSize: 14,
                                                              ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed:
                                                        () =>
                                                            Navigator.of(
                                                              context,
                                                            ).pop(),
                                                    child: Text(
                                                      'Mégse',
                                                      style:
                                                          GoogleFonts.openSans(
                                                            color: const Color(
                                                              0xFF8A7E8D,
                                                            ),
                                                          ),
                                                    ),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        _selectedParticipants =
                                                            tempSelectedParticipants;
                                                      });
                                                      Navigator.of(
                                                        context,
                                                      ).pop();
                                                    },
                                                    child: Text(
                                                      'Mentés',
                                                      style:
                                                          GoogleFonts.openSans(
                                                            color: Colors.white,
                                                          ),
                                                    ),
                                                    style:
                                                        ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              const Color(
                                                                0xFFD9BB8A,
                                                              ),
                                                        ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      );
                                    }
                                    : null,
                            child: Text(
                              'Résztvevők kiválasztása',
                              style: GoogleFonts.openSans(
                                color:
                                    canEdit
                                        ? const Color(0xFF8A7E8D)
                                        : Colors.grey,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8.0,
                            children:
                                _selectedParticipants.map((user) {
                                  return Chip(
                                    label: Text(
                                      user,
                                      style: GoogleFonts.openSans(
                                        color: const Color(0xFF8A7E8D),
                                        fontSize: 14,
                                      ),
                                    ),
                                    onDeleted:
                                        canEdit
                                            ? () {
                                              setState(() {
                                                _selectedParticipants.remove(
                                                  user,
                                                );
                                              });
                                            }
                                            : null,
                                    deleteIconColor:
                                        canEdit ? Colors.red : Colors.grey,
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: const BorderSide(
                                        color: Color(0xFFD9BB8A),
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ],
                        const SizedBox(height: 16),
                        DropdownButton<String>(
                          value: _selectedPriority,
                          hint: const Text('Válassz prioritást'),
                          items: const [
                            DropdownMenuItem(
                              value: 'high',
                              child: Text('Magas'),
                            ),
                            DropdownMenuItem(
                              value: 'medium',
                              child: Text('Közepes'),
                            ),
                            DropdownMenuItem(
                              value: 'low',
                              child: Text('Alacsony'),
                            ),
                          ],
                          onChanged:
                              canEdit
                                  ? (value) {
                                    setState(() {
                                      _selectedPriority = value;
                                    });
                                  }
                                  : null,
                          dropdownColor: Colors.white,
                          style: GoogleFonts.openSans(
                            color:
                                canEdit ? const Color(0xFF8A7E8D) : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            TextButton(
                              onPressed:
                                  canEdit
                                      ? () async {
                                        final pickedDate = await showDatePicker(
                                          context: context,
                                          initialDate: DateTime.now(),
                                          firstDate: DateTime.now(),
                                          lastDate: DateTime(2030),
                                          builder: (context, child) {
                                            return Theme(
                                              data: ThemeData.light().copyWith(
                                                colorScheme:
                                                    const ColorScheme.light(
                                                      primary: Color(
                                                        0xFFD9BB8A,
                                                      ),
                                                      onPrimary: Colors.white,
                                                      surface: Colors.white,
                                                      onSurface: Color(
                                                        0xFF8A7E8D,
                                                      ),
                                                    ),
                                                dialogBackgroundColor:
                                                    Colors.white,
                                              ),
                                              child: child!,
                                            );
                                          },
                                        );
                                        if (pickedDate != null) {
                                          setState(() {
                                            _selectedDeadline = pickedDate;
                                          });
                                        }
                                      }
                                      : null,
                              child: Text(
                                _selectedDeadline == null
                                    ? 'Válassz dátumot'
                                    : 'Dátum: ${_selectedDeadline!.toString().substring(0, 10)}',
                                style: GoogleFonts.openSans(
                                  color:
                                      canEdit
                                          ? const Color(0xFF8A7E8D)
                                          : Colors.grey,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            TextButton(
                              onPressed:
                                  canEdit
                                      ? () async {
                                        final pickedTime = await showTimePicker(
                                          context: context,
                                          initialTime: TimeOfDay.now(),
                                          builder: (context, child) {
                                            return Theme(
                                              data: ThemeData.light().copyWith(
                                                colorScheme:
                                                    const ColorScheme.light(
                                                      primary: Color(
                                                        0xFFD9BB8A,
                                                      ),
                                                      onPrimary: Colors.white,
                                                      surface: Colors.white,
                                                      onSurface: Color(
                                                        0xFF8A7E8D,
                                                      ),
                                                    ),
                                                dialogBackgroundColor:
                                                    Colors.white,
                                              ),
                                              child: child!,
                                            );
                                          },
                                        );
                                        if (pickedTime != null) {
                                          setState(() {
                                            _selectedTime = pickedTime;
                                          });
                                        }
                                      }
                                      : null,
                              child: Text(
                                _selectedTime == null
                                    ? 'Válassz időt'
                                    : 'Idő: ${_selectedTime!.format(context)}',
                                style: GoogleFonts.openSans(
                                  color:
                                      canEdit
                                          ? const Color(0xFF8A7E8D)
                                          : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text('Részfeladatok:'),
                        ..._currentSubtasks.asMap().entries.map((entry) {
                          final index = entry.key;
                          final subtask = entry.value;
                          return Row(
                            children: [
                              Checkbox(
                                value: subtask.completed,
                                onChanged:
                                    canEdit
                                        ? (value) {
                                          setState(() {
                                            _currentSubtasks[index] = Subtask(
                                              id: subtask.id,
                                              title: subtask.title,
                                              completed: value!,
                                              completedBy:
                                                  value
                                                      ? currentUser.email
                                                      : null,
                                              completedAt:
                                                  value
                                                      ? Timestamp.now()
                                                      : null,
                                            );
                                          });
                                        }
                                        : null,
                                activeColor: const Color(0xFFD9BB8A),
                                checkColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  subtask.title,
                                  style: GoogleFonts.openSans(
                                    color: const Color(0xFF8A7E8D),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Color(0xFF8A7E8D),
                                ),
                                onPressed:
                                    canEdit
                                        ? () {
                                          _subtaskController.text =
                                              subtask.title;
                                          showDialog(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                backgroundColor: Colors.white,
                                                title: Text(
                                                  'Részfeladat szerkesztése',
                                                  style: GoogleFonts.openSans(
                                                    color: const Color(
                                                      0xFF8A7E8D,
                                                    ),
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                content: TextField(
                                                  controller:
                                                      _subtaskController,
                                                  decoration: const InputDecoration(
                                                    labelText:
                                                        'Részfeladat neve (max 50 karakter)',
                                                  ),
                                                  maxLength: 50,
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed:
                                                        () =>
                                                            Navigator.of(
                                                              context,
                                                            ).pop(),
                                                    child: Text(
                                                      'Mégse',
                                                      style:
                                                          GoogleFonts.openSans(
                                                            color: const Color(
                                                              0xFF8A7E8D,
                                                            ),
                                                          ),
                                                    ),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      if (_subtaskController
                                                          .text
                                                          .isNotEmpty) {
                                                        setState(() {
                                                          _currentSubtasks[index] = Subtask(
                                                            id: subtask.id,
                                                            title:
                                                                _subtaskController
                                                                    .text,
                                                            completed:
                                                                subtask
                                                                    .completed,
                                                            completedBy:
                                                                subtask
                                                                    .completedBy,
                                                            completedAt:
                                                                subtask
                                                                    .completedAt,
                                                          );
                                                        });
                                                        Navigator.of(
                                                          context,
                                                        ).pop();
                                                      }
                                                    },
                                                    child: Text(
                                                      'Mentés',
                                                      style:
                                                          GoogleFonts.openSans(
                                                            color: Colors.white,
                                                          ),
                                                    ),
                                                    style:
                                                        ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              const Color(
                                                                0xFFD9BB8A,
                                                              ),
                                                        ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        }
                                        : null,
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed:
                                    canEdit
                                        ? () {
                                          setState(() {
                                            _currentSubtasks.removeAt(index);
                                          });
                                        }
                                        : null,
                              ),
                            ],
                          );
                        }),
                        TextButton(
                          onPressed:
                              canEdit
                                  ? () {
                                    _subtaskController.clear();
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          backgroundColor: Colors.white,
                                          title: Text(
                                            'Új részfeladat',
                                            style: GoogleFonts.openSans(
                                              color: const Color(0xFF8A7E8D),
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          content: TextField(
                                            controller: _subtaskController,
                                            decoration: const InputDecoration(
                                              labelText:
                                                  'Részfeladat neve (max 50 karakter)',
                                            ),
                                            maxLength: 50,
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () =>
                                                      Navigator.of(
                                                        context,
                                                      ).pop(),
                                              child: Text(
                                                'Mégse',
                                                style: GoogleFonts.openSans(
                                                  color: const Color(
                                                    0xFF8A7E8D,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                if (_subtaskController
                                                    .text
                                                    .isNotEmpty) {
                                                  setState(() {
                                                    _currentSubtasks.add(
                                                      Subtask(
                                                        id:
                                                            DateTime.now()
                                                                .toString(),
                                                        title:
                                                            _subtaskController
                                                                .text,
                                                        completed: false,
                                                      ),
                                                    );
                                                  });
                                                  Navigator.of(context).pop();
                                                }
                                              },
                                              child: Text(
                                                'Hozzáadás',
                                                style: GoogleFonts.openSans(
                                                  color: Colors.white,
                                                ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(
                                                  0xFFD9BB8A,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  }
                                  : null,
                          child: Text(
                            'Új részfeladat hozzáadása',
                            style: GoogleFonts.openSans(
                              color:
                                  canEdit
                                      ? const Color(0xFF8A7E8D)
                                      : Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('Beszélgetés:'),
                        ..._currentMessages.asMap().entries.map((entry) {
                          final index = entry.key;
                          final message = entry.value;
                          final isFirstMessage = index == 0;
                          final backgroundColor =
                              isFirstMessage
                                  ? const Color(0xFF666666)
                                  : (index % 2 == 0
                                      ? const Color(0xFF999999)
                                      : const Color(0xFFB3B3B3));
                          final RegExp linkRegExp = RegExp(r'(https?://\S+)');
                          final RegExp emailRegExp = RegExp(
                            r'([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})',
                          );
                          final List<TextSpan> textSpans = [];
                          String messageText = message.message;

                          int lastIndex = 0;
                          final allMatches = [
                            ...linkRegExp.allMatches(messageText),
                            ...emailRegExp.allMatches(messageText),
                          ]..sort((a, b) => a.start.compareTo(b.start));

                          for (var match in allMatches) {
                            if (match.start > lastIndex) {
                              textSpans.add(
                                TextSpan(
                                  text: messageText.substring(
                                    lastIndex,
                                    match.start,
                                  ),
                                  style: GoogleFonts.openSans(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              );
                            }
                            if (linkRegExp.hasMatch(match.group(0)!)) {
                              textSpans.add(
                                TextSpan(
                                  text: match.group(0),
                                  style: GoogleFonts.openSans(
                                    color: Colors.blue,
                                    fontSize: 14,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer:
                                      TapGestureRecognizer()
                                        ..onTap = () async {
                                          final url = match.group(0)!;
                                          if (await canLaunchUrl(
                                            Uri.parse(url),
                                          )) {
                                            await launchUrl(Uri.parse(url));
                                          }
                                        },
                                ),
                              );
                            } else if (emailRegExp.hasMatch(match.group(0)!)) {
                              textSpans.add(
                                TextSpan(
                                  text: match.group(0),
                                  style: GoogleFonts.openSans(
                                    color: Colors.blue,
                                    fontSize: 14,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer:
                                      TapGestureRecognizer()
                                        ..onTap = () async {
                                          final email = match.group(0)!;
                                          final url = 'mailto:$email';
                                          if (await canLaunchUrl(
                                            Uri.parse(url),
                                          )) {
                                            await launchUrl(Uri.parse(url));
                                          }
                                        },
                                ),
                              );
                            }
                            lastIndex = match.end;
                          }

                          if (lastIndex < messageText.length) {
                            textSpans.add(
                              TextSpan(
                                text: messageText.substring(lastIndex),
                                style: GoogleFonts.openSans(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            );
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8.0),
                            padding: const EdgeInsets.all(8.0),
                            color: backgroundColor,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${message.userEmail} bejegyzése, ${DateFormat('yyyy. MM. dd. HH:mm', 'hu').format(message.timestamp.toDate())}',
                                  style: GoogleFonts.openSans(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                RichText(text: TextSpan(children: textSpans)),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                decoration: const InputDecoration(
                                  labelText: 'Új hozzászólás',
                                ),
                                enabled: canEdit,
                                style: GoogleFonts.openSans(
                                  color:
                                      canEdit
                                          ? const Color(0xFF8A7E8D)
                                          : Colors.grey,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.send,
                                color: Color(0xFFD9BB8A),
                              ),
                              onPressed:
                                  canEdit
                                      ? () {
                                        if (_messageController
                                            .text
                                            .isNotEmpty) {
                                          setState(() {
                                            _currentMessages.add(
                                              Message(
                                                userEmail: currentUser.email!,
                                                message:
                                                    _messageController.text,
                                                timestamp: Timestamp.now(),
                                              ),
                                            );
                                            _messageController.clear();
                                          });
                                        }
                                      }
                                      : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text('Fájlok:'),
                        ..._currentFiles.map((file) {
                          return ListTile(
                            title: Text(
                              file.fileName,
                              style: GoogleFonts.openSans(
                                color: const Color(0xFF8A7E8D),
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Méret: ${(file.size / 1024 / 1024).toStringAsFixed(2)} MB',
                                  style: GoogleFonts.openSans(
                                    color: const Color(0xFF8A7E8D),
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'Feltöltötte: ${file.uploadedBy}, ${DateFormat('yyyy. MM. dd. HH:mm', 'hu').format(file.uploadedAt.toDate())}',
                                  style: GoogleFonts.openSans(
                                    color: const Color(0xFF8A7E8D),
                                    fontSize: 12,
                                  ),
                                ),
                                if (file.description != null)
                                  Text(
                                    'Leírás: ${file.description}',
                                    style: GoogleFonts.openSans(
                                      color: const Color(0xFF8A7E8D),
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed:
                                  canEdit
                                      ? () {
                                        setState(() {
                                          _currentFiles.remove(file);
                                        });
                                      }
                                      : null,
                            ),
                          );
                        }),
                        TextButton(
                          onPressed:
                              canEdit
                                  ? () {
                                    // Mock fájl feltöltés (valódi fájlkezelés később)
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          backgroundColor: Colors.white,
                                          title: Text(
                                            'Fájl csatolása',
                                            style: GoogleFonts.openSans(
                                              color: const Color(0xFF8A7E8D),
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text(
                                                'Mock fájl: 10 MB (valódi fájlkezelés később)',
                                              ),
                                              TextField(
                                                controller:
                                                    _fileDescriptionController,
                                                decoration: const InputDecoration(
                                                  labelText:
                                                      'Leírás (opcionális, max 250 karakter)',
                                                ),
                                                maxLength: 250,
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () =>
                                                      Navigator.of(
                                                        context,
                                                      ).pop(),
                                              child: Text(
                                                'Mégse',
                                                style: GoogleFonts.openSans(
                                                  color: const Color(
                                                    0xFF8A7E8D,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                const fileSize =
                                                    10 * 1024 * 1024; // 10 MB
                                                if (fileSize >
                                                    40 * 1024 * 1024) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'A fájl mérete maximum 40 MB lehet!',
                                                      ),
                                                    ),
                                                  );
                                                  return;
                                                }
                                                setState(() {
                                                  _currentFiles.add(
                                                    AttachedFile(
                                                      fileName:
                                                          'mock_file_${DateTime.now().millisecondsSinceEpoch}.txt',
                                                      size: fileSize,
                                                      description:
                                                          _fileDescriptionController
                                                                  .text
                                                                  .isNotEmpty
                                                              ? _fileDescriptionController
                                                                  .text
                                                              : null,
                                                      uploadedBy:
                                                          currentUser.email!,
                                                      uploadedAt:
                                                          Timestamp.now(),
                                                    ),
                                                  );
                                                });
                                                _fileDescriptionController
                                                    .clear();
                                                Navigator.of(context).pop();
                                              },
                                              child: Text(
                                                'Feltöltés',
                                                style: GoogleFonts.openSans(
                                                  color: Colors.white,
                                                ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(
                                                  0xFFD9BB8A,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  }
                                  : null,
                          child: Text(
                            'Fájl csatolása (max 40 MB)',
                            style: GoogleFonts.openSans(
                              color:
                                  canEdit
                                      ? const Color(0xFF8A7E8D)
                                      : Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Checkbox(
                              value: _isCompleted,
                              onChanged:
                                  canEdit
                                      ? (value) {
                                        setState(() {
                                          _isCompleted = value!;
                                          if (value) {
                                            _completedBy = currentUser.email;
                                            _completedAt = Timestamp.now();
                                          } else {
                                            _completedBy = null;
                                            _completedAt = null;
                                          }
                                        });
                                      }
                                      : null,
                              activeColor: const Color(0xFFD9BB8A),
                              checkColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            Text(
                              'Teljesítve${_completedBy != null ? ' ($_completedBy, ${DateFormat('yyyy. MM. dd. HH:mm', 'hu').format(_completedAt!.toDate())})' : ''}',
                              style: TextStyle(
                                fontFamily: GoogleFonts.openSans().fontFamily,
                                color:
                                    canEdit
                                        ? const Color(0xFF8A7E8D)
                                        : Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        if (!isSubtask)
                          Row(
                            children: [
                              Checkbox(
                                value: _isArchived,
                                onChanged:
                                    canEdit
                                        ? (value) {
                                          setState(() {
                                            _isArchived = value!;
                                          });
                                        }
                                        : null,
                                activeColor: const Color(0xFFD9BB8A),
                                checkColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              Text(
                                'Archiválás',
                                style: GoogleFonts.openSans(
                                  color:
                                      canEdit
                                          ? const Color(0xFF8A7E8D)
                                          : Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                      ] else ...[
                        TextField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Részfeladat neve (kötelező)',
                          ),
                          enabled: canEdit,
                          style: GoogleFonts.openSans(
                            color:
                                canEdit ? const Color(0xFF8A7E8D) : Colors.grey,
                          ),
                        ),
                        Row(
                          children: [
                            Checkbox(
                              value: _isCompleted,
                              onChanged:
                                  canEdit
                                      ? (value) {
                                        setState(() {
                                          _isCompleted = value!;
                                          if (value) {
                                            _completedBy = currentUser.email;
                                            _completedAt = Timestamp.now();
                                          } else {
                                            _completedBy = null;
                                            _completedAt = null;
                                          }
                                        });
                                      }
                                      : null,
                              activeColor: const Color(0xFFD9BB8A),
                              checkColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            Text(
                              'Teljesítve${_completedBy != null ? ' ($_completedBy, ${DateFormat('yyyy. MM. dd. HH:mm', 'hu').format(_completedAt!.toDate())})' : ''}',
                              style: TextStyle(
                                fontFamily: GoogleFonts.openSans().fontFamily,
                                color:
                                    canEdit
                                        ? const Color(0xFF8A7E8D)
                                        : Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    bool confirm = await showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            backgroundColor: Colors.white,
                            title: Text(
                              'Megerősítés',
                              style: GoogleFonts.openSans(
                                color: const Color(0xFF8A7E8D),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            content: Text(
                              'Biztos, hogy mentés nélkül szeretnéd bezárni az ablakot?',
                              style: GoogleFonts.openSans(
                                color: const Color(0xFF8A7E8D),
                                fontSize: 16,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed:
                                    () => Navigator.of(context).pop(false),
                                child: Text(
                                  'Nem',
                                  style: GoogleFonts.openSans(
                                    color: const Color(0xFF8A7E8D),
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed:
                                    () => Navigator.of(context).pop(true),
                                child: Text(
                                  'Igen',
                                  style: GoogleFonts.openSans(
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD9BB8A),
                                ),
                              ),
                            ],
                          ),
                    );
                    if (confirm == true) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(
                    'Mégse',
                    style: GoogleFonts.openSans(color: const Color(0xFF8A7E8D)),
                  ),
                ),
                ElevatedButton(
                  onPressed:
                      canEdit
                          ? () {
                            if (isSubtask && subtask == null) {
                              if (_titleController.text.isNotEmpty) {
                                setState(() {
                                  _currentSubtasks.add(
                                    Subtask(
                                      id: DateTime.now().toString(),
                                      title: _titleController.text,
                                      completed: false,
                                    ),
                                  );
                                });
                                Navigator.of(context).pop();
                              }
                            } else if (isSubtask &&
                                subtask != null &&
                                parentTaskId != null) {
                              _updateSubtask(
                                parentTaskId,
                                subtask,
                                _isCompleted,
                              );
                              Navigator.of(context).pop();
                            } else if (task == null) {
                              _createTask();
                            } else {
                              _updateTask(task);
                            }
                          }
                          : null,
                  child: Text(
                    'Mentés',
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
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('team_boards')
                .doc(boardId)
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

          final boardData = snapshot.data!.data() as Map<String, dynamic>;
          final boardTitle = boardData['title'] as String;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  boardTitle,
                  style: GoogleFonts.openSans(
                    color: const Color(0xFF8A7E8D),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () => _showTaskDialog(),
                      child: Text(
                        'Új feladat',
                        style: GoogleFonts.openSans(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD9BB8A),
                      ),
                    ),
                    Row(
                      children: [
                        const Text('Rendezés: '),
                        DropdownButton<String>(
                          value: _sortBy,
                          items: const [
                            DropdownMenuItem(
                              value: 'name',
                              child: Text('Betűrendes'),
                            ),
                            DropdownMenuItem(
                              value: 'priority',
                              child: Text('Prioritás szerint'),
                            ),
                            DropdownMenuItem(
                              value: 'deadline',
                              child: Text('Határidő szerint'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _sortBy = value!;
                            });
                          },
                          dropdownColor: Colors.white,
                          style: GoogleFonts.openSans(
                            color: const Color(0xFF8A7E8D),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _sortAscending
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
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
                  ],
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      final currentUser = FirebaseAuth.instance.currentUser;
                      final canEdit =
                          task.participants.contains(currentUser?.email) ||
                          currentUser?.email == 'superadmin@retorki.hu';
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 16.0),
                        color: Colors.white,
                        child: ExpansionTile(
                          title: Text(
                            task.title,
                            style: GoogleFonts.openSans(
                              color: const Color(0xFF8A7E8D),
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              decoration:
                                  task.completed
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                            ),
                          ),
                          subtitle: Text(
                            'Prioritás: ${_getPriorityText(task.priority)}, Határidő: ${DateFormat('yyyy. MM. dd. HH:mm', 'hu').format(task.deadline.toDate())}, '
                            'Teljesítve: ${task.completed ? 'Igen (${task.completedBy}, ${task.completedAt != null ? DateFormat('yyyy. MM. dd. HH:mm', 'hu').format(task.completedAt!.toDate()) : ''})' : 'Nem'}',
                            style: GoogleFonts.openSans(
                              color: const Color(0xFF8A7E8D),
                              fontSize: 14,
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (task.description != null)
                                    Text(
                                      'Leírás: ${task.description}',
                                      style: GoogleFonts.openSans(
                                        color: const Color(0xFF8A7E8D),
                                        fontSize: 14,
                                      ),
                                    ),
                                  Text(
                                    'Résztvevők (${task.participants.length}): ${task.participants.join(', ')}',
                                    style: GoogleFonts.openSans(
                                      color: const Color(0xFF8A7E8D),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text('Részfeladatok:'),
                                  ...task.subtasks.map((subtask) {
                                    return Row(
                                      children: [
                                        Checkbox(
                                          value: subtask.completed,
                                          onChanged:
                                              canEdit
                                                  ? (value) {
                                                    _updateSubtask(
                                                      task.id,
                                                      subtask,
                                                      value!,
                                                    );
                                                  }
                                                  : null,
                                          activeColor: const Color(0xFFD9BB8A),
                                          checkColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            subtask.title,
                                            style: GoogleFonts.openSans(
                                              color: const Color(0xFF8A7E8D),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Color(0xFF8A7E8D),
                                          ),
                                          onPressed:
                                              canEdit
                                                  ? () {
                                                    _showTaskDialog(
                                                      subtask: subtask,
                                                      isSubtask: true,
                                                      parentTaskId: task.id,
                                                    );
                                                  }
                                                  : null,
                                        ),
                                      ],
                                    );
                                  }),
                                  const SizedBox(height: 16),
                                  const Text('Beszélgetés:'),
                                  ...task.messages.map((message) {
                                    final isFirstMessage =
                                        task.messages.indexOf(message) == 0;
                                    final backgroundColor =
                                        isFirstMessage
                                            ? const Color(0xFF666666)
                                            : (task.messages.indexOf(message) %
                                                        2 ==
                                                    0
                                                ? const Color(0xFF999999)
                                                : const Color(0xFFB3B3B3));
                                    final RegExp linkRegExp = RegExp(
                                      r'(https?://\S+)',
                                    );
                                    final RegExp emailRegExp = RegExp(
                                      r'([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})',
                                    );
                                    final List<TextSpan> textSpans = [];
                                    String messageText = message.message;

                                    int lastIndex = 0;
                                    final allMatches = [
                                      ...linkRegExp.allMatches(messageText),
                                      ...emailRegExp.allMatches(messageText),
                                    ]..sort(
                                      (a, b) => a.start.compareTo(b.start),
                                    );

                                    for (var match in allMatches) {
                                      if (match.start > lastIndex) {
                                        textSpans.add(
                                          TextSpan(
                                            text: messageText.substring(
                                              lastIndex,
                                              match.start,
                                            ),
                                            style: GoogleFonts.openSans(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                        );
                                      }
                                      if (linkRegExp.hasMatch(
                                        match.group(0)!,
                                      )) {
                                        textSpans.add(
                                          TextSpan(
                                            text: match.group(0),
                                            style: GoogleFonts.openSans(
                                              color: Colors.blue,
                                              fontSize: 14,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                            recognizer:
                                                TapGestureRecognizer()
                                                  ..onTap = () async {
                                                    final url = match.group(0)!;
                                                    if (await canLaunchUrl(
                                                      Uri.parse(url),
                                                    )) {
                                                      await launchUrl(
                                                        Uri.parse(url),
                                                      );
                                                    }
                                                  },
                                          ),
                                        );
                                      } else if (emailRegExp.hasMatch(
                                        match.group(0)!,
                                      )) {
                                        textSpans.add(
                                          TextSpan(
                                            text: match.group(0),
                                            style: GoogleFonts.openSans(
                                              color: Colors.blue,
                                              fontSize: 14,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                            recognizer:
                                                TapGestureRecognizer()
                                                  ..onTap = () async {
                                                    final email =
                                                        match.group(0)!;
                                                    final url = 'mailto:$email';
                                                    if (await canLaunchUrl(
                                                      Uri.parse(url),
                                                    )) {
                                                      await launchUrl(
                                                        Uri.parse(url),
                                                      );
                                                    }
                                                  },
                                          ),
                                        );
                                      }
                                      lastIndex = match.end;
                                    }

                                    if (lastIndex < messageText.length) {
                                      textSpans.add(
                                        TextSpan(
                                          text: messageText.substring(
                                            lastIndex,
                                          ),
                                          style: GoogleFonts.openSans(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                      );
                                    }

                                    return Container(
                                      margin: const EdgeInsets.only(
                                        bottom: 8.0,
                                      ),
                                      padding: const EdgeInsets.all(8.0),
                                      color: backgroundColor,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${message.userEmail} bejegyzése, ${DateFormat('yyyy. MM. dd. HH:mm', 'hu').format(message.timestamp.toDate())}',
                                            style: GoogleFonts.openSans(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          RichText(
                                            text: TextSpan(children: textSpans),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                  const SizedBox(height: 16),
                                  const Text('Fájlok:'),
                                  ...task.files.map((file) {
                                    return ListTile(
                                      title: Text(
                                        file.fileName,
                                        style: GoogleFonts.openSans(
                                          color: const Color(0xFF8A7E8D),
                                          fontSize: 14,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Méret: ${(file.size / 1024 / 1024).toStringAsFixed(2)} MB',
                                            style: GoogleFonts.openSans(
                                              color: const Color(0xFF8A7E8D),
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            'Feltöltötte: ${file.uploadedBy}, ${DateFormat('yyyy. MM. dd. HH:mm', 'hu').format(file.uploadedAt.toDate())}',
                                            style: GoogleFonts.openSans(
                                              color: const Color(0xFF8A7E8D),
                                              fontSize: 12,
                                            ),
                                          ),
                                          if (file.description != null)
                                            Text(
                                              'Leírás: ${file.description}',
                                              style: GoogleFonts.openSans(
                                                color: const Color(0xFF8A7E8D),
                                                fontSize: 12,
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  }),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed:
                                            canEdit
                                                ? () {
                                                  _showTaskDialog(task: task);
                                                }
                                                : null,
                                        child: Text(
                                          'Szerkesztés',
                                          style: GoogleFonts.openSans(
                                            color:
                                                canEdit
                                                    ? const Color(0xFF8A7E8D)
                                                    : Colors.grey,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed:
                                            canEdit
                                                ? () {
                                                  _archiveTask(task);
                                                }
                                                : null,
                                        child: Text(
                                          'Archiválás',
                                          style: GoogleFonts.openSans(
                                            color:
                                                canEdit
                                                    ? const Color(0xFF8A7E8D)
                                                    : Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
