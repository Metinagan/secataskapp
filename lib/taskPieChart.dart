import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class TaskPieChart extends StatelessWidget {
  final String email;
  final String filter;

  const TaskPieChart({super.key, required this.email, required this.filter});

  Future<Map<String, int>> fetchChartData() async {
    // Firebase'den verileri filtrele ve say
    final ref = FirebaseFirestore.instance
        .collection('secavision')
        .doc('WrgRRDBv5bn9WhP1UESe')
        .collection('tasks');

    Query query = ref;

    if (email != 'all') {
      query = query.where('ownermail', isEqualTo: email);
    }

    if (filter == 'week') {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      query = query.where('startdate', isGreaterThanOrEqualTo: startOfWeek);
    } else if (filter == 'month') {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      query = query.where('startdate', isGreaterThanOrEqualTo: startOfMonth);
    }

    final snapshot = await query.get();
    int completed = 0;
    int pending = 0;

    for (var doc in snapshot.docs) {
      if (doc['taskstate'] == 3) {
        completed++;
      } else {
        pending++;
      }
    }

    return {'Tamamlandı': completed, 'Bekliyor': pending};
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: fetchChartData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!;
        final total = data.values.fold(0, (a, b) => a + b);
        if (total == 0) {
          return const Center(child: Text('Grafik için veri yok.'));
        }

        return SizedBox(
          height: 250, // veya 300
          child: PieChart(
            PieChartData(
              sections:
                  data.entries.map((entry) {
                    final color =
                        entry.key == 'Tamamlandı'
                            ? Colors.green
                            : Colors.orange;
                    final percent = (entry.value / total * 100).toStringAsFixed(
                      1,
                    );
                    return PieChartSectionData(
                      value: entry.value.toDouble(),
                      color: color,
                      title: '${entry.key}\n$percent%',
                      radius: 80,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
              sectionsSpace: 4,
              centerSpaceRadius: 40,
            ),
          ),
        );
      },
    );
  }
}
