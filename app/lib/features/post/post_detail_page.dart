import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/post_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';

class PostDetailPage extends ConsumerStatefulWidget {
  const PostDetailPage({super.key, required this.postId});
  final String postId;

  @override
  ConsumerState<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends ConsumerState<PostDetailPage> {
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  PostModel? _findPost(List<PostModel> posts) {
    try {
      return posts.firstWhere((p) => p.id == widget.postId);
    } catch (_) {
      return null;
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
        if (post == null) {
          return Scaffold(
            backgroundColor: const Color(0xFF0A0A0A),
            appBar: AppBar(backgroundColor: const Color(0xFF0A0A0A)),
            body: const Center(
              child:
                  Text('怪談が見つかりません', style: TextStyle(color: Colors.grey)),
            ),
          );
        }

        final isLiked = user != null && post.isLikedBy(user.id);

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
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFF2A2A2A),
                            child: Text(
                              post.authorName.isNotEmpty
                                  ? post.authorName[0]
                                  : '?',
                              style: GoogleFonts.notoSerifJp(
                                fontSize: 14,
                                color: const Color(0xFFCC0000),
                                fontWeight: FontWeight.w700,
                              ),
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
                      Text(
                        post.content,
                        style: GoogleFonts.notoSerifJp(
                          fontSize: 15,
                          color: const Color(0xFFCCCCCC),
                          height: 2.0,
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
                      const SizedBox(height: 32),
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
                                .map((c) => _CommentTile(comment: c))
                                .toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF111111),
                  border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
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

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});
  final dynamic comment;

  @override
  Widget build(BuildContext context) {
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
