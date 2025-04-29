import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:secatask/stepsScreen.dart';

class TaskScreen extends StatefulWidget {
  final String fullName;
  final String email;

  const TaskScreen({super.key, required this.fullName, required this.email});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  String selectedFilter = 'week';
  String selectedOrder =
      'newest'; // En yeni / en eski toggle butonu için ekledik
  List<Map<String, dynamic>> allTasks = [];

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

      if (snapshot.docs.isEmpty) {
        print("No tasks found for this email.");
      }

      final tasks =
          snapshot.docs.map((doc) {
            var taskData = doc.data();
            taskData['id'] = doc.id; // ID'yi ekliyoruz
            return taskData;
          }).toList();

      setState(() {
        allTasks = tasks.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      print("Error fetching tasks: $e");
    }
  }

  List<Map<String, dynamic>> getFilteredTasks() {
    DateTime now = DateTime.now();
    DateTime startOfWeek;
    DateTime startOfMonth;

    // Pazartesi günü için tarih hesaplama, saat 00:01'e ayarlandı
    startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    startOfWeek = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
      0,
      1,
    );

    // Bu ayın başlangıç tarihi, saat 00:01'e ayarlandı
    startOfMonth = DateTime(now.year, now.month, 1, 0, 1);

    var filteredTasks =
        allTasks.where((task) {
          DateTime? taskDate = (task['createdtime'] as Timestamp).toDate();

          if (selectedFilter == 'week') {
            // Pazartesi günü 00:01'den bugüne kadar olan görevler
            return taskDate.isAfter(startOfWeek) &&
                taskDate.isBefore(now.add(Duration(days: 1)));
          } else if (selectedFilter == 'month') {
            // Ayın 1. günü 00:01'den bugüne kadar olan görevler
            return taskDate.isAfter(startOfMonth) &&
                taskDate.isBefore(now.add(Duration(days: 1)));
          }
          return true;
        }).toList();

    // Sıralama
    if (selectedOrder == 'newest') {
      filteredTasks.sort(
        (a, b) => (b['createdtime'] as Timestamp).compareTo(
          a['createdtime'] as Timestamp,
        ),
      );
    } else if (selectedOrder == 'oldest') {
      filteredTasks.sort(
        (a, b) => (a['createdtime'] as Timestamp).compareTo(
          b['createdtime'] as Timestamp,
        ),
      );
    }

    return filteredTasks;
  }

  void refreshTasks() async {
    await fetchTasks();
  }

  Future<void> deleteTask(String taskId) async {
    final taskRef = FirebaseFirestore.instance
        .collection('secavision')
        .doc('WrgRRDBv5bn9WhP1UESe')
        .collection('tasks')
        .doc(taskId);
    await taskRef.delete();
    refreshTasks();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = getFilteredTasks();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Center(
          child: Text(widget.fullName, style: TextStyle(color: Colors.white)),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.white24,
              ),
              onPressed: () async {
                await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  builder:
                      (context) => TaskAddSheet(
                        email: widget.email,
                        onTaskAdded: refreshTasks,
                      ),
                );
              },
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center, // Butonları ortala
            children: [
              ToggleButtons(
                isSelected: [
                  selectedFilter == 'week',
                  selectedFilter == 'month',
                  selectedFilter == 'all',
                ],
                borderRadius: BorderRadius.circular(16),
                selectedColor: Colors.white,
                fillColor: Colors.deepPurple,
                onPressed: (index) {
                  setState(() {
                    selectedFilter = ['week', 'month', 'all'][index];
                  });
                },
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Bu Hafta'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Bu Ay'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Tüm Zamanlar'),
                  ),
                ],
              ),
              const SizedBox(width: 16), // Araya boşluk ekliyoruz
              ToggleButtons(
                isSelected: [
                  selectedOrder == 'newest',
                  selectedOrder == 'oldest',
                ],
                borderRadius: BorderRadius.circular(16),
                selectedColor: Colors.white,
                fillColor: Colors.deepPurple,
                onPressed: (index) {
                  setState(() {
                    selectedOrder = ['newest', 'oldest'][index];
                  });
                },
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('En Yeni'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('En Eski'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child:
                tasks.isEmpty
                    ? const Center(child: Text("Görev bulunamadı."))
                    : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        DateTime? createDate =
                            (task['createdtime'] as Timestamp).toDate();
                        DateTime? taskDate =
                            (task['startdate'] as Timestamp).toDate();
                        DateTime? endDate =
                            (task['enddate'] as Timestamp?)?.toDate();

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
                            title: Text(
                              task['title'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Oluşturulma Tarihi: ${DateFormat('dd MMM yyyy HH:mm').format(createDate)}",
                                ),
                                Text(
                                  "Başlangıç Tarihi: ${DateFormat('dd MMM yyyy HH:mm').format(taskDate)}",
                                ),
                                if (endDate != null)
                                  Text(
                                    "Bitiş Tarihi: ${DateFormat('dd MMM yyyy HH:mm').format(endDate)}",
                                  ),
                                if (task['note'] != null &&
                                    task['note'].isNotEmpty)
                                  Text("NOT! : ${task['note']}"),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.deepPurple,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => StepListScreen(
                                              taskId: task['id'],
                                            ), // Buraya gideceğin ekranı yaz
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () async {
                                    bool? confirmDelete = await showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text(
                                            "${task['title']} silmek istiyor musunuz?",
                                          ),
                                          actions: <Widget>[
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.of(
                                                    context,
                                                  ).pop(false),
                                              child: const Text('Hayır'),
                                            ),
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.of(
                                                    context,
                                                  ).pop(true),
                                              child: const Text('Evet'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                    if (confirmDelete == true) {
                                      await deleteTask(task['id']);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

class TaskAddSheet extends StatefulWidget {
  final String email;
  final VoidCallback onTaskAdded;

  const TaskAddSheet({
    super.key,
    required this.email,
    required this.onTaskAdded,
  });

  @override
  State<TaskAddSheet> createState() => _TaskAddSheetState();
}

class _TaskAddSheetState extends State<TaskAddSheet> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descController = TextEditingController();
  DateTime? selectedDateTime;
  String note = "";

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now()),
    );

    if (time == null) return;

    setState(() {
      selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> saveTask() async {
    if (_formKey.currentState!.validate()) {
      if (selectedDateTime == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lütfen bir tarih seçin")));
        return;
      }

      final tasksRef = FirebaseFirestore.instance
          .collection('secavision')
          .doc('WrgRRDBv5bn9WhP1UESe')
          .collection('tasks');

      DateTime endDate = selectedDateTime!.add(const Duration(hours: 1));

      await tasksRef.add({
        'ownermail': widget.email,
        'title': titleController.text,
        'note': note,
        'startdate': selectedDateTime,
        'enddate': endDate,
        'taskstate': 1,
        'createdtime': DateTime.now(),
      });

      widget.onTaskAdded();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            children: [
              const Text(
                "Yeni Görev Ekle",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: "Başlık",
                  labelStyle: TextStyle(color: Colors.deepPurple),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title, color: Colors.deepPurple),
                ),
                validator:
                    (value) => value!.isEmpty ? "Başlık boş olamaz" : null,
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text(
                  selectedDateTime != null
                      ? DateFormat(
                        'dd MMM yyyy HH:mm',
                      ).format(selectedDateTime!)
                      : "Tarih seçilmedi",
                  style: TextStyle(color: Colors.deepPurple),
                ),
                trailing: Icon(Icons.calendar_today, color: Colors.deepPurple),
                onTap: _pickDateTime,
              ),

              const SizedBox(height: 12),
              TextFormField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: "Açıklama (Opsiyonel)",
                  labelStyle: TextStyle(color: Colors.deepPurple),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description, color: Colors.deepPurple),
                ),
                onChanged: (value) {
                  setState(() {
                    note = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text("Kaydet"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.white, width: 2),
                  ),
                  foregroundColor: Colors.white,
                ),
                onPressed: saveTask,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
