import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

final userProfileProvider =
    FutureProvider.family<UserModel?, String>((ref, userId) async {
  final db = FirebaseFirestore.instance;
  final doc = await db.collection('users').doc(userId).get();
  if (!doc.exists) return null;
  final d = doc.data()!;
  return UserModel(
    id: userId,
    displayName: d['displayName'] ?? '',
    email: '',
    bio: d['bio'] as String?,
    photoUrl: d['photoUrl'] as String?,
    createdAt: d['createdAt'] != null
        ? (d['createdAt'] as Timestamp).toDate()
        : DateTime.now(),
  );
});
