enum NotificationType { like, comment }

class NotificationModel {
  final String id;
  final String targetUserId;
  final NotificationType type;
  final String actorName;
  final String postTitle;
  final String postId;
  final DateTime createdAt;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.targetUserId,
    required this.type,
    required this.actorName,
    required this.postTitle,
    required this.postId,
    required this.createdAt,
    this.isRead = false,
  });

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      targetUserId: targetUserId,
      type: type,
      actorName: actorName,
      postTitle: postTitle,
      postId: postId,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  String get message {
    switch (type) {
      case NotificationType.like:
        return '$actorName があなたの「$postTitle」にいいねしました';
      case NotificationType.comment:
        return '$actorName があなたの「$postTitle」にコメントしました';
    }
  }
}
