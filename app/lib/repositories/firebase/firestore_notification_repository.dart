import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/notification_model.dart';
import '../notification_repository.dart';

class FirestoreNotificationRepository implements NotificationRepository {
  final _db = FirebaseFirestore.instance;

  NotificationModel _fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      targetUserId: d['targetUserId'] ?? '',
      type: d['type'] == 'like' ? NotificationType.like : NotificationType.comment,
      actorName: d['actorName'] ?? '',
      postTitle: d['postTitle'] ?? '',
      postId: d['postId'] ?? '',
      createdAt: d['createdAt'] != null
          ? (d['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isRead: d['isRead'] ?? false,
    );
  }

  @override
  Stream<List<NotificationModel>> getNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('targetUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(_fromDoc).toList());
  }

  @override
  Future<void> markAllRead(String userId) async {
    final snap = await _db
        .collection('notifications')
        .where('targetUserId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  @override
  int getUnreadCount(String userId) => 0;
}
