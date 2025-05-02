import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:secatask/addMultiTask.dart';
import 'package:secatask/addemployee.dart';
import 'package:secatask/taskscreen.dart';

class MyAdminPanelScreen extends StatefulWidget {
  final String name;
  final String email;

  const MyAdminPanelScreen({
    super.key,
    required this.name,
    required this.email,
  });

  @override
  _MyAdminPanelScreenState createState() => _MyAdminPanelScreenState();
}

class _MyAdminPanelScreenState extends State<MyAdminPanelScreen> {
  late Future<List<Map<String, dynamic>>> employeesFuture;
  String selectedEmployeeName = 'Herkes';
  String? selectedEmail;
  List<bool> isSelected = [true, false, false];
  String selectedFilter = 'Bu Hafta';

  @override
  void initState() {
    super.initState();
    employeesFuture = fetchEmployees();
  }

  Future<List<Map<String, dynamic>>> fetchEmployees() async {
    List<Map<String, dynamic>> employees = [];
    final usersRef = FirebaseFirestore.instance
        .collection('secavision')
        .doc('WrgRRDBv5bn9WhP1UESe')
        .collection('users');

    final snapshot = await usersRef.get();
    for (var doc in snapshot.docs) {
      employees.add(doc.data());
    }
    return employees;
  }

  void refreshEmployeeList() {
    setState(() {
      employeesFuture = fetchEmployees();
    });
  }

  Future<Map<String, double>> fetchTaskStateData() async {
    final taskRef = FirebaseFirestore.instance
        .collection('secavision')
        .doc('WrgRRDBv5bn9WhP1UESe')
        .collection('tasks');

    Query query = taskRef;

    if (selectedEmail != null) {
      query = query.where('ownermail', isEqualTo: selectedEmail);
    }

    final snapshot = await query.get();

    final now = DateTime.now();
    DateTime startDate;

    switch (selectedFilter) {
      case 'Bu Hafta':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'Bu Ay':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'Tüm Zamanlar':
      default:
        startDate = DateTime(2000);
        break;
    }

    Map<int, int> stateCounts = {0: 0, 1: 0, 2: 0, 3: 0};

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final createdTime = (data['createdtime'] as Timestamp).toDate();

      if (createdTime.isAfter(startDate)) {
        final state = data['taskstate'];
        if (stateCounts.containsKey(state)) {
          stateCounts[state] = stateCounts[state]! + 1;
        }
      }
    }

    return {
      'İptal Edildi': stateCounts[0]!.toDouble(),
      'Başlamadı': stateCounts[1]!.toDouble(),
      'Devam Ediyor': stateCounts[2]!.toDouble(),
      'Tamamlandı': stateCounts[3]!.toDouble(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.deepPurpleAccent,
        centerTitle: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurpleAccent, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          widget.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => AddMultiUserTaskScreen(email: widget.email),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white),
              backgroundColor: Colors.white.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Görev Ekle',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(width: 6),
          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => AddEmployeeScreen(
                        onEmployeeAdded: refreshEmployeeList,
                      ),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white),
              backgroundColor: Colors.white.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Çalışan Ekle',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: employeesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Bir hata oluştu.'));
          }

          final employees = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                /// Çalışan Listesi Kartı
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 6,
                  shadowColor: Colors.deepPurpleAccent.withOpacity(0.5),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Align(
                          alignment: Alignment.center,
                          child: Text(
                            "Çalışanlar",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // ListView.builder ile çalışan kartlarını kaydırarak göster
                        SizedBox(
                          height:
                              250, // Burada liste yüksekliğini belirleyebilirsiniz
                          child: ListView.builder(
                            itemCount:
                                employees.length > 6
                                    ? 6
                                    : employees.length, // İlk 10 öğe
                            itemBuilder: (context, index) {
                              String employeeName =
                                  '${employees[index]['name']} ${employees[index]['surname']}';
                              return Card(
                                elevation: 3,
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.deepPurple,
                                    child: Text(
                                      employees[index]['name'][0],
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    employeeName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: Colors.deepPurple,
                                  ),
                                  onTap: () {
                                    String fullName =
                                        '${employees[index]['name']} ${employees[index]['surname']}';
                                    String email = employees[index]['email'];

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => TaskScreen(
                                              fullName: fullName,
                                              email: email,
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                /// Çalışan Seçimi ve Görev Durumu Grafik Kartı
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        /// Çalışan Dropdown
                        Row(
                          children: [
                            const Text(
                              "Çalışan Seç:",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButton<String>(
                                value: selectedEmployeeName,
                                isExpanded: true,
                                items: [
                                  const DropdownMenuItem(
                                    value: 'Herkes',
                                    child: Text('Herkes'),
                                  ),
                                  ...employees.map((e) {
                                    String fullName =
                                        '${e['name']} ${e['surname']}';
                                    return DropdownMenuItem(
                                      value: fullName,
                                      child: Text(fullName),
                                    );
                                  }),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    selectedEmployeeName = value!;
                                    if (value == 'Herkes') {
                                      selectedEmail = null;
                                    } else {
                                      final selected = employees.firstWhere(
                                        (e) =>
                                            '${e['name']} ${e['surname']}' ==
                                            value,
                                      );
                                      selectedEmail = selected['email'];
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        /// Tarih Filtre Butonları
                        ToggleButtons(
                          borderRadius: BorderRadius.circular(12),
                          fillColor: Colors.deepPurpleAccent,
                          selectedColor: Colors.white,
                          color: Colors.deepPurple,
                          borderColor: Colors.deepPurpleAccent,
                          selectedBorderColor: Colors.deepPurple,
                          isSelected: isSelected,
                          onPressed: (int index) {
                            setState(() {
                              for (int i = 0; i < isSelected.length; i++) {
                                isSelected[i] = i == index;
                              }
                              switch (index) {
                                case 0:
                                  selectedFilter = 'Bu Hafta';
                                  break;
                                case 1:
                                  selectedFilter = 'Bu Ay';
                                  break;
                                case 2:
                                  selectedFilter = 'Tüm Zamanlar';
                                  break;
                              }
                            });
                          },
                          children: const [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12.0),
                              child: Text('Bu Hafta'),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12.0),
                              child: Text('Bu Ay'),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12.0),
                              child: Text('Tüm Zamanlar'),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        /// Pie Chart
                        FutureBuilder<Map<String, double>>(
                          future: fetchTaskStateData(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }
                            if (snapshot.hasError || !snapshot.hasData) {
                              return const Text("Veri alınamadı.");
                            }

                            final dataMap = snapshot.data!;

                            if (dataMap.values.every((v) => v == 0)) {
                              return const Text("Görev bulunamadı.");
                            }

                            return PieChart(
                              dataMap: dataMap,
                              chartType: ChartType.ring,
                              ringStrokeWidth: 32,
                              chartRadius:
                                  MediaQuery.of(context).size.width / 2.5,
                              colorList: const [
                                Colors.red,
                                Colors.orange,
                                Colors.blue,
                                Colors.green,
                              ],
                              legendOptions: const LegendOptions(
                                legendPosition: LegendPosition.left,
                                showLegends: true,
                              ),
                              chartValuesOptions: const ChartValuesOptions(
                                showChartValues: true,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 60),
              ],
            ),
          );
        },
      ),
    );
  }
}
