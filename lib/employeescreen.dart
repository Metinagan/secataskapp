import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyEmployeeTasksScreen extends StatefulWidget {
  final String name;
  final String email;

  MyEmployeeTasksScreen({required this.name, required this.email});

  @override
  _MyEmployeeTasksScreenState createState() => _MyEmployeeTasksScreenState();
}

class _MyEmployeeTasksScreenState extends State<MyEmployeeTasksScreen> {
  List<Map<String, dynamic>> tasks = [];

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  Future<void> fetchTasks() async {
    try {
      final tasksRef = FirebaseFirestore.instance
          .collection('secavision')
          .doc('WrgRRDBv5bn9WhP1UESe')
          .collection('tasks');

      final snapshot =
          await tasksRef.where('ownermail', isEqualTo: widget.email).get();

      final fetchedTasks =
          snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();

      setState(() {
        tasks = fetchedTasks;
      });
    } catch (e) {
      print("Error fetching tasks: $e");
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await FirebaseFirestore.instance
          .collection('secavision')
          .doc('WrgRRDBv5bn9WhP1UESe')
          .collection('tasks')
          .doc(taskId)
          .delete();
      fetchTasks(); // Görev silindikten sonra listeyi güncelle
    } catch (e) {
      print("Error deleting task: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurpleAccent,
        title: Center(
          child: Text(
            widget.name,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child:
            tasks.isEmpty
                ? const Center(child: Text("Görev bulunamadı."))
                : ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    DateTime taskDate =
                        (task['startdate'] as Timestamp).toDate();
                    DateTime? endDate =
                        (task['enddate'] as Timestamp?)?.toDate();

                    // Task State Icon
                    IconData taskIcon;
                    Color taskColor;

                    switch (task['taskstate']) {
                      case 1:
                        taskIcon = Icons.remove_circle_outline;
                        taskColor = Colors.grey;
                        break;
                      case 2:
                        taskIcon = Icons.radio_button_checked;
                        taskColor = Colors.blue;
                        break;
                      case 3:
                        taskIcon = Icons.check_circle;
                        taskColor = Colors.green;
                        break;
                      case 0:
                        taskIcon = Icons.cancel;
                        taskColor = Colors.red;
                        break;
                      default:
                        taskIcon = Icons.help_outline;
                        taskColor = Colors.black;
                    }

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: Icon(taskIcon, color: taskColor),
                        title: GestureDetector(
                          onTap: () {
                            // Görev tıklanınca edit sayfasına yönlendiriliyor
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => EditTaskScreen(
                                      taskId: task['id'],
                                      taskName: task['title'],
                                      taskStartDate: task['startdate'],
                                      taskEndDate: task['enddate'],
                                      taskOwnerEmail: task['ownermail'],
                                      taskState: task['taskstate'],
                                      taskNote: task['note'] ?? '',
                                    ),
                              ),
                            ).then((_) {
                              fetchTasks(); // Yeni görev eklendikten sonra listeyi güncelle
                            });
                          },
                          child: Text(
                            task['title'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Başlangıç Tarihi: ${DateFormat('dd MMM yyyy HH:mm').format(taskDate)}",
                            ),
                            if (endDate != null)
                              Text(
                                "Bitiş Tarihi: ${DateFormat('dd MMM yyyy HH:mm').format(endDate)}",
                              ),
                            if (task['note'] != null && task['note'].isNotEmpty)
                              Text("NOT! : ${task['note']}"),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            // Silme işlemi
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Text("Silme Onayı"),
                                  content: Text(
                                    "Bu görevi silmek istediğinizden emin misiniz?",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text("İptal"),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        deleteTask(task['id']);
                                        Navigator.pop(context);
                                      },
                                      child: Text(
                                        "Sil",
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurpleAccent,
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => EditTaskScreen(
                    taskId: '',
                    taskName: '',
                    taskStartDate: Timestamp.now(),
                    taskEndDate: null,
                    taskOwnerEmail: widget.email,
                    taskState: 1,
                    taskNote: '',
                  ),
            ),
          ).then((_) {
            fetchTasks(); // Yeni görev eklendikten sonra listeyi güncelle
          });
        },
      ),
    );
  }
}

class EditTaskScreen extends StatefulWidget {
  final String taskId;
  final String taskName;
  final Timestamp? taskStartDate;
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
    selectedTaskState = widget.taskState;

    if (widget.taskEndDate != null) {
      taskEndDate = widget.taskEndDate?.toDate();
    }
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
        'startdate': widget.taskStartDate,
        'enddate':
            taskEndDate != null ? Timestamp.fromDate(taskEndDate!) : null,
        'ownermail': widget.taskOwnerEmail,
        'taskstate': selectedTaskState ?? 1,
        'note':
            taskNoteController.text.isEmpty ? null : taskNoteController.text,
      };

      if (widget.taskId.isEmpty) {
        await FirebaseFirestore.instance
            .collection('secavision')
            .doc('WrgRRDBv5bn9WhP1UESe')
            .collection('tasks')
            .add(taskData);
      } else {
        await FirebaseFirestore.instance
            .collection('secavision')
            .doc('WrgRRDBv5bn9WhP1UESe')
            .collection('tasks')
            .doc(widget.taskId)
            .update(taskData);
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
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Görev Başlığı
            _buildTextField(
              controller: taskNameController,
              labelText: "Görev Başlığı",
            ),
            SizedBox(height: 16),

            // Görev Notu
            _buildTextField(
              controller: taskNoteController,
              labelText: "Görev Notu",
              maxLines: 3,
            ),
            SizedBox(height: 16),

            // Başlangıç Tarihi
            _buildStartDatePicker(),
            SizedBox(height: 16),

            // Bitiş Tarihi (Opsiyonel)
            _buildEndDatePicker(),
            SizedBox(height: 16),

            // Görev Durumu
            _buildDropdown(),
            SizedBox(height: 24),

            // Görev Kaydetme Butonu
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  // TextField oluşturma fonksiyonu
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(color: Colors.deepPurpleAccent),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
        ),
      ),
    );
  }

  // Başlangıç tarihi ve saati seçici
  Widget _buildStartDatePicker() {
    // Eğer taskStartDate null ise, o anki tarih ve saatle başla
    DateTime currentDate = taskStartDate ?? DateTime.now();

    return Row(
      children: [
        Icon(Icons.calendar_today, color: Colors.deepPurpleAccent),
        SizedBox(width: 8),
        Text(
          "Başlangıç Zamanı: ${DateFormat('dd MMM yyyy HH:mm').format(currentDate)}",
          style: TextStyle(color: Colors.deepPurpleAccent),
        ),
        IconButton(
          icon: Icon(Icons.edit, color: Colors.deepPurpleAccent),
          onPressed: () async {
            final DateTime? selectedDate = await showDatePicker(
              context: context,
              initialDate: currentDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
            );
            if (selectedDate != null) {
              final TimeOfDay? selectedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(currentDate),
              );
              if (selectedTime != null) {
                setState(() {
                  taskStartDate = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );
                });
              }
            } else {
              setState(() {
                taskStartDate =
                    currentDate; // Eğer tarih seçilmezse, mevcut tarih ve saat kaydedilsin
              });
            }
          },
        ),
      ],
    );
  }

  // Bitiş tarihi seçici
  Widget _buildEndDatePicker() {
    return Row(
      children: [
        Icon(Icons.calendar_today, color: Colors.deepPurpleAccent),
        SizedBox(width: 8),
        Text(
          taskEndDate == null
              ? "Bitiş Zamanı"
              : "Bitiş Zamanı: ${DateFormat('dd MMM yyyy HH:mm').format(taskEndDate!)}",
          style: TextStyle(color: Colors.deepPurpleAccent),
        ),
        IconButton(
          icon: Icon(Icons.edit, color: Colors.deepPurpleAccent),
          onPressed: () async {
            final DateTime? selectedDate = await showDatePicker(
              context: context,
              initialDate: taskEndDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
            );
            if (selectedDate != null) {
              final TimeOfDay? selectedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(
                  taskEndDate ?? DateTime.now(),
                ),
              );
              if (selectedTime != null) {
                setState(() {
                  taskEndDate = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );
                });
              }
            }
          },
        ),
      ],
    );
  }

  // Durum seçici
  Widget _buildDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
      ),
      child: DropdownButton<int>(
        value: selectedTaskState,
        isExpanded: true,
        underline: SizedBox(),
        onChanged: (newValue) {
          setState(() {
            selectedTaskState = newValue;
          });
        },
        items: [
          DropdownMenuItem(value: 0, child: Text('İptal Edildi')),
          DropdownMenuItem(value: 1, child: Text('Başlamadı')),
          DropdownMenuItem(value: 2, child: Text('Devam Ediyor')),
          DropdownMenuItem(value: 3, child: Text('Tamamlandı')),
        ],
      ),
    );
  }

  // Kaydetme butonu
  Widget _buildSaveButton() {
    return Center(
      child: ElevatedButton(
        onPressed: saveTask,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              Colors.deepPurpleAccent, // primary yerine backgroundColor
          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          widget.taskId.isEmpty ? "Görevi Kaydet" : "Değişiklikleri Kaydet",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
