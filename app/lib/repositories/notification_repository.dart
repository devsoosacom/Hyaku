import '../models/notification_model.dart';

abstract class NotificationRepository {
  Stream<List<NotificationModel>> getNotifications(String userId);
  Future<void> markAllRead(String userId);
  Future<void> markOneRead(String notifId);
  int getUnreadCount(String userId);
}
