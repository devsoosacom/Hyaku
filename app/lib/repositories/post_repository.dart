import '../models/comment_model.dart';
import '../models/post_model.dart';

abstract class PostRepository {
  Stream<List<PostModel>> getPosts();
  Stream<List<PostModel>> getPostsByUser(String userId);
  Stream<List<PostModel>> getBookmarkedPosts(String userId);
  Stream<List<CommentModel>> getComments(String postId);
  Future<void> createPost({
    required String userId,
    required String authorName,
    required String title,
    required String content,
    List<String> tags,
  });
  Future<void> likePost(String postId, String userId);
  Future<void> unlikePost(String postId, String userId);
  Future<void> bookmarkPost(String postId, String userId);
  Future<void> unbookmarkPost(String postId, String userId);
  Future<void> addComment({
    required String postId,
    required String userId,
    required String authorName,
    required String content,
  });
  Future<void> deletePost(String postId, String userId);
}
