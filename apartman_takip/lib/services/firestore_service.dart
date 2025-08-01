import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/apartment_group.dart';
import '../models/task.dart';
import '../models/task_rotation.dart';
import 'dart:math';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Davet kodu oluştur
  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  // Yeni apartman grubu oluştur
  Future<ApartmentGroup?> createApartmentGroup({
    required String name,
    required String description,
    required String creatorId,
  }) async {
    try {
      final docRef = _firestore.collection('apartment_groups').doc();
      final inviteCode = _generateInviteCode();

      final apartmentGroup = ApartmentGroup(
        id: docRef.id,
        name: name,
        description: description,
        creatorId: creatorId,
        memberIds: [creatorId], // Oluşturan kişi otomatik üye
        inviteCode: inviteCode,
        createdAt: DateTime.now(),
      );

      await docRef.set(apartmentGroup.toMap());
      return apartmentGroup;
    } catch (e) {
      print('Apartman grubu oluşturma hatası: $e');
      return null;
    }
  }

  // Kullanıcının apartman gruplarını getir
  Future<List<ApartmentGroup>> getUserApartmentGroups(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('apartment_groups')
          .where('memberIds', arrayContains: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ApartmentGroup.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Apartman grupları getirme hatası: $e');
      return [];
    }
  }

  // Apartman grubu bilgilerini getir
  Future<ApartmentGroup?> getApartmentGroup(String apartmentId) async {
    try {
      final docSnapshot = await _firestore
          .collection('apartment_groups')
          .doc(apartmentId)
          .get();

      if (docSnapshot.exists) {
        return ApartmentGroup.fromMap(docSnapshot.data()!);
      }
      return null;
    } catch (e) {
      print('Apartman grubu getirme hatası: $e');
      return null;
    }
  }

  // Davet kodu ile gruba katıl
  Future<ApartmentGroup?> joinGroupByInviteCode({
    required String inviteCode,
    required String userId,
  }) async {
    try {
      // Davet kodu ile grubu bul
      final querySnapshot = await _firestore
          .collection('apartment_groups')
          .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Geçersiz davet kodu');
      }

      final doc = querySnapshot.docs.first;
      final apartmentData = doc.data();
      final memberIds = List<String>.from(apartmentData['memberIds'] ?? []);

      // Kullanıcı zaten üye mi kontrol et
      if (memberIds.contains(userId)) {
        throw Exception('Bu gruba zaten üyesiniz');
      }

      // Kullanıcıyı gruba ekle
      memberIds.add(userId);

      await doc.reference.update({
        'memberIds': memberIds,
      });

      // Güncellenmiş grup bilgilerini döndür
      return ApartmentGroup.fromMap({
        ...apartmentData,
        'memberIds': memberIds,
      });
    } catch (e) {
      print('Gruba katılma hatası: $e');
      return null;
    }
  }

  // Yeni görev oluştur (atama bilgisi ile)
  Future<Task?> createTask({
    required String name,
    required String description,
    required String apartmentId,
    int priority = 3,
    String? assignedUserId,
  }) async {
    try {
      final docRef = _firestore.collection('tasks').doc();

      final task = Task(
        id: docRef.id,
        name: name,
        description: description,
        apartmentId: apartmentId,
        priority: priority,
        isActive: true,
        createdAt: DateTime.now(),
        assignedUserId: assignedUserId,
        assignedDate: assignedUserId != null ? DateTime.now() : null,
      );

      await docRef.set(task.toMap());
      return task;
    } catch (e) {
      print('Görev oluşturma hatası: $e');
      return null;
    }
  }

  // Apartmanın görevlerini getir
  Future<List<Task>> getApartmentTasks(String apartmentId) async {
    try {
      final querySnapshot = await _firestore
          .collection('tasks')
          .where('apartmentId', isEqualTo: apartmentId)
          .where('isActive', isEqualTo: true)
          .orderBy('priority')
          .orderBy('createdAt', descending: false)
          .get();

      return querySnapshot.docs.map((doc) => Task.fromMap(doc.data())).toList();
    } catch (e) {
      print('Görevleri getirme hatası: $e');
      return [];
    }
  }

  // Görev güncelle (atanan kişi dahil)
  Future<Task?> updateTask({
    required String taskId,
    required String name,
    required String description,
    required int priority,
    String? assignedUserId,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'name': name,
        'description': description,
        'priority': priority,
        'assignedUserId': assignedUserId,
      };

      // Atanan kişi bilgisi varsa tarihi de güncelle
      if (assignedUserId != null) {
        updateData['assignedDate'] = DateTime.now().millisecondsSinceEpoch;
      } else {
        // Atama kaldırıldıysa tarihi de temizle
        updateData['assignedDate'] = null;
      }

      await _firestore.collection('tasks').doc(taskId).update(updateData);

      // Güncellenmiş görevi al
      final docSnapshot = await _firestore.collection('tasks').doc(taskId).get();

      if (docSnapshot.exists) {
        return Task.fromMap(docSnapshot.data()!);
      }
      return null;
    } catch (e) {
      print('Görev güncelleme hatası: $e');
      return null;
    }
  }

  // Görev sil (soft delete)
  Future<bool> deleteTask(String taskId) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'isActive': false,
      });
      return true;
    } catch (e) {
      print('Görev silme hatası: $e');
      return false;
    }
  }

  // Görevi belirli kişiye ata
  Future<bool> assignTaskToUser({
    required String taskId,
    required String userId,
  }) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'assignedUserId': userId,
        'assignedDate': DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    } catch (e) {
      print('Görev atama hatası: $e');
      return false;
    }
  }

  // Kullanıcı bilgilerini Firestore'a kaydet
  Future<void> saveUserInfo({
    required String userId,
    required String email,
    required String displayName,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'email': email,
        'displayName': displayName,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Kullanıcı bilgisi kaydetme hatası: $e');
    }
  }

  // Kullanıcı adını getir (Firestore'dan)
  Future<String> getUserDisplayName(String userId) async {
    try {
      // Önce Firestore'dan kullanıcı bilgisini al
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        return userData['displayName'] ?? 'Kullanıcı';
      }

      // Firestore'da yoksa mevcut kullanıcı ise displayName'i al
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.uid == userId) {
        if (currentUser.displayName != null &&
            currentUser.displayName!.isNotEmpty) {
          // Firestore'a kaydet
          await saveUserInfo(
            userId: userId,
            email: currentUser.email ?? '',
            displayName: currentUser.displayName!,
          );
          return currentUser.displayName!;
        }
        // Fallback: email'den kullanıcı adı oluştur
        if (currentUser.email != null) {
          String emailPart = currentUser.email!.split('@')[0];
          String displayName = emailPart
              .replaceAll('.', ' ')
              .replaceAll('_', ' ')
              .split(' ')
              .map((word) => word.isNotEmpty
                  ? word[0].toUpperCase() + word.substring(1).toLowerCase()
                  : word)
              .join(' ');

          // Firestore'a kaydet
          await saveUserInfo(
            userId: userId,
            email: currentUser.email!,
            displayName: displayName,
          );
          return displayName;
        }
      }

      return 'Kullanıcı';
    } catch (e) {
      print('Kullanıcı adı getirme hatası: $e');
      return 'Bilinmeyen Kullanıcı';
    }
  }

  // Birden fazla kullanıcının adlarını getir
  Future<Map<String, String>> getUserDisplayNames(List<String> userIds) async {
    Map<String, String> userNames = {};

    for (String userId in userIds) {
      userNames[userId] = await getUserDisplayName(userId);
    }

    return userNames;
  }

  // Görev için sıra sistemi oluştur
  Future<TaskRotation?> createTaskRotation({
    required String taskId,
    required String apartmentId,
    required List<String> memberIds,
    int intervalDays = 7,
  }) async {
    try {
      final docRef = _firestore.collection('task_rotations').doc();
      
      // Rastgele sıralama ile adil başlangıç
      final shuffledMembers = List<String>.from(memberIds)..shuffle();
      
      final now = DateTime.now();
      final nextRotation = now.add(Duration(days: intervalDays));

      final rotation = TaskRotation(
        id: docRef.id,
        taskId: taskId,
        apartmentId: apartmentId,
        currentUserId: shuffledMembers.first,
        memberOrder: shuffledMembers,
        rotationStartDate: now,
        nextRotationDate: nextRotation,
        intervalDays: intervalDays,
        status: RotationStatus.active,
        currentPosition: 0,
      );

      await docRef.set(rotation.toMap());
      return rotation;
    } catch (e) {
      print('Sıra sistemi oluşturma hatası: $e');
      return null;
    }
  }

  // Apartmanın aktif sıralarını getir
  Future<List<TaskRotation>> getApartmentRotations(String apartmentId) async {
    try {
      final querySnapshot = await _firestore
          .collection('task_rotations')
          .where('apartmentId', isEqualTo: apartmentId)
          .where('status', isEqualTo: 'active')
          .get();

      return querySnapshot.docs
          .map((doc) => TaskRotation.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Sıra listesi getirme hatası: $e');
      return [];
    }
  }

  // Belirli görev için sırayı getir
  Future<TaskRotation?> getTaskRotation(String taskId) async {
    try {
      final querySnapshot = await _firestore
          .collection('task_rotations')
          .where('taskId', isEqualTo: taskId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return TaskRotation.fromMap(querySnapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      print('Görev sırası getirme hatası: $e');
      return null;
    }
  }

  // Görevi tamamla ve sırayı değiştir
  Future<bool> completeTaskRotation({
    required String rotationId,
    required String completedByUserId,
    String? notes,
  }) async {
    try {
      final rotationDoc = await _firestore
          .collection('task_rotations')
          .doc(rotationId)
          .get();

      if (!rotationDoc.exists) return false;

      final rotation = TaskRotation.fromMap(rotationDoc.data()!);
      
      // Sonraki kişiye geç
      final nextPosition = (rotation.currentPosition + 1) % rotation.memberOrder.length;
      final nextUserId = rotation.memberOrder[nextPosition];
      final nextRotationDate = DateTime.now().add(Duration(days: rotation.intervalDays));

      await _firestore.collection('task_rotations').doc(rotationId).update({
        'currentUserId': nextUserId,
        'currentPosition': nextPosition,
        'nextRotationDate': nextRotationDate.millisecondsSinceEpoch,
        'completedAt': DateTime.now().millisecondsSinceEpoch,
        'completedByUserId': completedByUserId,
        'rotationStartDate': DateTime.now().millisecondsSinceEpoch,
        'notes': notes,
      });

      // Tamamlanma geçmişi kaydet
      await _firestore.collection('task_completions').add({
        'rotationId': rotationId,
        'taskId': rotation.taskId,
        'apartmentId': rotation.apartmentId,
        'completedByUserId': completedByUserId,
        'completedAt': DateTime.now().millisecondsSinceEpoch,
        'notes': notes,
      });

      return true;
    } catch (e) {
      print('Görev tamamlama hatası: $e');
      return false;
    }
  }

  // Sırayı atla
  Future<bool> skipTaskRotation({
    required String rotationId,
    required String skippedByUserId,
    String? reason,
  }) async {
    try {
      final rotationDoc = await _firestore
          .collection('task_rotations')
          .doc(rotationId)
          .get();

      if (!rotationDoc.exists) return false;

      final rotation = TaskRotation.fromMap(rotationDoc.data()!);
      
      // Sonraki kişiye geç (atlama)
      final nextPosition = (rotation.currentPosition + 1) % rotation.memberOrder.length;
      final nextUserId = rotation.memberOrder[nextPosition];
      final nextRotationDate = DateTime.now().add(Duration(days: rotation.intervalDays));

      await _firestore.collection('task_rotations').doc(rotationId).update({
        'currentUserId': nextUserId,
        'currentPosition': nextPosition,
        'nextRotationDate': nextRotationDate.millisecondsSinceEpoch,
        'rotationStartDate': DateTime.now().millisecondsSinceEpoch,
      });

      // Atlama geçmişi kaydet
      await _firestore.collection('task_skips').add({
        'rotationId': rotationId,
        'taskId': rotation.taskId,
        'apartmentId': rotation.apartmentId,
        'skippedByUserId': skippedByUserId,
        'skippedAt': DateTime.now().millisecondsSinceEpoch,
        'reason': reason,
      });

      return true;
    } catch (e) {
      print('Sıra atlama hatası: $e');
      return false;
    }
  }

  // Kullanıcının aktif görevlerini getir (ona düşen sıralar)
  Future<List<Map<String, dynamic>>> getUserActiveRotations(String userId) async {
    try {
      final rotationsSnapshot = await _firestore
          .collection('task_rotations')
          .where('currentUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();

      List<Map<String, dynamic>> userRotations = [];

      for (var rotationDoc in rotationsSnapshot.docs) {
        final rotation = TaskRotation.fromMap(rotationDoc.data());
        
        // Görev bilgisini al
        final taskDoc = await _firestore
            .collection('tasks')
            .doc(rotation.taskId)
            .get();
            
        if (taskDoc.exists) {
          final task = Task.fromMap(taskDoc.data()!);
          userRotations.add({
            'rotation': rotation,
            'task': task,
          });
        }
      }

      return userRotations;
    } catch (e) {
      print('Kullanıcı sıraları getirme hatası: $e');
      return [];
    }
  }
}
