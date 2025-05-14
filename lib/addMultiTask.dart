import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddMultiUserTaskScreen extends StatefulWidget {
  final String email;
  final String teamID;
  AddMultiUserTaskScreen({required this.email, required this.teamID});

  @override
  _AddMultiUserTaskScreenState createState() => _AddMultiUserTaskScreenState();
}

class _AddMultiUserTaskScreenState extends State<AddMultiUserTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _title, _note;
  late DateTime createdTime = DateTime.now();
  List<String> _allEmails = [];
  List<String> _selectedEmails = [];

  @override
  void initState() {
    super.initState();
    _fetchAllUsers();
  }

  Future<void> _fetchAllUsers() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('secavision')
            .doc('WrgRRDBv5bn9WhP1UESe')
            .collection('users')
            .where('teamID', isEqualTo: widget.teamID)
            .get();

    setState(() {
      _allEmails = snapshot.docs.map((doc) => doc['email'] as String).toList();
    });
  }

  Future<void> _saveTaskForSelectedUsers() async {
    for (String email in _selectedEmails) {
      await FirebaseFirestore.instance
          .collection('secavision')
          .doc('WrgRRDBv5bn9WhP1UESe')
          .collection('tasks')
          .add({
            'title': _title,
            'taskstate': 1, // Varsayılan olarak "Başlamamış"
            'ownermail': email,
            'startdate': null,
            'enddate': null,
            'note': _note,
            'createdtime': Timestamp.fromDate(createdTime),
            'teamID': widget.teamID,
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Expanded widget kullanarak buton genişliği ekran boyutuna oranlı olacak şekilde ayarlandı
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _showUserSelectionDialog();
                      },
                      child: Text(
                        'Çalışan Seç',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                          primaryColor,
                        ),
                      ),
                    ),
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
                // Kaydetme butonunu burada yerleştirdik
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate() &&
                          _selectedEmails.isNotEmpty) {
                        _formKey.currentState!.save();
                        try {
                          await _saveTaskForSelectedUsers();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Görev(ler) başarıyla eklendi!'),
                            ),
                          );
                          Navigator.pop(context);
                        } catch (e) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Hata: $e')));
                        }
                      } else if (_selectedEmails.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Lütfen en az bir kullanıcı seçin.'),
                          ),
                        );
                      }
                    },
                    child: Text(
                      'Kaydet',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(primaryColor),
                    ),
                  ),
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
