import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/post_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/post_provider.dart';

class PostCard extends ConsumerWidget {
  const PostCard({super.key, required this.post});
  final PostModel post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isLiked = user != null && post.isLikedBy(user.id);
    final isBookmarked = user != null && post.isBookmarkedBy(user.id);

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
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF2A2A2A),
                    child: Text(
                      post.authorName.isNotEmpty ? post.authorName[0] : '?',
                      style: GoogleFonts.notoSerifJp(
                        fontSize: 13,
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
                        ? null
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
                  if (user != null)
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
                      onPressed: () => ref
                          .read(postActionsProvider.notifier)
                          .toggleBookmark(post, user.id),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  if (user?.id == post.userId) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Color(0xFF444444), size: 18),
                      onPressed: () => _confirmDelete(context, ref),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
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

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('削除しますか？',
            style: TextStyle(color: Color(0xFFEEEEEE))),
        content: const Text('この怪談を削除します。元に戻せません。',
            style: TextStyle(color: Color(0xFF888888))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル',
                style: TextStyle(color: Color(0xFF888888))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除',
                style: TextStyle(color: Color(0xFFCC0000))),
          ),
        ],
      ),
    );
    if (ok == true) {
      ref.read(postActionsProvider.notifier).deletePost(post.id, user.id);
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
