// edit_task_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditTaskScreen extends StatefulWidget {
  final String taskId;
  final String taskName;
  final Timestamp taskStartDate;
  final Timestamp? taskEndDate;
  final String taskOwnerEmail;
  final int taskState;
  final String taskNote;

  EditTaskScreen({
    required this.taskId,
    required this.taskName,
    required this.taskStartDate,
    required this.taskEndDate,
    required this.taskOwnerEmail,
    required this.taskState,
    required this.taskNote,
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
              TextFormField(
                initialValue: _description,
                decoration: InputDecoration(labelText: 'Açıklama'),
                onSaved: (value) => _description = value!,
              ),
              TextFormField(
                initialValue: _note,
                decoration: InputDecoration(labelText: 'Not'),
                onSaved: (value) => _note = value!,
              ),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: Text('Başlangıç Tarihi'),
                      subtitle: Text('${_startDate.toLocal()}'.split(' ')[0]),
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2101),
                        );
                        if (pickedDate != null && pickedDate != _startDate)
                          setState(() {
                            _startDate = pickedDate;
                          });
                      },
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: Text('Bitiş Tarihi (Opsiyonel)'),
                      subtitle:
                          _endDate != null
                              ? Text('${_endDate.toLocal()}'.split(' ')[0])
                              : Text('Seçiniz'),
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2101),
                        );
                        if (pickedDate != null && pickedDate != _endDate)
                          setState(() {
                            _endDate = pickedDate;
                          });
                      },
                    ),
                  ),
                ],
              ),
              DropdownButtonFormField<int>(
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
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    FirebaseFirestore.instance
                        .collection('tasks')
                        .doc(widget.taskId)
                        .update({
                          'title': _title,
                          'description': _description,
                          'startdate': _startDate,
                          'enddate': _endDate,
                          'taskstate': _taskState,
                          'note': _note,
                        })
                        .then((value) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Görev başarıyla güncellendi!'),
                            ),
                          );
                          Navigator.pop(context);
                        });
                  }
                },
                child: Text('Görevi Güncelle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
