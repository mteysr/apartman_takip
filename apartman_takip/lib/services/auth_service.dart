import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } catch (e) {
      print('Sign in error: $e');
      return null;
    }
  }

  // Register with email, password and username
  Future<UserCredential?> registerWithEmailAndPassword(
    String email,
    String password,
    String username,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Kullanıcı adını Firebase Auth'a kaydet
      await result.user?.updateDisplayName(username);
      await result.user?.reload();

      // Firestore'a da kullanıcı bilgilerini kaydet
      if (result.user != null) {
        final firestoreService = FirestoreService();
        await firestoreService.saveUserInfo(
          userId: result.user!.uid,
          email: email,
          displayName: username,
        );
      }

      return result;
    } catch (e) {
      print('Register error: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
    }
  }

  // Get user display name
  String getUserDisplayName() {
    final user = currentUser;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    // Fallback: email'den daha güzel kullanıcı adı oluştur
    if (user?.email != null) {
      String emailPart = user!.email!.split('@')[0];
      // Nokta ve alt çizgiyi boşlukla değiştir, ilk harfi büyük yap
      return emailPart
          .replaceAll('.', ' ')
          .replaceAll('_', ' ')
          .split(' ')
          .map((word) => word.isNotEmpty
              ? word[0].toUpperCase() + word.substring(1).toLowerCase()
              : word)
          .join(' ');
    }
    return 'Kullanıcı';
  }

  // Kullanıcı adını güncelle
  Future<bool> updateUserDisplayName(String newDisplayName) async {
    try {
      final user = currentUser;
      if (user != null) {
        await user.updateDisplayName(newDisplayName);
        await user.reload();

        // Firestore'a da güncelle
        final firestoreService = FirestoreService();
        await firestoreService.saveUserInfo(
          userId: user.uid,
          email: user.email ?? '',
          displayName: newDisplayName,
        );

        return true;
      }
      return false;
    } catch (e) {
      print('Display name güncelleme hatası: $e');
      return false;
    }
  }
}
