import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AddTaskScreen extends StatefulWidget {
  final String email;
  final String teamID;

  AddTaskScreen({required this.email, required this.teamID});

  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _title, _note;
  DateTime? _startDate;
  DateTime? _endDate;

  int? _taskState = 1;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _startDate ??
          DateTime.now(), // ilk seçimde yine DateTime.now() gösterilsin ama atama olmasın
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
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

  @override
  Widget build(BuildContext context) {
    Color primaryColor = Colors.deepPurple;

    DateTime createdTime = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Text('Görev Ekle'),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                try {
                  await FirebaseFirestore.instance
                      .collection('secavision')
                      .doc('WrgRRDBv5bn9WhP1UESe')
                      .collection('tasks')
                      .add({
                        'title': _title,
                        'startdate':
                            _startDate != null
                                ? Timestamp.fromDate(_startDate!)
                                : null,
                        'enddate':
                            _endDate != null
                                ? Timestamp.fromDate(_endDate!)
                                : null,
                        'taskstate': _taskState,
                        'ownermail': widget.email,
                        'note': _note,
                        'createdtime': Timestamp.fromDate(createdTime),
                        'teamID': widget.teamID,
                      });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Görev başarıyla eklendi!')),
                  );
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Hata: $e')));
                }
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
                                _startDate != null
                                    ? DateFormat(
                                      'dd MMM yyyy',
                                    ).format(_startDate!)
                                    : 'Seçiniz',
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
                Container(
                  width: double.infinity,
                  child: DropdownButtonFormField<int>(
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
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      try {
                        await FirebaseFirestore.instance
                            .collection('secavision')
                            .doc('WrgRRDBv5bn9WhP1UESe')
                            .collection('tasks')
                            .add({
                              'title': _title,
                              'startdate':
                                  _startDate != null
                                      ? Timestamp.fromDate(_startDate!)
                                      : null,
                              'enddate':
                                  _endDate != null
                                      ? Timestamp.fromDate(_endDate!)
                                      : null,
                              'taskstate': _taskState,
                              'ownermail': widget.email,
                              'note': _note,
                              'createdtime': Timestamp.fromDate(createdTime),
                              'teamID': widget.teamID,
                            });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Görev başarıyla eklendi!')),
                        );
                        Navigator.pop(context, true);
                      } catch (e) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    minimumSize: Size(double.infinity, 50),
                  ),
                  child: Text(
                    'Görev Ekle',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
}
