import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:secatask/addemployee.dart';
import 'package:secatask/taskscreen.dart';

class MyAdminPanelScreen extends StatefulWidget {
  final String name;

  const MyAdminPanelScreen({super.key, required this.name});

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

    final snapshot = await usersRef.where('role', isEqualTo: 'employee').get();

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
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
        title: Text(
          widget.name, // Display the name in the app bar
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => AddEmployeeScreen(
                          onEmployeeAdded:
                              refreshEmployeeList, // Refresh after adding employee
                        ),
                  ),
                );
              },
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: employeesFuture, // Updated future for employee list
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
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.deepPurple,
                      child: Text(
                        employee['name'][0], // İlk harfi gösteriyoruz
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      employeeName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded),
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
