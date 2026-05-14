import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  UserModel? _cached;

  @override
  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) {
        _cached = null;
        return null;
      }
      try {
        final model = await _fetchOrCreate(user);
        _cached = model;
        return model;
      } catch (e) {
        final basic = UserModel(
          id: user.uid,
          displayName: user.displayName ?? 'ユーザー',
          email: user.email ?? '',
          createdAt: DateTime.now(),
        );
        _cached = basic;
        return basic;
      }
    });
  }

  @override
  UserModel? get currentUser => _cached;

  Future<UserModel> _fetchOrCreate(User firebaseUser) async {
    final doc = await _db.collection('users').doc(firebaseUser.uid).get();
    if (doc.exists) {
      final d = doc.data()!;
      return UserModel(
        id: firebaseUser.uid,
        displayName: d['displayName'] ?? '',
        email: d['email'] ?? '',
        bio: d['bio'] as String?,
        photoUrl: d['photoUrl'] as String?,
        createdAt: (d['createdAt'] as Timestamp).toDate(),
      );
    }
    final now = DateTime.now();
    final user = UserModel(
      id: firebaseUser.uid,
      displayName: firebaseUser.displayName ?? 'ユーザー',
      email: firebaseUser.email ?? '',
      createdAt: now,
    );
    await _db.collection('users').doc(user.id).set({
      'displayName': user.displayName,
      'email': user.email,
      'bio': null,
      'photoUrl': null,
      'createdAt': Timestamp.fromDate(now),
    });
    return user;
  }

  @override
  Future<UserModel> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final model = await _fetchOrCreate(cred.user!);
    _cached = model;
    return model;
  }

  @override
  Future<UserModel> signUp(
      String email, String password, String displayName) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user!.updateDisplayName(displayName);
    final now = DateTime.now();
    final user = UserModel(
      id: cred.user!.uid,
      displayName: displayName,
      email: email,
      createdAt: now,
    );
    await _db.collection('users').doc(user.id).set({
      'displayName': displayName,
      'email': email,
      'bio': null,
      'photoUrl': null,
      'createdAt': Timestamp.fromDate(now),
    });
    _cached = user;
    return user;
  }

  @override
  Future<void> signOut() async {
    _cached = null;
    await _auth.signOut();
  }

  @override
  Future<void> updateProfile({String? displayName, String? bio}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final updates = <String, dynamic>{};
    if (displayName != null) updates['displayName'] = displayName;
    if (bio != null) updates['bio'] = bio;
    await _db.collection('users').doc(uid).update(updates);
    if (displayName != null) {
      await _auth.currentUser!.updateDisplayName(displayName);
    }
    if (_cached != null) {
      _cached = _cached!.copyWith(
        displayName: displayName,
        bio: bio,
      );
    }
  }

  @override
  Future<String> updateProfilePhoto(List<int> bytes, String fileName) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('未ログイン');

    // Resize to 256px and encode as base64 PNG data URL (no Firebase Storage / CORS needed)
    final dataUrl = await _toResizedDataUrl(Uint8List.fromList(bytes));

    await _db.collection('users').doc(uid).update({'photoUrl': dataUrl});

    if (_cached != null) {
      _cached = _cached!.copyWith(photoUrl: dataUrl);
    }
    return dataUrl;
  }

  static Future<String> _toResizedDataUrl(Uint8List raw) async {
    final codec = await ui.instantiateImageCodec(
      raw,
      targetWidth: 256,
      targetHeight: 256,
    );
    final frame = await codec.getNextFrame();
    final byteData =
        await frame.image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();
    return 'data:image/png;base64,${base64Encode(pngBytes)}';
  }
}
