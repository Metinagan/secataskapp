import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmployeeEditTaskScreen extends StatefulWidget {
  final String taskId;
  final String taskName;
  final Timestamp? taskStartDate;
  final Timestamp? taskEndDate;
  final String taskOwnerEmail;
  final int taskState;
  final String taskNote;

  EmployeeEditTaskScreen({
    required this.taskId,
    required this.taskName,
    required this.taskStartDate,
    required this.taskEndDate,
    required this.taskOwnerEmail,
    required this.taskState,
    required this.taskNote,
  });

  @override
  _EmployeeEditTaskScreenState createState() => _EmployeeEditTaskScreenState();
}

class _EmployeeEditTaskScreenState extends State<EmployeeEditTaskScreen> {
  late TextEditingController taskNameController;
  late TextEditingController taskNoteController;
  DateTime? taskStartDate;
  DateTime? taskEndDate;
  int? selectedTaskState;

  @override
  void initState() {
    super.initState();
    taskNameController = TextEditingController(text: widget.taskName);
    taskNoteController = TextEditingController(text: widget.taskNote);
    taskStartDate = widget.taskStartDate?.toDate();
    if (widget.taskEndDate != null) {
      taskEndDate = widget.taskEndDate?.toDate();
    }
    selectedTaskState = widget.taskState;
  }

  @override
  void dispose() {
    taskNameController.dispose();
    taskNoteController.dispose();
    super.dispose();
  }

  Future<void> saveTask() async {
    try {
      final taskData = {
        'title': taskNameController.text,
        'startdate': Timestamp.fromDate(taskStartDate ?? DateTime.now()),
        'enddate':
            taskEndDate != null ? Timestamp.fromDate(taskEndDate!) : null,
        'ownermail': widget.taskOwnerEmail,
        'taskstate': selectedTaskState ?? 1,
        'note':
            taskNoteController.text.isEmpty ? null : taskNoteController.text,
      };

      final taskRef = FirebaseFirestore.instance
          .collection('secavision')
          .doc('WrgRRDBv5bn9WhP1UESe')
          .collection('tasks');

      if (widget.taskId.isEmpty) {
        await taskRef.add(taskData);
      } else {
        await taskRef.doc(widget.taskId).update(taskData);
      }

      Navigator.pop(context);
    } catch (e) {
      print("Error saving task: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.taskId.isEmpty ? "Yeni Görev Ekle" : "Görevi Düzenle",
        ),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTextField(
              controller: taskNameController,
              labelText: "Görev Başlığı",
            ),
            SizedBox(height: 16),
            _buildTextField(
              controller: taskNoteController,
              labelText: "Görev Notu",
              maxLines: 3,
            ),
            SizedBox(height: 16),
            _buildDatePicker("Başlangıç Zamanı", taskStartDate, true),
            SizedBox(height: 16),
            _buildDatePicker("Bitiş Zamanı", taskEndDate, false),
            SizedBox(height: 16),
            _buildDropdown(),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: saveTask,
              child: Text("Kaydet"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                minimumSize: Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime? dateTime, bool isStart) {
    return Row(
      children: [
        Icon(Icons.calendar_today, color: Colors.deepPurpleAccent),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            dateTime == null
                ? "$label seçilmedi"
                : "$label: ${DateFormat('dd MMM yyyy HH:mm').format(dateTime)}",
            style: TextStyle(color: Colors.deepPurpleAccent),
          ),
        ),
        IconButton(
          icon: Icon(Icons.edit, color: Colors.deepPurpleAccent),
          onPressed: () async {
            final selectedDate = await showDatePicker(
              context: context,
              initialDate: dateTime ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
            );
            if (selectedDate != null) {
              final selectedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(dateTime ?? DateTime.now()),
              );
              if (selectedTime != null) {
                final fullDate = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );
                setState(() {
                  if (isStart) {
                    taskStartDate = fullDate;
                  } else {
                    taskEndDate = fullDate;
                  }
                });
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<int>(
      value: selectedTaskState,
      onChanged: (val) => setState(() => selectedTaskState = val),
      items: [
        DropdownMenuItem(
          value: 0,
          child: Text(
            'İptal Edildi',
            style: TextStyle(color: Colors.red), // Kırmızı renk
          ),
        ),
        DropdownMenuItem(
          value: 1,
          child: Text(
            'Başlamadı',
            style: TextStyle(color: Colors.grey), // Gri renk
          ),
        ),
        DropdownMenuItem(
          value: 2,
          child: Text(
            'Devam Ediyor',
            style: TextStyle(color: Colors.blueAccent), // Amber renk
          ),
        ),
        DropdownMenuItem(
          value: 3,
          child: Text(
            'Tamamlandı',
            style: TextStyle(color: Colors.green), // Yeşil renk
          ),
        ),
      ],
      decoration: InputDecoration(
        labelText: "Görev Durumu",
        border: OutlineInputBorder(),
      ),
    );
  }
}
