class UserModel {
  final String id;
  final String displayName;
  final String email;
  final String? bio;
  final String? photoUrl;
  final int postCount;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.displayName,
    required this.email,
    this.bio,
    this.photoUrl,
    this.postCount = 0,
    required this.createdAt,
  });

  UserModel copyWith({
    String? displayName,
    String? bio,
    String? photoUrl,
    int? postCount,
  }) {
    return UserModel(
      id: id,
      displayName: displayName ?? this.displayName,
      email: email,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      postCount: postCount ?? this.postCount,
      createdAt: createdAt,
    );
  }
}
