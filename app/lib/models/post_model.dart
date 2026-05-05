class PostModel {
  final String id;
  final String userId;
  final String authorName;
  final String title;
  final String content;
  final DateTime createdAt;
  final Set<String> likedBy;
  final int commentCount;

  const PostModel({
    required this.id,
    required this.userId,
    required this.authorName,
    required this.title,
    required this.content,
    required this.createdAt,
    this.likedBy = const {},
    this.commentCount = 0,
  });

  int get likeCount => likedBy.length;

  bool isLikedBy(String userId) => likedBy.contains(userId);

  PostModel copyWith({
    Set<String>? likedBy,
    int? commentCount,
  }) {
    return PostModel(
      id: id,
      userId: userId,
      authorName: authorName,
      title: title,
      content: content,
      createdAt: createdAt,
      likedBy: likedBy ?? this.likedBy,
      commentCount: commentCount ?? this.commentCount,
    );
  }
}
