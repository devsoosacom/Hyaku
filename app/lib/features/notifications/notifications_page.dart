import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/notification_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    final notifAsync = ref.watch(notificationsProvider(user.id));

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: Color(0xFF888888), size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '通知',
          style: GoogleFonts.notoSerifJp(
            fontSize: 18,
            color: const Color(0xFFEEEEEE),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF1E1E1E)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref
                  .read(notificationRepositoryProvider)
                  .markAllRead(user.id);
            },
            child: Text(
              '全既読',
              style: GoogleFonts.notoSerifJp(
                  color: const Color(0xFF888888), fontSize: 12),
            ),
          ),
        ],
      ),
      body: notifAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
              color: Color(0xFFCC0000), strokeWidth: 2),
        ),
        error: (_, __) => const SizedBox.shrink(),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.notifications_none,
                      color: Color(0xFF333333), size: 52),
                  const SizedBox(height: 16),
                  Text(
                    '通知はありません',
                    style: GoogleFonts.notoSerifJp(
                        color: const Color(0xFF555555), fontSize: 14),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (_, __) =>
                const Divider(color: Color(0xFF1A1A1A), height: 1),
            itemBuilder: (_, i) =>
                _NotificationTile(notification: notifications[i]),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});
  final NotificationModel notification;

  void _onTap(BuildContext context, WidgetRef ref) {
    // Mark as read
    if (!notification.isRead) {
      ref
          .read(notificationRepositoryProvider)
          .markOneRead(notification.id);
    }
    // Navigate
    switch (notification.type) {
      case NotificationType.like:
      case NotificationType.comment:
        if (notification.postId.isNotEmpty) {
          context.push('/post/${notification.postId}');
        }
      case NotificationType.follow:
        if (notification.actorId.isNotEmpty) {
          context.push('/user/${notification.actorId}');
        }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLike = notification.type == NotificationType.like;
    final isFollow = notification.type == NotificationType.follow;

    return GestureDetector(
      onTap: () => _onTap(context, ref),
      child: Container(
        color: notification.isRead
            ? Colors.transparent
            : const Color(0xFF0F0A0A),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Icon(
              isFollow
                  ? Icons.person_add
                  : isLike
                      ? Icons.favorite
                      : Icons.chat_bubble,
              color: isLike
                  ? const Color(0xFFCC0000)
                  : isFollow
                      ? const Color(0xFF4A9EFF)
                      : const Color(0xFF666666),
              size: 18,
            ),
          ),
          title: Text(
            notification.message,
            style: GoogleFonts.notoSerifJp(
              fontSize: 13,
              color: notification.isRead
                  ? const Color(0xFF888888)
                  : const Color(0xFFDDDDDD),
              height: 1.5,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _formatTime(notification.createdAt),
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF555555)),
            ),
          ),
          trailing: notification.isRead
              ? null
              : Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFCC0000),
                    shape: BoxShape.circle,
                  ),
                ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
    if (diff.inHours < 24) return '${diff.inHours}時間前';
    return DateFormat('MM月dd日').format(dt);
  }
}
