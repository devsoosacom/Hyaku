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
        // Firestore失敗でもFirebase Authが認証済みなら基本情報で返す
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
}
