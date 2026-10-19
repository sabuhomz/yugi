import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// ตัวกลางเรียก Firebase Authentication
///
/// ทุกเมธอดที่ทำงานกับเซิร์ฟเวอร์คืนค่า `String?` เป็นข้อความผิดพลาดภาษาไทย
/// (null = สำเร็จ หรือผู้ใช้ปิดหน้าต่างล็อกอินเอง)
class AuthService {
  AuthService({required this.available});

  /// false เมื่อ Firebase ยังไม่ถูกตั้งค่า / เริ่มต้นไม่สำเร็จ
  final bool available;

  FirebaseAuth get _auth => FirebaseAuth.instance;

  User? get user => available ? _auth.currentUser : null;

  /// อีเวนต์เมื่อมีการล็อกอิน ออกจากระบบ หรือแก้โปรไฟล์
  Stream<User?> get changes =>
      available ? _auth.userChanges() : const Stream<User?>.empty();

  static const _cancelled = {
    'popup-closed-by-user',
    'cancelled-popup-request',
    'canceled',
    'web-context-canceled',
    'web-context-cancelled',
  };

  Future<String?> _run(Future<void> Function() action) async {
    if (!available) return 'ยังไม่ได้ตั้งค่า Firebase';
    try {
      await action();
      return null;
    } on FirebaseAuthException catch (e) {
      if (_cancelled.contains(e.code)) return null;
      debugPrint('FirebaseAuthException: ${e.code} ${e.message}');
      return thaiAuthError(e.code);
    } catch (e) {
      debugPrint('auth error: $e');
      return 'เกิดข้อผิดพลาด ลองใหม่อีกครั้ง';
    }
  }

  Future<String?> signIn(String email, String password) => _run(() async {
        await _auth.signInWithEmailAndPassword(
            email: email.trim(), password: password);
      });

  Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) =>
      _run(() async {
        final cred = await _auth.createUserWithEmailAndPassword(
            email: email.trim(), password: password);
        await cred.user?.updateDisplayName(name.trim());
      });

  /// เว็บใช้ popup, มือถือใช้ flow ของ Firebase เอง (ไม่ต้องใช้แพ็กเกจ google_sign_in)
  Future<String?> signInWithGoogle() => _run(() async {
        final provider = GoogleAuthProvider();
        if (kIsWeb) {
          await _auth.signInWithPopup(provider);
        } else {
          await _auth.signInWithProvider(provider);
        }
      });

  Future<String?> sendPasswordReset(String email) => _run(() async {
        await _auth.sendPasswordResetEmail(email: email.trim());
      });

  Future<void> signOut() async {
    if (available) await _auth.signOut();
  }
}

String thaiAuthError(String code) {
  switch (code) {
    case 'invalid-email':
      return 'รูปแบบอีเมลไม่ถูกต้อง';
    case 'user-disabled':
      return 'บัญชีนี้ถูกระงับการใช้งาน';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
    case 'email-already-in-use':
      return 'อีเมลนี้ถูกใช้สมัครแล้ว ลองเข้าสู่ระบบแทน';
    case 'weak-password':
      return 'รหัสผ่านง่ายเกินไป (อย่างน้อย 6 ตัวอักษร)';
    case 'too-many-requests':
      return 'ลองหลายครั้งเกินไป กรุณารอสักครู่แล้วลองใหม่';
    case 'network-request-failed':
      return 'เชื่อมต่ออินเทอร์เน็ตไม่ได้';
    case 'operation-not-allowed':
      return 'ยังไม่ได้เปิดวิธีล็อกอินนี้ใน Firebase Console';
    case 'account-exists-with-different-credential':
      return 'อีเมลนี้มีบัญชีที่สมัครด้วยวิธีอื่นอยู่แล้ว';
    case 'popup-blocked':
      return 'เบราว์เซอร์บล็อกหน้าต่างล็อกอิน กรุณาอนุญาตป๊อปอัป';
    case 'unauthorized-domain':
      return 'โดเมนนี้ยังไม่ได้เพิ่มใน Authorized domains ของ Firebase';
    default:
      return 'เกิดข้อผิดพลาด ($code)';
  }
}
