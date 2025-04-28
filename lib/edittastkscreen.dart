// edit_task_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:secatask/deletemultitask.dart';
// Burada task_service.dart dosyasını import ettik

class EditTaskScreen extends StatefulWidget {
  final String taskId;
  final String taskName;
  final Timestamp taskStartDate;
  final Timestamp? taskEndDate;
  final String taskOwnerEmail;
  final int taskState;
  final String taskNote;
  final Timestamp createdTime;

  EditTaskScreen({
    required this.taskId,
    required this.taskName,
    required this.taskStartDate,
    required this.taskEndDate,
    required this.taskOwnerEmail,
    required this.taskState,
    required this.taskNote,
    required this.createdTime,
  });

  @override
  _EditTaskScreenState createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _title, _description, _note;
  late DateTime _startDate, _endDate;
  int? _taskState;

  @override
  void initState() {
    super.initState();
    _title = widget.taskName;
    _description = ''; // Eksik olan alanı doldurdum
    _note = widget.taskNote;
    _startDate = widget.taskStartDate.toDate();
    _endDate = widget.taskEndDate?.toDate() ?? DateTime.now();
    _taskState = widget.taskState;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Görev Düzenle')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _title,
                decoration: InputDecoration(labelText: 'Görev Başlığı'),
                onSaved: (value) => _title = value!,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Başlık gereklidir';
                  }
                  return null;
                },
              ),
              // Diğer form elemanları...
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();

                    // Firestore işlemi
                    await FirebaseFirestore.instance
                        .collection('secavision')
                        .doc('WrgRRDBv5bn9WhP1UESe')
                        .collection('tasks')
                        .doc(widget.taskId)
                        .update({
                          'title': _title,
                          'description': _description,
                          'startdate': _startDate,
                          'enddate': _endDate,
                          'taskstate': _taskState,
                          'note': _note,
                          'createdtime': Timestamp.fromDate(
                            widget.createdTime.toDate(),
                          ),
                        });

                    if (_taskState == 2) {
                      // "Devam Ediyor" durumunda görevleri sil
                      await TaskService.deleteMultiTask(_title);
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Görev başarıyla güncellendi!')),
                    );
                    Navigator.pop(context);
                  }
                },
                child: Text('Güncelle'),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
