abstract class FollowRepository {
  Stream<Set<String>> getFollowing(String userId);
  Stream<Set<String>> getFollowers(String userId);
  Future<void> follow(String followerId, String targetId);
  Future<void> unfollow(String followerId, String targetId);
}
