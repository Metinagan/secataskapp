import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:secatask/employeeEditTaskScreen.dart';
import 'package:secatask/stepsScreen.dart';

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
            data['createdtime'] =
                doc['createdtime']; // Firebase'den 'createdtime' verisini al
            data['startdate'] =
                doc['startdate']; // 'startdate' verisini ayrı al
            data['enddate'] = doc['enddate']; // 'enddate' verisini ayrı al
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
      int weekday = now.weekday;
      DateTime startOfWeek = DateTime(
        now.year,
        now.month,
        now.day - (weekday - 1),
      );
      DateTime endOfWeek = startOfWeek.add(
        Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
      );

      filtered =
          filtered.where((task) {
            DateTime taskDate = (task['createdtime'] as Timestamp).toDate();
            return taskDate.isAfter(
                  startOfWeek.subtract(Duration(seconds: 1)),
                ) &&
                taskDate.isBefore(endOfWeek.add(Duration(seconds: 1)));
          }).toList();
    } else if (selectedTimeFilter == 'Bu Ay') {
      DateTime startOfMonth = DateTime(now.year, now.month, 1);
      DateTime endOfMonth;
      if (now.month == 12) {
        endOfMonth = DateTime(now.year + 1, 1, 0, 23, 59, 59);
      } else {
        endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      }

      filtered =
          filtered.where((task) {
            DateTime taskDate = (task['createdtime'] as Timestamp).toDate();
            return taskDate.isAfter(
                  startOfMonth.subtract(Duration(seconds: 1)),
                ) &&
                taskDate.isBefore(endOfMonth.add(Duration(seconds: 1)));
          }).toList();
    }

    if (selectedSort == 'Yeni → Eski') {
      filtered.sort(
        (a, b) => (b['createdtime'] as Timestamp).compareTo(
          a['createdtime'] as Timestamp,
        ),
      );
    } else {
      filtered.sort(
        (a, b) => (a['createdtime'] as Timestamp).compareTo(
          b['createdtime'] as Timestamp,
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

  Duration calculateWorkDuration(DateTime start, DateTime end) {
    final workDayStart = TimeOfDay(hour: 8, minute: 0);
    final workDayEnd = TimeOfDay(hour: 18, minute: 0);

    if (start.isAfter(end)) return Duration.zero;

    Duration totalDuration = Duration.zero;
    DateTime current = start;

    while (current.isBefore(end)) {
      final dayStart = DateTime(
        current.year,
        current.month,
        current.day,
        workDayStart.hour,
        workDayStart.minute,
      );
      final dayEnd = DateTime(
        current.year,
        current.month,
        current.day,
        workDayEnd.hour,
        workDayEnd.minute,
      );

      final actualStart = current.isBefore(dayStart) ? dayStart : current;
      final actualEnd = end.isBefore(dayEnd) ? end : dayEnd;

      if (actualEnd.isAfter(actualStart)) {
        totalDuration += actualEnd.difference(actualStart);
      }

      current = DateTime(current.year, current.month, current.day + 1, 0, 0);
    }

    // Yuvarlama işlemi: Saniyeleri 60'a yuvarla
    final totalMinutes = totalDuration.inMinutes;
    final totalSeconds = totalDuration.inSeconds;
    final remainingSeconds = totalSeconds % 60;

    // Eğer saniye 30'dan büyükse, dakikayı 1 artırıyoruz
    if (remainingSeconds > 0) {
      return Duration(minutes: totalMinutes + 1);
    } else {
      return Duration(minutes: totalMinutes);
    }
  }

  Future<Duration> getTotalStepsDuration(String taskId) async {
    try {
      final stepsRef = FirebaseFirestore.instance
          .collection('secavision')
          .doc('WrgRRDBv5bn9WhP1UESe')
          .collection('tasks')
          .doc(taskId)
          .collection('steps');

      final snapshot = await stepsRef.get();
      Duration totalDuration = Duration.zero;

      for (var step in snapshot.docs) {
        final stepData = step.data() as Map<String, dynamic>;
        DateTime startDate = (stepData['startdate'] as Timestamp).toDate();
        DateTime endDate = (stepData['enddate'] as Timestamp).toDate();
        totalDuration += calculateWorkDuration(startDate, endDate);
      }

      return totalDuration;
    } catch (e) {
      print("Error fetching steps: $e");
      return Duration.zero;
    }
  }

  String getDurationString(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes % 60;
    return '$hours saat $minutes dakika';
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
                          DateTime createdTime =
                              (task['createdtime'] as Timestamp).toDate();
                          DateTime? startDate =
                              (task['startdate'] as Timestamp?)?.toDate();
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
                              leading: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [Icon(taskIcon, color: taskColor)],
                              ),
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
                                    "Oluşturulma Tarihi: ${DateFormat('dd MMM yyyy HH:mm').format(createdTime)}",
                                    style: TextStyle(color: Colors.black),
                                  ),
                                  if (startDate != null)
                                    Text(
                                      "Başlangıç Tarihi: ${DateFormat('dd MMM yyyy HH:mm').format(startDate)}",
                                      style: TextStyle(
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  if (endDate != null)
                                    Text(
                                      "Bitiş Tarihi: ${DateFormat('dd MMM yyyy HH:mm').format(endDate)}",
                                      style: TextStyle(color: Colors.red[700]),
                                    ),
                                  if (startDate != null && endDate != null)
                                    FutureBuilder<Duration>(
                                      future: getTotalStepsDuration(task['id']),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const CircularProgressIndicator();
                                        }

                                        if (snapshot.hasError) {
                                          return const Text(
                                            "Süre hesaplanamadı.",
                                          );
                                        }

                                        Duration totalStepsDuration =
                                            snapshot.data ?? Duration.zero;

                                        return Row(
                                          children: [
                                            const Icon(
                                              Icons.access_time,
                                              color: Colors.orange,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              "Çalışma Süresi: ${formatDuration(totalStepsDuration)}",
                                              style: TextStyle(
                                                color:
                                                    Colors
                                                        .orange, // Turuncu renk
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.arrow_right,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => StepListScreen(
                                                taskId: task['id'],
                                              ),
                                        ),
                                      ).then((result) {
                                        if (result == 'updated') {
                                          fetchTasks(); // Veri güncellenince fetchTasks fonksiyonunu çağırarak yeni veriyi al
                                        }
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text("Sil"),
                                            content: const Text(
                                              "Bu görevi silmek istediğinizden emin misiniz?",
                                            ),
                                            actions: <Widget>[
                                              TextButton(
                                                onPressed:
                                                    () =>
                                                        Navigator.pop(context),
                                                child: const Text("Hayır"),
                                              ),
                                              TextButton(
                                                onPressed: () async {
                                                  await deleteTask(task['id']);
                                                  Navigator.pop(context);
                                                },
                                                child: const Text("Evet"),
                                              ),
                                            ],
                                          );
                                        },
                                      );
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
      ),
    );
  }

  Widget _buildToggleButton(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(text, style: TextStyle(fontSize: 16)),
    );
  }

  String formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes % 60;
    return '$hours saat $minutes dakika';
  }
}
