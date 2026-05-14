import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/comment_model.dart';
import '../../models/post_model.dart';
import '../post_repository.dart';

class FirestorePostRepository implements PostRepository {
  final _db = FirebaseFirestore.instance;

  PostModel _postFromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      userId: d['userId'] ?? '',
      authorName: d['authorName'] ?? '',
      authorPhotoUrl: d['authorPhotoUrl'] as String?,
      title: d['title'] ?? '',
      content: d['content'] ?? '',
      createdAt: d['createdAt'] != null
          ? (d['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      likedBy: Set<String>.from(d['likedBy'] ?? []),
      commentCount: d['commentCount'] ?? 0,
      tags: List<String>.from(d['tags'] ?? []),
      bookmarkedBy: Set<String>.from(d['bookmarkedBy'] ?? []),
    );
  }

  CommentModel _commentFromDoc(DocumentSnapshot doc, String postId) {
    final d = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      postId: postId,
      userId: d['userId'] ?? '',
      authorName: d['authorName'] ?? '',
      content: d['content'] ?? '',
      createdAt: d['createdAt'] != null
          ? (d['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  @override
  Stream<List<PostModel>> getPosts() {
    return _db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(_postFromDoc).toList());
  }

  @override
  Stream<List<PostModel>> getPostsByUser(String userId) {
    return _db
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) => s.docs.map(_postFromDoc).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  @override
  Stream<List<PostModel>> getBookmarkedPosts(String userId) {
    return _db
        .collection('posts')
        .where('bookmarkedBy', arrayContains: userId)
        .snapshots()
        .map((s) {
      final posts = s.docs.map(_postFromDoc).toList();
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return posts;
    });
  }

  @override
  Stream<List<CommentModel>> getComments(String postId) {
    return _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt')
        .snapshots()
        .map((s) => s.docs.map((d) => _commentFromDoc(d, postId)).toList());
  }

  @override
  Future<void> createPost({
    required String userId,
    required String authorName,
    required String title,
    required String content,
    List<String> tags = const [],
    String? authorPhotoUrl,
  }) async {
    await _db.collection('posts').add({
      'userId': userId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'title': title,
      'content': content,
      'tags': tags,
      'likedBy': [],
      'bookmarkedBy': [],
      'commentCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> likePost(String postId, String userId) async {
    final postRef = _db.collection('posts').doc(postId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(postRef);
      if (!snap.exists) return;
      tx.update(postRef, {
        'likedBy': FieldValue.arrayUnion([userId]),
      });
      final d = snap.data()!;
      final authorId = d['userId'] as String?;
      if (authorId != null && authorId != userId) {
        final notifRef = _db.collection('notifications').doc();
        tx.set(notifRef, {
          'targetUserId': authorId,
          'type': 'like',
          'actorId': userId,
          'actorName': '',
          'postId': postId,
          'postTitle': d['title'] ?? '',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
    // Update actorName separately (can't do async fetch inside transaction easily)
    await _updateNotificationActorName(userId, postId, 'like');
  }

  @override
  Future<void> unlikePost(String postId, String userId) async {
    await _db.collection('posts').doc(postId).update({
      'likedBy': FieldValue.arrayRemove([userId]),
    });
  }

  @override
  Future<void> bookmarkPost(String postId, String userId) async {
    await _db.collection('posts').doc(postId).update({
      'bookmarkedBy': FieldValue.arrayUnion([userId]),
    });
  }

  @override
  Future<void> unbookmarkPost(String postId, String userId) async {
    await _db.collection('posts').doc(postId).update({
      'bookmarkedBy': FieldValue.arrayRemove([userId]),
    });
  }

  @override
  Future<void> addComment({
    required String postId,
    required String userId,
    required String authorName,
    required String content,
  }) async {
    final batch = _db.batch();
    final commentRef =
        _db.collection('posts').doc(postId).collection('comments').doc();
    batch.set(commentRef, {
      'userId': userId,
      'authorName': authorName,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    });
    final postRef = _db.collection('posts').doc(postId);
    batch.update(postRef, {'commentCount': FieldValue.increment(1)});
    await batch.commit();

    // Create notification for post author
    final postSnap = await postRef.get();
    if (postSnap.exists) {
      final d = postSnap.data()!;
      final authorId = d['userId'] as String?;
      if (authorId != null && authorId != userId) {
        await _db.collection('notifications').add({
          'targetUserId': authorId,
          'type': 'comment',
          'actorId': userId,
          'actorName': authorName,
          'postId': postId,
          'postTitle': d['title'] ?? '',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  @override
  Future<void> deletePost(String postId, String userId) async {
    await _db.collection('posts').doc(postId).delete();
  }

  @override
  Future<void> deleteComment(String postId, String commentId) async {
    final batch = _db.batch();
    batch.delete(
      _db.collection('posts').doc(postId).collection('comments').doc(commentId),
    );
    batch.update(
      _db.collection('posts').doc(postId),
      {'commentCount': FieldValue.increment(-1)},
    );
    await batch.commit();
  }

  Future<void> _updateNotificationActorName(
      String actorId, String postId, String type) async {
    try {
      final userSnap =
          await _db.collection('users').doc(actorId).get();
      if (!userSnap.exists) return;
      final actorName = userSnap.data()?['displayName'] ?? '';
      final notifs = await _db
          .collection('notifications')
          .where('actorId', isEqualTo: actorId)
          .where('postId', isEqualTo: postId)
          .where('type', isEqualTo: type)
          .where('actorName', isEqualTo: '')
          .get();
      for (final d in notifs.docs) {
        await d.reference.update({'actorName': actorName});
      }
    } catch (_) {}
  }
}
