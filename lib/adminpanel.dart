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
  List<Map<String, dynamic>> filteredSteps = [];

  int selectedStatus = 5;

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  @override
  void initState() {
    super.initState();
    employeesFuture = fetchEmployees();

    _startDate = DateTime.now().subtract(Duration(days: 7));
    _endDate = DateTime.now();

    loadFilteredSteps();
  }

  Future<void> loadFilteredSteps() async {
    final steps = await fetchFilteredSteps(
      selectedEmail: selectedEmail,
      selectedStatus: selectedStatus,
      startDate: _startDate,
      endDate: _endDate,
    );
    setState(() {
      filteredSteps = steps;
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });

      //Tarih değişince görevleri tekrar filtrele
      loadFilteredSteps();
    }
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

  Future<List<Map<String, dynamic>>> fetchFilteredSteps({
    required String? selectedEmail,
    required int selectedStatus,
    required DateTime? startDate,
    required DateTime? endDate,
  }) async {
    List<Map<String, dynamic>> filteredSteps = [];

    try {
      final tasksSnapshot =
          await FirebaseFirestore.instance
              .collection('secavision')
              .doc('WrgRRDBv5bn9WhP1UESe')
              .collection('tasks')
              .get();

      for (var taskDoc in tasksSnapshot.docs) {
        final taskData = taskDoc.data();

        if (selectedEmail != null &&
            selectedEmail != 'Herkes' &&
            taskData['ownermail'] != selectedEmail) {
          continue;
        }

        if (selectedStatus != 5 && taskData['taskstate'] != selectedStatus) {
          continue;
        }

        final stepsSnapshot = await taskDoc.reference.collection('steps').get();

        for (var stepDoc in stepsSnapshot.docs) {
          final stepData = stepDoc.data();
          final stepStart = stepData['startdate'];

          DateTime? stepDate;
          if (stepStart is Timestamp) {
            stepDate = stepStart.toDate(); // ✅ Timestamp'tan DateTime'a
          }

          if (stepDate != null &&
              startDate != null &&
              endDate != null &&
              stepDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
              stepDate.isBefore(endDate.add(const Duration(days: 1)))) {
            filteredSteps.add({
              'taskId': taskDoc.id,
              'taskTitle': taskData['title'],
              'taskOwner': taskData['ownermail'],
              'name': taskData['name'],
              'surname': taskData['surname'],
              'step': stepData,
            });
          }
        }
      }

      print("Toplam adım: ${filteredSteps.length}"); // 🐞 Debug için

      return filteredSteps;
    } catch (e) {
      print('Hata (adım okuma): $e');
      return [];
    }
  }

  List<Widget> _buildTaskList(List<Map<String, dynamic>> stepsData) {
    // taskId'ye göre grupla
    Map<String, Map<String, dynamic>> grouped = {};

    for (var entry in stepsData) {
      String taskId = entry['taskId'];
      String title = entry['taskTitle'] ?? 'Başlıksız Görev';
      String owner = entry['taskOwner'] ?? 'Bilinmiyor';
      Map<String, dynamic> step = entry['step'];

      if (!grouped.containsKey(taskId)) {
        grouped[taskId] = {
          'title': title,
          'ownermail': owner,
          'steps': <Map<String, dynamic>>[],
        };
      }

      (grouped[taskId]!['steps'] as List<Map<String, dynamic>>).add(step);
    }

    return grouped.entries.map((entry) {
      final task = entry.value;
      final steps = task['steps'] as List<Map<String, dynamic>>;

      return Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Görev adı ve mail
                Text(
                  '📌 ${task['title']}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '👤 ${task['ownermail']}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),

                // Her step için küçük kart
                ...steps.map((step) {
                  String note = step['note'] ?? 'Not yok';

                  DateTime? startDate;
                  DateTime? endDate;

                  if (step['startdate'] is Timestamp) {
                    startDate = (step['startdate'] as Timestamp).toDate();
                  }
                  if (step['enddate'] is Timestamp) {
                    endDate = (step['enddate'] as Timestamp).toDate();
                  }

                  return Card(
                    color: const Color(0xFFF1F1F6),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),

                    child: Container(
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• $note'),
                            const SizedBox(height: 4),
                            if (startDate != null)
                              Text(
                                '🕒 Başlangıç: ${startDate.day}/${startDate.month}/${startDate.year} - '
                                '${startDate.hour.toString().padLeft(2, '0')}:${startDate.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            if (endDate != null)
                              Text(
                                '✅ Bitiş: ${endDate.day}/${endDate.month}/${endDate.year} - '
                                '${endDate.hour.toString().padLeft(2, '0')}:${endDate.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Future<Map<String, dynamic>?> showEmployeeSelectionDialog(
    BuildContext context,
    List<Map<String, dynamic>> employees,
  ) async {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Silinecek çalışanı seçin"),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: employees.length,
              itemBuilder: (context, index) {
                final employee = employees[index];
                final fullName = '${employee['name']} ${employee['surname']}';
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(fullName),
                  onTap: () {
                    Navigator.of(context).pop(employee);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text("İptal"),
              onPressed: () => Navigator.of(context).pop(null),
            ),
          ],
        );
      },
    );
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
                              child: DropdownButtonFormField<String>(
                                value: selectedEmployeeName,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.deepPurpleAccent
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.deepPurpleAccent
                                          .withOpacity(0.5),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.deepPurpleAccent,
                                      width: 2,
                                    ),
                                  ),
                                ),
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
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.person,
                                            color: Colors.black,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            fullName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
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
                                    loadFilteredSteps();
                                    //_buildTaskList(filteredSteps);
                                  });
                                },
                                dropdownColor:
                                    Colors.white, // Menü arka plan rengi
                                style: const TextStyle(
                                  color: Colors.deepPurpleAccent,
                                ),
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

                        const SizedBox(height: 30),

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

                            return Container(
                              height: 300, // Sabit yükseklik 400 piksel
                              child: PieChart(
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
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Görev Adımları Filtreleme Kartı
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tarih seçimleri
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _selectDate(context, true),
                                child: AbsorbPointer(
                                  child: TextFormField(
                                    decoration: InputDecoration(
                                      labelText: 'Başlangıç Tarihi',
                                      suffixIcon: Icon(Icons.calendar_today),
                                    ),
                                    controller: TextEditingController(
                                      text:
                                          _startDate == null
                                              ? ''
                                              : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                                    ),
                                    readOnly: true,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _selectDate(context, false),
                                child: AbsorbPointer(
                                  child: TextFormField(
                                    decoration: InputDecoration(
                                      labelText: 'Bitiş Tarihi',
                                      suffixIcon: Icon(Icons.calendar_today),
                                    ),
                                    controller: TextEditingController(
                                      text:
                                          _endDate == null
                                              ? ''
                                              : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                                    ),
                                    readOnly: true,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Durum Dropdown
                        DropdownButtonFormField<int>(
                          value: selectedStatus,
                          decoration: const InputDecoration(
                            labelText: 'Durum',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 5, child: Text('Hepsi')),
                            DropdownMenuItem(
                              value: 1,
                              child: Text('Başlamadı'),
                            ),
                            DropdownMenuItem(
                              value: 2,
                              child: Text('Devam Ediyor'),
                            ),
                            DropdownMenuItem(
                              value: 3,
                              child: Text('Tamamlandı'),
                            ),
                            DropdownMenuItem(
                              value: 0,
                              child: Text('İptal Edildi'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedStatus = value!;
                            });
                            loadFilteredSteps();
                          },
                        ),
                        const SizedBox(height: 16),

                        // Görevler Listesi
                        if (filteredSteps.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Text('Filtreye uyan görev bulunamadı.'),
                          )
                        else
                          ..._buildTaskList(filteredSteps), // ✅ YENİLEME BURADA
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                //çalışa silme kartı
                Card(
                  elevation: 4,
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.delete),
                            label: const Text("Çalışan Sil"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: const TextStyle(fontSize: 16),
                            ),
                            onPressed: () async {
                              final selectedEmployee =
                                  await showEmployeeSelectionDialog(
                                    context,
                                    employees,
                                  );

                              if (selectedEmployee != null) {
                                String fullName =
                                    '${selectedEmployee['name']} ${selectedEmployee['surname']}';

                                bool? confirm = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: Text('$fullName silinsin mi?'),
                                        content: const Text(
                                          "Bu işlem geri alınamaz. Devam etmek istiyor musunuz?",
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.of(
                                                  context,
                                                ).pop(false),
                                            child: const Text("İptal"),
                                          ),
                                          ElevatedButton(
                                            onPressed:
                                                () => Navigator.of(
                                                  context,
                                                ).pop(true),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.redAccent,
                                            ),
                                            child: const Text("Evet, Sil"),
                                          ),
                                        ],
                                      ),
                                );

                                if (confirm == true) {
                                  // 1. Firestore'dan kullanıcıyı sil
                                  final userSnapshot =
                                      await FirebaseFirestore.instance
                                          .collection('secavision')
                                          .doc('WrgRRDBv5bn9WhP1UESe')
                                          .collection('users')
                                          .where(
                                            'email',
                                            isEqualTo:
                                                selectedEmployee['email'],
                                          )
                                          .get();

                                  for (var doc in userSnapshot.docs) {
                                    await doc.reference.delete();
                                  }

                                  // 2. Görevleri sil
                                  final tasksSnapshot =
                                      await FirebaseFirestore.instance
                                          .collection('secavision')
                                          .doc('WrgRRDBv5bn9WhP1UESe')
                                          .collection('tasks')
                                          .where(
                                            'ownermail',
                                            isEqualTo:
                                                selectedEmployee['email'],
                                          )
                                          .get();

                                  for (var doc in tasksSnapshot.docs) {
                                    await doc.reference.delete();
                                  }

                                  // Listeyi güncelle
                                  fetchEmployees();
                                  refreshEmployeeList();

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "$fullName ve görevleri silindi.",
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }
}
