import 'dart:async';
import '../../models/notification_model.dart';
import '../notification_repository.dart';

class MockNotificationRepository implements NotificationRepository {
  final _controllers = <String, StreamController<List<NotificationModel>>>{};
  final _notifications = <String, List<NotificationModel>>{};

  List<NotificationModel> _seedForUser(String userId) {
    final now = DateTime.now();
    return [
      NotificationModel(
        id: 'notif-${userId}-1',
        targetUserId: userId,
        type: NotificationType.like,
        actorName: '怪談師 鬼灯',
        postTitle: 'あなたの怪談',
        postId: 'seed-1',
        createdAt: now.subtract(const Duration(minutes: 15)),
      ),
      NotificationModel(
        id: 'notif-${userId}-2',
        targetUserId: userId,
        type: NotificationType.comment,
        actorName: '夜語り べる',
        postTitle: 'あなたの怪談',
        postId: 'seed-1',
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      NotificationModel(
        id: 'notif-${userId}-3',
        targetUserId: userId,
        type: NotificationType.like,
        actorName: '闇語り ゆらぎ',
        postTitle: 'あなたの怪談',
        postId: 'seed-2',
        createdAt: now.subtract(const Duration(hours: 3)),
        isRead: true,
      ),
      NotificationModel(
        id: 'notif-${userId}-4',
        targetUserId: userId,
        type: NotificationType.comment,
        actorName: '語り部 とおの',
        postTitle: 'あなたの怪談',
        postId: 'seed-2',
        createdAt: now.subtract(const Duration(hours: 6)),
        isRead: true,
      ),
      NotificationModel(
        id: 'notif-${userId}-5',
        targetUserId: userId,
        type: NotificationType.like,
        actorName: '夜半 かなえ',
        postTitle: 'あなたの怪談',
        postId: 'seed-1',
        createdAt: now.subtract(const Duration(days: 1)),
        isRead: true,
      ),
    ];
  }

  @override
  Stream<List<NotificationModel>> getNotifications(String userId) {
    _notifications.putIfAbsent(userId, () => _seedForUser(userId));
    _controllers.putIfAbsent(
      userId,
      () => StreamController<List<NotificationModel>>.broadcast(),
    );
    Future.microtask(
        () => _controllers[userId]!.add(_notifications[userId]!));
    return _controllers[userId]!.stream;
  }

  @override
  Future<void> markAllRead(String userId) async {
    final list = _notifications[userId];
    if (list == null) return;
    _notifications[userId] = list.map((n) => n.copyWith(isRead: true)).toList();
    _controllers[userId]?.add(_notifications[userId]!);
  }

  @override
  int getUnreadCount(String userId) {
    return (_notifications[userId] ?? []).where((n) => !n.isRead).length;
  }

  void addNotification(NotificationModel notification) {
    final userId = notification.targetUserId;
    _notifications[userId] = [
      notification,
      ...(_notifications[userId] ?? []),
    ];
    _controllers[userId]?.add(_notifications[userId]!);
  }
}
