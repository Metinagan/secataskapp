import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:secatask/employeeEditTaskScreen.dart';

class MyEmployeeTasksScreen extends StatefulWidget {
  final String name;
  final String email;

  MyEmployeeTasksScreen({required this.name, required this.email});

  @override
  _MyEmployeeTasksScreenState createState() => _MyEmployeeTasksScreenState();
}

class _MyEmployeeTasksScreenState extends State<MyEmployeeTasksScreen> {
  List<Map<String, dynamic>> allTasks = [];
  List<Map<String, dynamic>> tasks = [];

  String selectedTimeFilter = 'Bu Hafta';
  String selectedSort = 'Yeni → Eski';

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
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          }).toList();

      setState(() {
        allTasks = fetchedTasks;
        applyFilters();
      });
    } catch (e) {
      print("Error fetching tasks: $e");
    }
  }

  void applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(allTasks);

    DateTime now = DateTime.now();

    if (selectedTimeFilter == 'Bu Hafta') {
      DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      DateTime endOfWeek = startOfWeek.add(Duration(days: 6));
      filtered =
          filtered.where((task) {
            DateTime taskDate = (task['startdate'] as Timestamp).toDate();
            return taskDate.isAfter(
                  startOfWeek.subtract(Duration(seconds: 1)),
                ) &&
                taskDate.isBefore(endOfWeek.add(Duration(days: 1)));
          }).toList();
    } else if (selectedTimeFilter == 'Bu Ay') {
      filtered =
          filtered.where((task) {
            DateTime taskDate = (task['startdate'] as Timestamp).toDate();
            return taskDate.month == now.month && taskDate.year == now.year;
          }).toList();
    }

    if (selectedSort == 'Yeni → Eski') {
      filtered.sort(
        (a, b) => (b['startdate'] as Timestamp).compareTo(
          a['startdate'] as Timestamp,
        ),
      );
    } else {
      filtered.sort(
        (a, b) => (a['startdate'] as Timestamp).compareTo(
          b['startdate'] as Timestamp,
        ),
      );
    }

    setState(() {
      tasks = filtered;
    });
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await FirebaseFirestore.instance
          .collection('secavision')
          .doc('WrgRRDBv5bn9WhP1UESe')
          .collection('tasks')
          .doc(taskId)
          .delete();
      fetchTasks();
    } catch (e) {
      print("Error deleting task: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Colors.deepPurpleAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurpleAccent, Colors.purple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: Center(
            child: Text(
              widget.name,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 32,
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ToggleButtons(
                    isSelected: [
                      selectedTimeFilter == 'Bu Hafta',
                      selectedTimeFilter == 'Bu Ay',
                      selectedTimeFilter == 'Tüm Zamanlar',
                    ],
                    onPressed: (index) {
                      setState(() {
                        if (index == 0) {
                          selectedTimeFilter = 'Bu Hafta';
                        } else if (index == 1) {
                          selectedTimeFilter = 'Bu Ay';
                        } else {
                          selectedTimeFilter = 'Tüm Zamanlar';
                        }
                        applyFilters();
                      });
                    },
                    children: [
                      _buildToggleButton("Bu Hafta"),
                      _buildToggleButton("Bu Ay"),
                      _buildToggleButton("Tüm Zamanlar"),
                    ],
                    color: Colors.deepPurpleAccent,
                    selectedColor: Colors.white,
                    fillColor: Colors.deepPurpleAccent,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  SizedBox(width: 12),
                  ToggleButtons(
                    isSelected: [
                      selectedSort == 'Yeni → Eski',
                      selectedSort == 'Eski → Yeni',
                    ],
                    onPressed: (index) {
                      setState(() {
                        if (index == 0) {
                          selectedSort = 'Yeni → Eski';
                        } else {
                          selectedSort = 'Eski → Yeni';
                        }
                        applyFilters();
                      });
                    },
                    children: [
                      _buildToggleButton("Yeni → Eski"),
                      _buildToggleButton("Eski → Yeni"),
                    ],
                    color: Colors.deepPurpleAccent,
                    selectedColor: Colors.white,
                    fillColor: Colors.deepPurpleAccent,
                    borderRadius: BorderRadius.circular(30),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Expanded(
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
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => EmployeeEditTaskScreen(
                                            taskId: task['id'],
                                            taskName: task['title'],
                                            taskStartDate: task['startdate'],
                                            taskEndDate: task['enddate'],
                                            taskOwnerEmail: task['ownermail'],
                                            taskState: task['taskstate'],
                                            taskNote: task['note'] ?? '',
                                          ),
                                    ),
                                  ).then((_) => fetchTasks());
                                },
                                child: Text(
                                  task['title'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
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
                                  if (task['note'] != null &&
                                      task['note'].isNotEmpty)
                                    Text("NOT! : ${task['note']}"),
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
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
                                            onPressed:
                                                () => Navigator.pop(context),
                                            child: Text("İptal"),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              deleteTask(task['id']);
                                              Navigator.pop(context);
                                            },
                                            child: Text(
                                              "Sil",
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
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
          ],
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
                  (context) => EmployeeEditTaskScreen(
                    taskId: '',
                    taskName: '',
                    taskStartDate: Timestamp.now(),
                    taskEndDate: null,
                    taskOwnerEmail: widget.email,
                    taskState: 1,
                    taskNote: '',
                  ),
            ),
          ).then((_) => fetchTasks());
        },
      ),
    );
  }

  Widget _buildToggleButton(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(text),
    );
  }
}
