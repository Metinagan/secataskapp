import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:secatask/adminpanel.dart';
import 'package:secatask/employeescreen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void _onLoginPressed() async {
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun')),
      );
      return;
    }

    final usersRef = FirebaseFirestore.instance
        .collection('secavision')
        .doc('WrgRRDBv5bn9WhP1UESe')
        .collection('users');

    final snapshot = await usersRef.get();

    bool loginSuccess = false;

    for (var doc in snapshot.docs) {
      final docEmail = doc.data()['email']?.toString();
      final docPassword = doc.data()['password']?.toString();

      // Null kontrolü ve email, password eşleşmesi
      if (docEmail != null &&
          docPassword != null &&
          email == docEmail &&
          password == docPassword) {
        loginSuccess = true;

        // Firebase'den 'role' değerini almak ve kontrol etmek
        final role = doc.data()['role']?.toString();
        if (role == 'admin') {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Admin Girişi!')));
          var adminName = doc.data()['name'];
          var adminSurname = doc.data()['surname'];
          var name = adminName + ' ' + adminSurname;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MyAdminPanelScreen(name: name),
            ),
          );
        } else if (role == 'employee') {
          // Çalışan girişi
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Çalışan Girişi!')));
          var employeeName = doc.data()['name'];
          var employeeSurname = doc.data()['surname'];
          var name = employeeName + ' ' + employeeSurname;
          var employeeEmail = doc.data()['email'];

          // Çalışan ekranına yönlendirme
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      MyEmployeeTasksScreen(name: name, email: employeeEmail),
            ),
          );
        } else {
          // Eğer rol tanımlanmamışsa, hata mesajı göster
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bilinmeyen kullanıcı rolü!')),
          );
        }
        break; // Eşleşme bulunduktan sonra döngüden çıkıyoruz
      }
    }

    // Eğer kullanıcı adı ve şifre eşleşmediyse
    if (!loginSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçersiz e-posta veya şifre')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Seca Vision Giriş',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'E-posta',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: 'Şifre',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: Colors.deepPurple,
                        ),
                        onPressed: _onLoginPressed,
                        child: const Text(
                          'Giriş Yap',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
