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
        actorId: 'seed-user',
        actorName: '怪談師 鬼灯',
        postTitle: 'あなたの怪談',
        postId: 'seed-1',
        createdAt: now.subtract(const Duration(minutes: 15)),
      ),
      NotificationModel(
        id: 'notif-${userId}-2',
        targetUserId: userId,
        type: NotificationType.comment,
        actorId: 'seed-user2',
        actorName: '夜語り べる',
        postTitle: 'あなたの怪談',
        postId: 'seed-1',
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      NotificationModel(
        id: 'notif-${userId}-3',
        targetUserId: userId,
        type: NotificationType.like,
        actorId: 'seed-user3',
        actorName: '闇語り ゆらぎ',
        postTitle: 'あなたの怪談',
        postId: 'seed-2',
        createdAt: now.subtract(const Duration(hours: 3)),
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
  Future<void> markOneRead(String notifId) async {
    for (final userId in _notifications.keys) {
      final list = _notifications[userId]!;
      final idx = list.indexWhere((n) => n.id == notifId);
      if (idx != -1) {
        list[idx] = list[idx].copyWith(isRead: true);
        _controllers[userId]?.add(list);
        break;
      }
    }
  }

  @override
  int getUnreadCount(String userId) {
    return (_notifications[userId] ?? []).where((n) => !n.isRead).length;
  }
}
