import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AddMultiUserTaskScreen extends StatefulWidget {
  final String email;

  AddMultiUserTaskScreen({required this.email});

  @override
  _AddMultiUserTaskScreenState createState() => _AddMultiUserTaskScreenState();
}

class _AddMultiUserTaskScreenState extends State<AddMultiUserTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _title, _note;
  late DateTime _startDate;
  DateTime? _endDate;
  int? _taskState = 1;
  List<String> _allEmails = [];
  List<String> _selectedEmails = [];

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    _fetchAllUsers();
  }

  Future<void> _fetchAllUsers() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('secavision')
            .doc('WrgRRDBv5bn9WhP1UESe')
            .collection('users')
            .get();

    setState(() {
      _allEmails = snapshot.docs.map((doc) => doc['email'] as String).toList();
    });
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _saveTaskForSelectedUsers() async {
    for (String email in _selectedEmails) {
      await FirebaseFirestore.instance
          .collection('secavision')
          .doc('WrgRRDBv5bn9WhP1UESe')
          .collection('tasks')
          .add({
            'title': _title,
            'startdate': Timestamp.fromDate(_startDate),
            'enddate': _endDate != null ? Timestamp.fromDate(_endDate!) : null,
            'taskstate': _taskState,
            'ownermail': email,
            'note': _note,
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    Color primaryColor = Colors.deepPurple;

    return Scaffold(
      appBar: AppBar(
        title: Text('Çoklu Görev Ekle'),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () async {
              if (_formKey.currentState!.validate() &&
                  _selectedEmails.isNotEmpty) {
                _formKey.currentState!.save();
                try {
                  await _saveTaskForSelectedUsers();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Görev(ler) başarıyla eklendi!')),
                  );
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Hata: $e')));
                }
              } else if (_selectedEmails.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lütfen en az bir kullanıcı seçin.')),
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _showUserSelectionDialog();
                  },
                  child: Text(
                    'Çalışan Seç',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(primaryColor),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Görev Başlığı',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Başlık girin',
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 20,
                    ),
                  ),
                  onSaved: (value) => _title = value!,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Başlık gereklidir';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                Text(
                  'Not',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Not girin',
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 20,
                    ),
                  ),
                  onSaved: (value) => _note = value!,
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickStartDate,
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: primaryColor),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Başlangıç Tarihi',
                                style: TextStyle(color: primaryColor),
                              ),
                              Text(
                                DateFormat('dd MMM yyyy').format(_startDate),
                                style: TextStyle(color: primaryColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickEndDate,
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: primaryColor),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Bitiş Tarihi',
                                style: TextStyle(color: primaryColor),
                              ),
                              Text(
                                _endDate != null
                                    ? DateFormat(
                                      'dd MMM yyyy',
                                    ).format(_endDate!)
                                    : 'Seçiniz',
                                style: TextStyle(color: primaryColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  'Görev Durumu',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 20,
                    ),
                  ),
                  value: _taskState,
                  items: [
                    DropdownMenuItem(child: Text('Başlamamış'), value: 1),
                    DropdownMenuItem(child: Text('Devam Ediyor'), value: 2),
                    DropdownMenuItem(child: Text('Tamamlandı'), value: 3),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _taskState = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUserSelectionDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Çalışan ekle',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple, // Doğrudan renk kullanımı
                    ),
                  ),

                  Expanded(
                    child: ListView(
                      children:
                          _allEmails.map((email) {
                            return CheckboxListTile(
                              title: Text(email),
                              value: _selectedEmails.contains(email),
                              onChanged: (bool? selected) {
                                setState(() {
                                  if (selected != null) {
                                    if (selected) {
                                      _selectedEmails.add(email);
                                    } else {
                                      _selectedEmails.remove(email);
                                    }
                                  }
                                });
                              },
                            );
                          }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
