import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../models/post_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/follow_provider.dart';
import '../../../providers/post_provider.dart';
import '../../../widgets/user_avatar.dart';

const _adminUid = 'dRFL5GfO15a0fRbfmfS6uQIshvp1';

class PostCard extends ConsumerWidget {
  const PostCard({super.key, required this.post});
  final PostModel post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isLiked = user != null && post.isLikedBy(user.id);
    final isBookmarked = user != null && post.isBookmarkedBy(user.id);
    final isOwnPost = user?.id == post.userId;
    final canDelete = isOwnPost || user?.id == _adminUid;
    // 古い投稿で authorPhotoUrl がない場合、自分の投稿なら現在の photoUrl で補完
    final displayPhotoUrl = post.authorPhotoUrl ??
        (isOwnPost ? user?.photoUrl : null);
    final isFollowing = user != null && !isOwnPost
        ? ref.watch(isFollowingProvider('${user.id}::${post.userId}'))
        : false;

    return GestureDetector(
      onTap: () => context.push('/post/${post.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.push('/user/${post.userId}'),
                    child: UserAvatar(
                      photoUrl: displayPhotoUrl,
                      displayName: post.authorName,
                      radius: 16,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorName,
                          style: GoogleFonts.notoSerifJp(
                            fontSize: 13,
                            color: const Color(0xFFCCCCCC),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          DateFormat('yyyy年MM月dd日 HH:mm')
                              .format(post.createdAt),
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF666666)),
                        ),
                      ],
                    ),
                  ),
                  if (user != null && !isOwnPost)
                    GestureDetector(
                      onTap: () => ref
                          .read(followNotifierProvider.notifier)
                          .toggle(user.id, post.userId, isFollowing),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: isFollowing
                              ? Colors.transparent
                              : const Color(0xFFCC0000),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: isFollowing
                                ? const Color(0xFF444444)
                                : const Color(0xFFCC0000),
                          ),
                        ),
                        child: Text(
                          isFollowing ? 'フォロー中' : 'フォロー',
                          style: GoogleFonts.notoSerifJp(
                            fontSize: 10,
                            color: isFollowing
                                ? const Color(0xFF888888)
                                : Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                post.title,
                style: GoogleFonts.notoSerifJp(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFEEEEEE),
                  height: 1.4,
                ),
              ),
            ),
            if (post.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: post.tags
                      .map((t) => Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A0000),
                              borderRadius: BorderRadius.circular(3),
                              border:
                                  Border.all(color: const Color(0xFF3A1A1A)),
                            ),
                            child: Text(
                              t,
                              style: GoogleFonts.notoSerifJp(
                                fontSize: 10,
                                color: const Color(0xFF993333),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                post.content,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.notoSerifJp(
                  fontSize: 13,
                  color: const Color(0xFF999999),
                  height: 1.7,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(color: Color(0xFF222222), height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  _ActionButton(
                    icon: isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked
                        ? const Color(0xFFCC0000)
                        : const Color(0xFF666666),
                    label: '${post.likeCount}',
                    onTap: user == null
                        ? () => _showLoginRequired(context)
                        : () => ref
                            .read(postActionsProvider.notifier)
                            .toggleLike(post, user.id),
                  ),
                  _ActionButton(
                    icon: Icons.chat_bubble_outline,
                    color: const Color(0xFF666666),
                    label: '${post.commentCount}',
                    onTap: () => context.push('/post/${post.id}'),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.share_outlined,
                        color: Color(0xFF444444), size: 18),
                    onPressed: () => _sharePost(),
                    padding: const EdgeInsets.all(8),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: Icon(
                      isBookmarked
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      color: isBookmarked
                          ? const Color(0xFFCC0000)
                          : const Color(0xFF444444),
                      size: 18,
                    ),
                    onPressed: user == null
                        ? () => _showLoginRequired(context)
                        : () => ref
                            .read(postActionsProvider.notifier)
                            .toggleBookmark(post, user.id),
                    padding: const EdgeInsets.all(8),
                    visualDensity: VisualDensity.compact,
                  ),
                  if (canDelete) ...[
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Color(0xFF444444), size: 18),
                      onPressed: () => _confirmDelete(context, ref),
                      padding: const EdgeInsets.all(8),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sharePost() {
    final preview = post.content.length > 100
        ? '${post.content.substring(0, 100)}…'
        : post.content;
    Share.share('【${post.title}】\n$preview\n\n#百物語 #怪談');
  }

  void _showLoginRequired(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'ログインすると参加できます',
          style: GoogleFonts.notoSerifJp(fontSize: 13),
        ),
        action: SnackBarAction(
          label: 'ログイン',
          textColor: const Color(0xFFCC0000),
          onPressed: () => context.push('/login'),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
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

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(postActionsProvider.notifier).deletePost(post.id, user.id);
    } catch (_) {
      if (context.mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('削除に失敗しました')),
        );
      }
    }
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.label,
    this.onTap,
  });
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
