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
        content:
            '去年の秋、私のアパートに見知らぬ荷物が届いた。\n\n宛名は私の名前と正確な住所。差出人欄は空白だった。中身はノート一冊。最初のページには日付と短い文章があった。\n\n「4月3日。7時15分、彼は起きた。今日は髪を洗った。」\n\n私がこのアパートに引っ越してきた日と、日付が一致していた。',
        createdAt: now.subtract(const Duration(hours: 3)),
        likedBy: {'seed-user2', 'seed-user3'},
        commentCount: 2,
        tags: ['体験談', '不思議'],
      ),
      PostModel(
        id: 'seed-2',
        userId: 'seed-user2',
        authorName: '夜語り べる',
        title: '変な写真',
        content:
            'リサイクルショップで古いデジタルカメラを買った。三千円。メモリーカードがそのまま残っていた。\n\n中に四百三十二枚の写真があった。すべて同じ場所を撮っていた。\n\n最初の一枚は十一年前。最後の一枚は三か月前。\n\nそして夫は五年前に亡くなっている。',
        createdAt: now.subtract(const Duration(hours: 8)),
        likedBy: {'seed-user', 'seed-user3', 'seed-user4'},
        commentCount: 5,
        tags: ['体験談', '心霊'],
      ),
      PostModel(
        id: 'seed-3',
        userId: 'seed-user3',
        authorName: '闇語り ゆらぎ',
        title: '変な録音',
        content:
            'スマートフォンのボイスメモに、覚えのないファイルがあった。録音時間は二時間十七分。\n\n再生すると二人の会話が始まった。一人は私の声だとわかった。もう一人は聞き覚えのない男性の声。\n\nカフェで場所を特定し、スタッフに聞いた。\n\n「いつもお一人ですよ」',
        createdAt: now.subtract(const Duration(days: 1)),
        likedBy: {'seed-user', 'seed-user2'},
        commentCount: 3,
        tags: ['体験談', '不思議'],
      ),
      PostModel(
        id: 'seed-4',
        userId: 'seed-user4',
        authorName: '語り部 とおの',
        title: '真夜中の訪問者',
        content:
            '毎晩0時過ぎに、玄関の外で足音がする。\n\nドアを開けると、誰もいない。\n\n三週間続いたある夜、ドアスコープから外を見た。\n\n廊下に人が立っていた。こちらを向いていた。\n\nそして私も気づいた。外から誰かがドアスコープを覗いていたことに。',
        createdAt: now.subtract(const Duration(days: 2)),
        likedBy: {'seed-user', 'seed-user2', 'seed-user3', 'seed-user5'},
        commentCount: 8,
        tags: ['心霊', '怪談'],
      ),
      PostModel(
        id: 'seed-5',
        userId: 'seed-user5',
        authorName: '夜半 かなえ',
        title: '祖母の電話',
        content:
            '祖母が亡くなったのは三年前の冬だ。\n\n先週、祖母の番号から着信があった。\n\n出ると、祖母の声だった。\n\n「ちゃんと食べてる？」\n\n一言だけ言って、切れた。\n\n通話履歴を確認すると、その番号への着信記録はなかった。',
        createdAt: now.subtract(const Duration(days: 3)),
        likedBy: {'seed-user', 'seed-user3'},
        commentCount: 4,
        tags: ['心霊', '体験談'],
      ),
      PostModel(
        id: 'seed-6',
        userId: 'seed-user2',
        authorName: '夜語り べる',
        title: '消えた隣人',
        content:
            '引っ越し先のマンションで隣の部屋の住人と挨拶を交わした。三十代くらいの男性で、名前は田中と名乗った。\n\n翌週、管理人に「隣の田中さんに荷物が届いたので」と声をかけた。\n\n管理人は首を傾げた。\n\n「そちらの部屋は三年前から空き家ですよ」',
        createdAt: now.subtract(const Duration(days: 5)),
        likedBy: {'seed-user', 'seed-user4', 'seed-user5'},
        commentCount: 6,
        tags: ['都市伝説', '不思議'],
      ),
      PostModel(
        id: 'seed-7',
        userId: 'seed-user3',
        authorName: '闇語り ゆらぎ',
        title: '鏡の中の自分',
        content:
            '洗面所の鏡を見るたびに、違和感があった。\n\n最初は気のせいだと思っていた。\n\n一週間後、ようやく気づいた。\n\n鏡の中の自分が、右手を上げるとき、左手を上げていた。\n\nいや——正確には、私が左手を上げているのに、鏡の中では右手が上がっていた。',
        createdAt: now.subtract(const Duration(days: 7)),
        likedBy: {'seed-user2', 'seed-user5'},
        commentCount: 9,
        tags: ['不思議', '心霊'],
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
  Stream<List<PostModel>> getBookmarkedPosts(String userId) {
    return _postsController.stream.map(
      (posts) => posts.where((p) => p.isBookmarkedBy(userId)).toList(),
    );
  }

  @override
  Stream<List<CommentModel>> getComments(String postId) {
    _commentControllers.putIfAbsent(
      postId,
      () => StreamController<List<CommentModel>>.broadcast(),
    );
    Future.microtask(() => _notifyComments(postId));
    return _commentControllers[postId]!.stream;
  }

  @override
  Future<void> createPost({
    required String userId,
    required String authorName,
    required String title,
    required String content,
    List<String> tags = const [],
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final post = PostModel(
      id: _uuid.v4(),
      userId: userId,
      authorName: authorName,
      title: title,
      content: content,
      createdAt: DateTime.now(),
      tags: tags,
    );
    _posts = [post, ..._posts];
    _notifyPosts();
  }

  @override
  Future<void> likePost(String postId, String userId) async {
    _updatePost(postId, (p) => p.copyWith(likedBy: {...p.likedBy, userId}));
  }

  @override
  Future<void> unlikePost(String postId, String userId) async {
    _updatePost(
        postId, (p) => p.copyWith(likedBy: p.likedBy.difference({userId})));
  }

  @override
  Future<void> bookmarkPost(String postId, String userId) async {
    _updatePost(postId,
        (p) => p.copyWith(bookmarkedBy: {...p.bookmarkedBy, userId}));
  }

  @override
  Future<void> unbookmarkPost(String postId, String userId) async {
    _updatePost(
        postId,
        (p) =>
            p.copyWith(bookmarkedBy: p.bookmarkedBy.difference({userId})));
  }

  void _updatePost(String postId, PostModel Function(PostModel) updater) {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    _posts = [..._posts]..[idx] = updater(_posts[idx]);
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
    _comments[postId] = [...(_comments[postId] ?? []), comment];
    _updatePost(
        postId, (p) => p.copyWith(commentCount: p.commentCount + 1));
    _notifyComments(postId);
  }

  @override
  Future<void> deletePost(String postId, String userId) async {
    _posts =
        _posts.where((p) => !(p.id == postId && p.userId == userId)).toList();
    _notifyPosts();
  }

  @override
  Future<void> deleteComment(String postId, String commentId) async {
    final list = _comments[postId];
    if (list == null) return;
    _comments[postId] = list.where((c) => c.id != commentId).toList();
    _commentControllers[postId]?.add(_comments[postId]!);
  }
}
