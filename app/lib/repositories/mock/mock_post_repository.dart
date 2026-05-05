import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../models/comment_model.dart';
import '../../models/post_model.dart';
import '../post_repository.dart';

class MockPostRepository implements PostRepository {
  static const _uuid = Uuid();

  final _postsController = StreamController<List<PostModel>>.broadcast();
  final _commentControllers = <String, StreamController<List<CommentModel>>>{};

  List<PostModel> _posts = [];
  final Map<String, List<CommentModel>> _comments = {};

  MockPostRepository() {
    _posts = _seedPosts();
    Future.microtask(() => _postsController.add(_posts));
  }

  List<PostModel> _seedPosts() {
    final now = DateTime.now();
    return [
      PostModel(
        id: 'seed-1',
        userId: 'seed-user',
        authorName: '怪談師 鬼灯',
        title: '変な日記',
        content: '去年の秋、私のアパートに見知らぬ荷物が届いた。\n\n宛名は私の名前と正確な住所。差出人欄は空白だった。中身はノート一冊。最初のページには日付と短い文章があった。\n\n「4月3日。7時15分、彼は起きた。今日は髪を洗った。」\n\n私がこのアパートに引っ越してきた日と、日付が一致していた。',
        createdAt: now.subtract(const Duration(hours: 3)),
        likedBy: {'seed-user2', 'seed-user3'},
        commentCount: 2,
      ),
      PostModel(
        id: 'seed-2',
        userId: 'seed-user2',
        authorName: '夜語り べる',
        title: '変な写真',
        content: 'リサイクルショップで古いデジタルカメラを買った。三千円。メモリーカードがそのまま残っていた。\n\n中に四百三十二枚の写真があった。すべて同じ場所を撮っていた。\n\n最初の一枚は十一年前。最後の一枚は三か月前。\n\nそして夫は五年前に亡くなっている。',
        createdAt: now.subtract(const Duration(hours: 8)),
        likedBy: {'seed-user', 'seed-user3', 'seed-user4'},
        commentCount: 5,
      ),
      PostModel(
        id: 'seed-3',
        userId: 'seed-user3',
        authorName: '闇語り ゆらぎ',
        title: '変な録音',
        content: 'スマートフォンのボイスメモに、覚えのないファイルがあった。録音時間は二時間十七分。\n\n再生すると二人の会話が始まった。一人は私の声だとわかった。もう一人は聞き覚えのない男性の声。\n\nカフェで場所を特定し、スタッフに聞いた。\n\n「いつもお一人ですよ」',
        createdAt: now.subtract(const Duration(days: 1)),
        likedBy: {'seed-user', 'seed-user2'},
        commentCount: 3,
      ),
      PostModel(
        id: 'seed-4',
        userId: 'seed-user4',
        authorName: '語り部 とおの',
        title: '真夜中の訪問者',
        content: '毎晩0時過ぎに、玄関の外で足音がする。\n\nドアを開けると、誰もいない。\n\n三週間続いたある夜、ドアスコープから外を見た。\n\n廊下に人が立っていた。こちらを向いていた。\n\nそして私も気づいた。外から誰かがドアスコープを覗いていたことに。',
        createdAt: now.subtract(const Duration(days: 2)),
        likedBy: {'seed-user', 'seed-user2', 'seed-user3', 'seed-user5'},
        commentCount: 8,
      ),
      PostModel(
        id: 'seed-5',
        userId: 'seed-user5',
        authorName: '夜半 かなえ',
        title: '祖母の電話',
        content: '祖母が亡くなったのは三年前の冬だ。\n\n先週、祖母の番号から着信があった。\n\n出ると、祖母の声だった。\n\n「ちゃんと食べてる？」\n\n一言だけ言って、切れた。\n\n通話履歴を確認すると、その番号への着信記録はなかった。',
        createdAt: now.subtract(const Duration(days: 3)),
        likedBy: {'seed-user', 'seed-user3'},
        commentCount: 4,
      ),
    ];
  }

  void _notifyPosts() => _postsController.add(List.unmodifiable(_posts));

  void _notifyComments(String postId) {
    final ctrl = _commentControllers[postId];
    if (ctrl != null) {
      ctrl.add(List.unmodifiable(_comments[postId] ?? []));
    }
  }

  @override
  Stream<List<PostModel>> getPosts() {
    Future.microtask(() => _postsController.add(List.unmodifiable(_posts)));
    return _postsController.stream;
  }

  @override
  Stream<List<PostModel>> getPostsByUser(String userId) {
    return _postsController.stream.map(
      (posts) => posts.where((p) => p.userId == userId).toList(),
    );
  }

  @override
  Stream<List<CommentModel>> getComments(String postId) {
    _commentControllers.putIfAbsent(
      postId,
      () => StreamController<List<CommentModel>>.broadcast(),
    );
    Future.microtask(
      () => _notifyComments(postId),
    );
    return _commentControllers[postId]!.stream;
  }

  @override
  Future<void> createPost({
    required String userId,
    required String authorName,
    required String title,
    required String content,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final post = PostModel(
      id: _uuid.v4(),
      userId: userId,
      authorName: authorName,
      title: title,
      content: content,
      createdAt: DateTime.now(),
    );
    _posts = [post, ..._posts];
    _notifyPosts();
  }

  @override
  Future<void> likePost(String postId, String userId) async {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final post = _posts[idx];
    final updated = post.copyWith(
      likedBy: {...post.likedBy, userId},
    );
    _posts = [..._posts]..[idx] = updated;
    _notifyPosts();
  }

  @override
  Future<void> unlikePost(String postId, String userId) async {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final post = _posts[idx];
    final updated = post.copyWith(
      likedBy: post.likedBy.difference({userId}),
    );
    _posts = [..._posts]..[idx] = updated;
    _notifyPosts();
  }

  @override
  Future<void> addComment({
    required String postId,
    required String userId,
    required String authorName,
    required String content,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final comment = CommentModel(
      id: _uuid.v4(),
      postId: postId,
      userId: userId,
      authorName: authorName,
      content: content,
      createdAt: DateTime.now(),
    );
    _comments[postId] = [
      ...(_comments[postId] ?? []),
      comment,
    ];
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      final post = _posts[idx];
      final updated =
          post.copyWith(commentCount: post.commentCount + 1);
      _posts = [..._posts]..[idx] = updated;
      _notifyPosts();
    }
    _notifyComments(postId);
  }

  @override
  Future<void> deletePost(String postId, String userId) async {
    _posts = _posts.where((p) => !(p.id == postId && p.userId == userId)).toList();
    _notifyPosts();
  }
}
