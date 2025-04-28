import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    employeesFuture = fetchEmployees(); // İlk veri yüklemesi
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
      employeesFuture = fetchEmployees(); // Veri güncelleniyor
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.deepPurpleAccent,
        centerTitle: false, // Bu satırı false yaparak başlığı sola yaslıyoruz
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurpleAccent, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Align(
          alignment:
              Alignment
                  .centerLeft, // Başlığı sola yaslamak için Align kullanıyoruz
          child: Text(
            widget.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.white.withOpacity(0.2),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            AddMultiUserTaskScreen(email: widget.email),
                  ),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Görev Ekle', // Butonun yazısı
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.white.withOpacity(0.2),
              ),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Çalışan Ekle', // Butonun yazısı
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: employeesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Bir hata oluştu.'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Hiç çalışan bulunamadı.'));
          }

          final employees = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: employees.length,
              itemBuilder: (context, index) {
                var employee = employees[index];
                String employeeName =
                    '${employee['name']} ${employee['surname']}';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  shadowColor: Colors.deepPurpleAccent.withOpacity(0.5),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 16.0,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Colors.deepPurple,
                      child: Text(
                        employee['name'][0],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      employeeName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.deepPurple,
                    ),
                    onTap: () {
                      String fullName =
                          '${employee['name']} ${employee['surname']}';
                      String email = employee['email'];

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  TaskScreen(fullName: fullName, email: email),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
