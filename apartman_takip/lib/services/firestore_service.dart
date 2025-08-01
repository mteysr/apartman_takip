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
}
