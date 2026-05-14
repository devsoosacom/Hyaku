import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/post_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/ad_banner.dart';
import '../../utils/meta_tags_stub.dart'
    if (dart.library.js_interop) '../../utils/meta_tags_impl.dart';

class PostDetailPage extends ConsumerStatefulWidget {
  const PostDetailPage({super.key, required this.postId});
  final String postId;

  @override
  ConsumerState<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends ConsumerState<PostDetailPage> {
  final _commentCtrl = TextEditingController();
  bool _submitting = false;
  String? _metaPostId;

  @override
  void dispose() {
    _commentCtrl.dispose();
    resetPageMeta();
    super.dispose();
  }

  PostModel? _findPost(List<PostModel> posts) {
    try {
      return posts.firstWhere((p) => p.id == widget.postId);
    } catch (_) {
      return null;
    }
  }

  void _showShareSheet(BuildContext context, PostModel post) {
    final url = 'https://hyaku-35692.web.app/post/${post.id}';
    final text = '【${post.title}】 #百物語 #怪談\n$url';
    final twitterUrl = 'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(text)}';
    final lineUrl = 'https://line.me/R/msg/text/?${Uri.encodeComponent(text)}';

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF444444),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _ShareTile(
              icon: Icons.close,
              iconColor: const Color(0xFF1DA1F2),
              label: 'X (Twitter) でシェア',
              onTap: () { Navigator.pop(context); launchUrl(Uri.parse(twitterUrl), mode: LaunchMode.externalApplication); },
            ),
            _ShareTile(
              icon: Icons.chat_bubble,
              iconColor: const Color(0xFF00B900),
              label: 'LINE でシェア',
              onTap: () { Navigator.pop(context); launchUrl(Uri.parse(lineUrl), mode: LaunchMode.externalApplication); },
            ),
            _ShareTile(
              icon: Icons.link,
              iconColor: const Color(0xFF888888),
              label: 'URLをコピー',
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: url));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('URLをコピーしました'), duration: Duration(seconds: 2)),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('削除しますか？',
            style: TextStyle(color: Color(0xFFEEEEEE))),
        content: const Text('この怪談を削除します。元に戻せません。',
            style: TextStyle(color: Color(0xFF888888))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('キャンセル',
                style: TextStyle(color: Color(0xFF888888))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('削除',
                style: TextStyle(color: Color(0xFFCC0000))),
          ),
        ],
      ),
    );

    if (ok != true) return;

    // async gap 前に参照を保存
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref.read(postActionsProvider.notifier)
          .deletePost(widget.postId, user.id);
      if (mounted) {
        if (router.canPop()) {
          router.pop();
        } else {
          router.go('/feed');
        }
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('削除に失敗しました')),
        );
      }
    }
  }

  Future<void> _submitComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _submitting = true);
    try {
      await ref.read(postActionsProvider.notifier).addComment(
            postId: widget.postId,
            userId: user.id,
            authorName: user.displayName,
            content: text,
          );
      _commentCtrl.clear();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(postsProvider);
    final commentsAsync = ref.watch(commentsProvider(widget.postId));
    final user = ref.watch(currentUserProvider);

    return postsAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFCC0000))),
      ),
      error: (e, _) => const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(child: Text('エラー', style: TextStyle(color: Colors.grey))),
      ),
      data: (posts) {
        final post = _findPost(posts);
        if (post != null && _metaPostId != post.id) {
          _metaPostId = post.id;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final desc = post.content.length > 150
                ? '${post.content.substring(0, 150)}…'
                : post.content;
            final cleanDesc = desc.replaceAll('\n', ' ');
            final url = 'https://hyaku-35692.web.app/post/${post.id}';
            updatePageMeta('${post.title} | 百物語', cleanDesc, url);
            updateArticleLd(
              post.title,
              cleanDesc,
              url,
              post.createdAt.toIso8601String(),
              post.authorName,
            );
          });
        }
        if (post == null) {
          // 投稿が消えた（削除された）ら次フレームで戻る
          // pop() はスタックをそのまま戻るため ShellRoute 境界を壊さない
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/feed');
              }
            }
          });
          return const Scaffold(
            backgroundColor: Color(0xFF0A0A0A),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFCC0000)),
            ),
          );
        }

        final isLiked = user != null && post.isLikedBy(user.id);
        final isOwnPost = user?.id == post.userId;
        const adminUid = 'dRFL5GfO15a0fRbfmfS6uQIshvp1';
        final canDelete = isOwnPost || user?.id == adminUid;
        final displayPhotoUrl = post.authorPhotoUrl ??
            (isOwnPost ? user?.photoUrl : null);

        return Scaffold(
          backgroundColor: const Color(0xFF0A0A0A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0A0A0A),
            elevation: 0,
            iconTheme: const IconThemeData(color: Color(0xFF888888)),
            title: Text(
              '怪談',
              style: GoogleFonts.notoSerifJp(
                fontSize: 16,
                color: const Color(0xFF888888),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined,
                    color: Color(0xFF888888), size: 20),
                onPressed: () => _showShareSheet(context, post),
              ),
              if (canDelete)
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Color(0xFF888888), size: 20),
                  onPressed: () => _confirmDelete(context),
                ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: const Color(0xFF1E1E1E)),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => context.push('/user/${post.userId}'),
                            child: UserAvatar(
                              photoUrl: displayPhotoUrl,
                              displayName: post.authorName,
                              radius: 18,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.authorName,
                                style: GoogleFonts.notoSerifJp(
                                  fontSize: 14,
                                  color: const Color(0xFFCCCCCC),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                DateFormat('yyyy年MM月dd日 HH:mm')
                                    .format(post.createdAt),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF666666),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        post.title,
                        style: GoogleFonts.notoSerifJp(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFEEEEEE),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      MarkdownBody(
                        data: post.content,
                        styleSheet: MarkdownStyleSheet(
                          p: GoogleFonts.notoSerifJp(
                            fontSize: 15,
                            color: const Color(0xFFCCCCCC),
                            height: 2.0,
                          ),
                          horizontalRuleDecoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: Color(0xFF333333),
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (post.tags.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          children: post.tags
                              .map((t) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A0000),
                                      borderRadius: BorderRadius.circular(3),
                                      border: Border.all(
                                          color: const Color(0xFF3A1A1A)),
                                    ),
                                    child: Text(
                                      t,
                                      style: GoogleFonts.notoSerifJp(
                                        fontSize: 11,
                                        color: const Color(0xFF993333),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: user == null
                                ? null
                                : () => ref
                                    .read(postActionsProvider.notifier)
                                    .toggleLike(post, user.id),
                            child: Row(
                              children: [
                                Icon(
                                  isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isLiked
                                      ? const Color(0xFFCC0000)
                                      : const Color(0xFF666666),
                                  size: 22,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${post.likeCount}',
                                  style: TextStyle(
                                    color: isLiked
                                        ? const Color(0xFFCC0000)
                                        : const Color(0xFF666666),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Row(
                            children: [
                              const Icon(Icons.chat_bubble_outline,
                                  color: Color(0xFF666666), size: 20),
                              const SizedBox(width: 6),
                              Text(
                                '${post.commentCount}',
                                style: const TextStyle(
                                    color: Color(0xFF666666), fontSize: 14),
                              ),
                            ],
                          ),
                          const Spacer(),
                          if (user != null)
                            GestureDetector(
                              onTap: () => ref
                                  .read(postActionsProvider.notifier)
                                  .toggleBookmark(post, user.id),
                              child: Icon(
                                post.isBookmarkedBy(user.id)
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color: post.isBookmarkedBy(user.id)
                                    ? const Color(0xFFCC0000)
                                    : const Color(0xFF666666),
                                size: 22,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const AdBannerWidget(height: 120),
                      const SizedBox(height: 24),
                      Container(
                        height: 1,
                        color: const Color(0xFF2A2A2A),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'コメント',
                        style: GoogleFonts.notoSerifJp(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF888888),
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      commentsAsync.when(
                        loading: () => const SizedBox(
                          height: 40,
                          child: Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFFCC0000), strokeWidth: 2),
                          ),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (comments) {
                          if (comments.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                'まだコメントはありません',
                                style: GoogleFonts.notoSerifJp(
                                  color: const Color(0xFF555555),
                                  fontSize: 13,
                                ),
                              ),
                            );
                          }
                          return Column(
                            children: comments
                                .map((c) => _CommentTile(
                                      comment: c,
                                      postId: widget.postId,
                                    ))
                                .toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              if (user == null)
                GestureDetector(
                  onTap: () => context.push('/login'),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F0F0F),
                      border:
                          Border(top: BorderSide(color: Color(0xFF2A2A2A))),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.login,
                            color: Color(0xFF666666), size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'ログインしてコメントに参加する',
                          style: GoogleFonts.notoSerifJp(
                            fontSize: 13,
                            color: const Color(0xFF888888),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF111111),
                    border:
                        Border(top: BorderSide(color: Color(0xFF2A2A2A))),
                  ),
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 12,
                    top: 10,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentCtrl,
                          style: GoogleFonts.notoSerifJp(
                            fontSize: 14,
                            color: const Color(0xFFEEEEEE),
                          ),
                          decoration: InputDecoration(
                            hintText: 'コメントを追加...',
                            hintStyle: GoogleFonts.notoSerifJp(
                              fontSize: 14,
                              color: const Color(0xFF555555),
                            ),
                            filled: true,
                            fillColor: const Color(0xFF1A1A1A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _submitComment(),
                          maxLines: null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _submitting ? null : _submitComment,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFFCC0000),
                            shape: BoxShape.circle,
                          ),
                          child: _submitting
                              ? const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.send,
                                  color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CommentTile extends ConsumerWidget {
  const _CommentTile({required this.comment, required this.postId});
  final dynamic comment;
  final String postId;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('コメントを削除しますか？',
            style: TextStyle(color: Color(0xFFEEEEEE))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('キャンセル',
                style: TextStyle(color: Color(0xFF888888))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('削除',
                style: TextStyle(color: Color(0xFFCC0000))),
          ),
        ],
      ),
    );
    if (ok == true) {
      ref.read(postActionsProvider.notifier).deleteComment(postId, comment.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final isOwn = currentUser?.id == comment.userId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFF2A2A2A),
            child: Text(
              comment.authorName.isNotEmpty ? comment.authorName[0] : '?',
              style: GoogleFonts.notoSerifJp(
                fontSize: 11,
                color: const Color(0xFFCC0000),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.authorName,
                      style: GoogleFonts.notoSerifJp(
                        fontSize: 12,
                        color: const Color(0xFFAAAAAA),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MM/dd HH:mm').format(comment.createdAt),
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF555555)),
                    ),
                    const Spacer(),
                    if (isOwn)
                      GestureDetector(
                        onTap: () => _delete(context, ref),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.delete_outline,
                              size: 14, color: Color(0xFF555555)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: GoogleFonts.notoSerifJp(
                    fontSize: 13,
                    color: const Color(0xFFCCCCCC),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareTile extends StatelessWidget {
  const _ShareTile({required this.icon, required this.iconColor, required this.label, required this.onTap});
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(label, style: GoogleFonts.notoSerifJp(fontSize: 14, color: const Color(0xFFEEEEEE))),
      onTap: onTap,
    );
  }
}
