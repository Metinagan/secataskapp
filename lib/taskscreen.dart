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
        final stepData = step.data();
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

  String formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes % 60;
    return '$hours saat $minutes dakika';
  }

  @override
  Widget build(BuildContext context) {
    final tasks = getFilteredTasks();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        automaticallyImplyLeading: true, // Geri butonu gerekiyorsa true
        centerTitle: true, // Gerçek ortalama için bu önemli
        title: Text(
          widget.fullName,
          style: const TextStyle(color: Colors.white),
        ),
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
                                if (taskDate != null)
                                  Text(
                                    "Başlangıç Tarihi: ${DateFormat('dd MMM yyyy HH:mm').format(taskDate)}",
                                  ),
                                const SizedBox(height: 8),
                                if (endDate != null)
                                  Text(
                                    "Bitiş Tarihi: ${DateFormat('dd MMM yyyy HH:mm').format(endDate)}",
                                  ),
                                if (task['note'] != null &&
                                    task['note'].isNotEmpty)
                                  Text("NOT! : ${task['note']}"),

                                if (taskDate != null)
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
                                                  Colors.orange, // Turuncu renk
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
                                            ),
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
