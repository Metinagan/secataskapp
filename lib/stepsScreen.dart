import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StepListScreen extends StatefulWidget {
  final String taskId;

  const StepListScreen({Key? key, required this.taskId}) : super(key: key);

  @override
  _StepListScreenState createState() => _StepListScreenState();
}

class _StepListScreenState extends State<StepListScreen> {
  Future<List<Map<String, dynamic>>> fetchSteps() async {
    final stepsSnapshot =
        await FirebaseFirestore.instance
            .collection('secavision')
            .doc('WrgRRDBv5bn9WhP1UESe')
            .collection('tasks')
            .doc(widget.taskId)
            .collection('steps')
            .orderBy('createdtime')
            .get();

    return stepsSnapshot.docs.map((doc) => doc.data()).toList();
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

  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours == 0 && minutes == 0) {
      return "0 dakika";
    } else if (hours == 0) {
      return "$minutes dakika";
    } else if (minutes == 0) {
      return "$hours saat";
    } else {
      return "$hours saat $minutes dakika";
    }
  }

  Future<void> addStep(
    String taskId,
    String note,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('secavision')
          .doc('WrgRRDBv5bn9WhP1UESe')
          .collection('tasks')
          .doc(taskId)
          .collection('steps')
          .add({
            'note': note,
            'startdate': Timestamp.fromDate(startDate), // Timestamp format
            'enddate': Timestamp.fromDate(endDate), // Timestamp format
            'createdtime': Timestamp.now(),
          });
      print("Adım başarıyla eklendi!");
    } catch (e) {
      print("Error adding step: $e");
    }
  }

  Future<void> deleteStep(String stepId) async {
    try {
      await FirebaseFirestore.instance
          .collection('secavision')
          .doc('WrgRRDBv5bn9WhP1UESe')
          .collection('tasks')
          .doc(widget.taskId)
          .collection('steps')
          .doc(stepId)
          .delete();
      print("Adım başarıyla silindi!");
    } catch (e) {
      print("Error deleting step: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Görev Adımları',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              _showAddStepDialog(context);
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchSteps(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Hiç adım bulunamadı.'));
          }

          final steps = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: steps.length,
            itemBuilder: (context, index) {
              final step = steps[index];
              final createdDate = (step['createdtime'] as Timestamp?)?.toDate();
              final startDate = (step['startdate'] as Timestamp?)?.toDate();
              final endDate = (step['enddate'] as Timestamp?)?.toDate();
              final note = step['note'] ?? '';
              final stepId =
                  step['stepId'] ?? ''; // Assuming you store the document ID

              Duration? workDuration;
              if (startDate != null && endDate != null) {
                workDuration = calculateWorkDuration(startDate, endDate);
              }

              return Card(
                elevation: 6,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.isNotEmpty ? note : "Açıklama Yok",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (createdDate != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.add_circle_outline,
                              color: Colors.grey,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Oluşturuldu: ${DateFormat('dd MMM yyyy HH:mm').format(createdDate)}",
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      if (startDate != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.play_circle_outline,
                              color: Colors.green,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Başlangıç: ${DateFormat('dd MMM yyyy HH:mm').format(startDate)}",
                              style: TextStyle(color: Colors.green[700]),
                            ),
                          ],
                        ),
                      if (endDate != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.stop_circle_outlined,
                              color: Colors.red,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Bitiş: ${DateFormat('dd MMM yyyy HH:mm').format(endDate)}",
                              style: TextStyle(color: Colors.red[700]),
                            ),
                          ],
                        ),
                      if (workDuration != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                color: Colors.orange,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Çalışma Süresi: ${formatDuration(workDuration)}",
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // ElevatedButton with text and icon
                          ElevatedButton.icon(
                            onPressed: () {
                              deleteStep(stepId);
                            },
                            icon: const Icon(Icons.delete, color: Colors.white),
                            label: const Text(
                              "Sil",
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.red, // Red color for the button
                              foregroundColor:
                                  Colors.white, // Color for the text and icon
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showAddStepDialog(BuildContext context) async {
    String note = '';
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(Duration(days: 1));
    TimeOfDay startTime = TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = TimeOfDay(hour: 9, minute: 0);

    TextEditingController startDateController = TextEditingController();
    TextEditingController endDateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Adım Ekle"),
          content: Container(
            width: 300,
            height: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(labelText: "Not"),
                  onChanged: (value) {
                    note = value;
                  },
                ),
                GestureDetector(
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: startDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        startDate = pickedDate;
                      });
                      TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: startTime,
                      );
                      if (pickedTime != null) {
                        setState(() {
                          startTime = pickedTime;
                        });
                        startDateController.text =
                            DateFormat('dd MMM yyyy').format(startDate) +
                            ' ' +
                            startTime.format(context);
                      }
                    }
                  },
                  child: AbsorbPointer(
                    child: TextField(
                      controller: startDateController,
                      decoration: InputDecoration(
                        labelText: "Başlangıç Tarihi",
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: endDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        endDate = pickedDate;
                      });
                      TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: endTime,
                      );
                      if (pickedTime != null) {
                        setState(() {
                          endTime = pickedTime;
                        });
                        endDateController.text =
                            DateFormat('dd MMM yyyy').format(endDate) +
                            ' ' +
                            endTime.format(context);
                      }
                    }
                  },
                  child: AbsorbPointer(
                    child: TextField(
                      controller: endDateController,
                      decoration: InputDecoration(labelText: "Bitiş Tarihi"),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("İptal"),
            ),
            TextButton(
              onPressed: () async {
                // Firebase'e veri kaydetme
                await addStep(widget.taskId, note, startDate, endDate);
                Navigator.pop(context);
              },
              child: Text("Kaydet"),
            ),
          ],
        );
      },
    );
  }
}
