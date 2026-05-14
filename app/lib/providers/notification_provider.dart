import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';
import '../repositories/firebase/firestore_notification_repository.dart';

final notificationRepositoryProvider =
    Provider<NotificationRepository>((ref) => FirestoreNotificationRepository());

final notificationsProvider =
    StreamProvider.family<List<NotificationModel>, String>((ref, userId) {
  return ref.watch(notificationRepositoryProvider).getNotifications(userId);
});

final unreadCountProvider = Provider.family<int, String>((ref, userId) {
  return ref.watch(notificationsProvider(userId)).maybeWhen(
        data: (list) => list.where((n) => !n.isRead).length,
        orElse: () => 0,
      );
});
