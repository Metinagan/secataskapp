// task_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class TaskService {
  // Veritabanı işlemleri için genel bir servis sınıfı oluşturuyoruz
  static Future<void> deleteMultiTask(String taskName) async {
    try {
      final tasksRef = FirebaseFirestore.instance
          .collection('secavision')
          .doc('WrgRRDBv5bn9WhP1UESe')
          .collection('tasks');

      // Batch işlemi başlatılıyor
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // "title" ve "taskstate" kriterine göre filtreleme yapıyoruz
      final snapshot =
          await tasksRef
              .where('title', isEqualTo: taskName)
              .where('taskstate', isEqualTo: 1)
              .get();

      if (snapshot.docs.isEmpty) {
        print("Silinecek görev bulunamadı.");
      } else {
        // Bulunan her belgeyi batch'e ekliyoruz
        for (var doc in snapshot.docs) {
          batch.delete(doc.reference);
        }

        // Batch işlemini gönderiyoruz
        await batch.commit();
        print("${snapshot.docs.length} görev başarıyla silindi.");
      }
    } catch (e) {
      print("Silme hatası: $e");
    }
  }
}
