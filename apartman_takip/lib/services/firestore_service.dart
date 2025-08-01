import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/apartment_group.dart';
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
          .orderBy('createdAt', descending: true) // Index hazır, geri ekledik
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
}
