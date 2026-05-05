import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/comment_model.dart';
import '../models/post_model.dart';
import '../repositories/post_repository.dart';
import '../repositories/mock/mock_post_repository.dart';

final postRepositoryProvider = Provider<PostRepository>((ref) {
  return MockPostRepository();
});

final postsProvider = StreamProvider<List<PostModel>>((ref) {
  return ref.watch(postRepositoryProvider).getPosts();
});

final userPostsProvider =
    StreamProvider.family<List<PostModel>, String>((ref, userId) {
  return ref.watch(postRepositoryProvider).getPostsByUser(userId);
});

final commentsProvider =
    StreamProvider.family<List<CommentModel>, String>((ref, postId) {
  return ref.watch(postRepositoryProvider).getComments(postId);
});

class PostActionsNotifier extends StateNotifier<bool> {
  PostActionsNotifier(this._repo) : super(false);

  final PostRepository _repo;

  Future<void> createPost({
    required String userId,
    required String authorName,
    required String title,
    required String content,
  }) async {
    state = true;
    try {
      await _repo.createPost(
        userId: userId,
        authorName: authorName,
        title: title,
        content: content,
      );
    } finally {
      state = false;
    }
  }

  Future<void> toggleLike(PostModel post, String userId) async {
    if (post.isLikedBy(userId)) {
      await _repo.unlikePost(post.id, userId);
    } else {
      await _repo.likePost(post.id, userId);
    }
  }

  Future<void> addComment({
    required String postId,
    required String userId,
    required String authorName,
    required String content,
  }) async {
    await _repo.addComment(
      postId: postId,
      userId: userId,
      authorName: authorName,
      content: content,
    );
  }

  Future<void> deletePost(String postId, String userId) async {
    await _repo.deletePost(postId, userId);
  }
}

final postActionsProvider =
    StateNotifierProvider<PostActionsNotifier, bool>((ref) {
  return PostActionsNotifier(ref.watch(postRepositoryProvider));
});
