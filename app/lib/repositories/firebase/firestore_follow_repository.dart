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
    final batch = _db.batch();

    batch.set(
      _db.collection('follows').doc('${followerId}_$targetId'),
      {
        'followerId': followerId,
        'targetId': targetId,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );

    // Send follow notification to target user
    batch.set(
      _db.collection('notifications').doc(),
      {
        'targetUserId': targetId,
        'type': 'follow',
        'actorId': followerId,
        'actorName': '',
        'postId': '',
        'postTitle': '',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();

    // Fill in actor name from users collection
    try {
      final userSnap = await _db.collection('users').doc(followerId).get();
      if (!userSnap.exists) return;
      final name = userSnap.data()?['displayName'] ?? '';
      final notifs = await _db
          .collection('notifications')
          .where('actorId', isEqualTo: followerId)
          .where('targetUserId', isEqualTo: targetId)
          .where('type', isEqualTo: 'follow')
          .where('actorName', isEqualTo: '')
          .get();
      for (final d in notifs.docs) {
        await d.reference.update({'actorName': name});
      }
    } catch (_) {}
  }

  @override
  Future<void> unfollow(String followerId, String targetId) async {
    await _db
        .collection('follows')
        .doc('${followerId}_$targetId')
        .delete();
  }
}
