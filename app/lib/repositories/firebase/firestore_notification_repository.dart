import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/notification_model.dart';
import '../notification_repository.dart';

class FirestoreNotificationRepository implements NotificationRepository {
  final _db = FirebaseFirestore.instance;

  NotificationModel _fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    NotificationType type;
    switch (d['type']) {
      case 'like':
        type = NotificationType.like;
      case 'follow':
        type = NotificationType.follow;
      default:
        type = NotificationType.comment;
    }
    return NotificationModel(
      id: doc.id,
      targetUserId: d['targetUserId'] ?? '',
      type: type,
      actorId: d['actorId'] ?? '',
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
        .snapshots()
        .map((s) => s.docs.map(_fromDoc).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
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
  Future<void> markOneRead(String notifId) async {
    await _db
        .collection('notifications')
        .doc(notifId)
        .update({'isRead': true});
  }

  @override
  int getUnreadCount(String userId) => 0;
}
