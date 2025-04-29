import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StepListScreen extends StatelessWidget {
  final String taskId;

  const StepListScreen({Key? key, required this.taskId}) : super(key: key);

  Future<List<Map<String, dynamic>>> fetchSteps() async {
    final stepsSnapshot =
        await FirebaseFirestore.instance
            .collection('secavision')
            .doc('WrgRRDBv5bn9WhP1UESe')
            .collection('tasks')
            .doc(taskId)
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

      // Ertesi güne geç
      current = DateTime(current.year, current.month, current.day + 1, 0, 0);
    }

    // Saat ve dakika farkı alıp sadece bunları döndürüyoruz, saniyeleri sıfırlıyoruz.
    final hours = totalDuration.inMinutes ~/ 60;
    final minutes = (totalDuration.inMinutes % 60) + 1;

    return Duration(hours: hours, minutes: minutes);
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
}
