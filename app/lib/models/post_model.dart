class PostModel {
  final String id;
  final String userId;
  final String authorName;
  final String? authorPhotoUrl;
  final String title;
  final String content;
  final DateTime createdAt;
  final Set<String> likedBy;
  final int commentCount;
  final List<String> tags;
  final Set<String> bookmarkedBy;

  const PostModel({
    required this.id,
    required this.userId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.title,
    required this.content,
    required this.createdAt,
    this.likedBy = const {},
    this.commentCount = 0,
    this.tags = const [],
    this.bookmarkedBy = const {},
  });

  int get likeCount => likedBy.length;
  bool isLikedBy(String userId) => likedBy.contains(userId);
  bool isBookmarkedBy(String userId) => bookmarkedBy.contains(userId);

  PostModel copyWith({
    Set<String>? likedBy,
    int? commentCount,
    List<String>? tags,
    Set<String>? bookmarkedBy,
  }) {
    return PostModel(
      id: id,
      userId: userId,
      authorName: authorName,
      authorPhotoUrl: authorPhotoUrl,
      title: title,
      content: content,
      createdAt: createdAt,
      likedBy: likedBy ?? this.likedBy,
      commentCount: commentCount ?? this.commentCount,
      tags: tags ?? this.tags,
      bookmarkedBy: bookmarkedBy ?? this.bookmarkedBy,
    );
  }
}
