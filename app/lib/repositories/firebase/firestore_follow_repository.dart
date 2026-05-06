import 'package:cloud_firestore/cloud_firestore.dart';
import '../follow_repository.dart';

class FirestoreFollowRepository implements FollowRepository {
  final _db = FirebaseFirestore.instance;

  @override
  Stream<Set<String>> getFollowing(String userId) {
    return _db
        .collection('follows')
        .where('followerId', isEqualTo: userId)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => d.data()['targetId'] as String).toSet());
  }

  @override
  Stream<Set<String>> getFollowers(String userId) {
    return _db
        .collection('follows')
        .where('targetId', isEqualTo: userId)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => d.data()['followerId'] as String).toSet());
  }

  @override
  Future<void> follow(String followerId, String targetId) async {
    await _db
        .collection('follows')
        .doc('${followerId}_$targetId')
        .set({
      'followerId': followerId,
      'targetId': targetId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> unfollow(String followerId, String targetId) async {
    await _db
        .collection('follows')
        .doc('${followerId}_$targetId')
        .delete();
  }
}
