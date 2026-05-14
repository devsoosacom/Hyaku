import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/post_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/user_avatar.dart';
import '../../providers/follow_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/post_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    final userPostsAsync = ref.watch(userPostsProvider(user.id));
    final bookmarkedAsync = ref.watch(bookmarkedPostsProvider(user.id));
    final unreadCount = ref.watch(unreadCountProvider(user.id));
    final followersAsync = ref.watch(followersProvider(user.id));
    final followingAsync = ref.watch(followingProvider(user.id));

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        title: Text(
          'マイページ',
          style: GoogleFonts.notoSerifJp(
            fontSize: 18,
            color: const Color(0xFFEEEEEE),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF1E1E1E)),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: Color(0xFF888888), size: 22),
                onPressed: () => context.push('/notifications'),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFFCC0000),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: Color(0xFF888888), size: 20),
            onPressed: () => context.push('/profile/edit'),
          ),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 32),
          Center(
            child: UserAvatar(
              photoUrl: user.photoUrl,
              displayName: user.displayName,
              radius: 44,
              fontSize: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.displayName,
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSerifJp(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFEEEEEE),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF666666), fontSize: 13),
          ),
          if (user.bio != null && user.bio!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                user.bio!,
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSerifJp(
                  fontSize: 13,
                  color: const Color(0xFF999999),
                  height: 1.6,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          // Stats row
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: userPostsAsync.when(
              loading: () => const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Color(0xFFCC0000), strokeWidth: 2),
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (posts) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Stat('${posts.length}', '怪談'),
                  _divider(),
                  followersAsync.when(
                    data: (s) => GestureDetector(
                      onTap: () => context.push('/followers/${user.id}'),
                      child: _Stat('${s.length}', 'フォロワー'),
                    ),
                    loading: () => _Stat('-', 'フォロワー'),
                    error: (_, __) => _Stat('0', 'フォロワー'),
                  ),
                  _divider(),
                  followingAsync.when(
                    data: (s) => GestureDetector(
                      onTap: () => context.push('/following/${user.id}'),
                      child: _Stat('${s.length}', 'フォロー中'),
                    ),
                    loading: () => _Stat('-', 'フォロー中'),
                    error: (_, __) => _Stat('0', 'フォロー中'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          // My posts
          _SectionHeader('投稿した怪談'),
          const SizedBox(height: 12),
          userPostsAsync.when(
            loading: () => const SizedBox(height: 60),
            error: (_, __) => const SizedBox.shrink(),
            data: (posts) {
              if (posts.isEmpty) {
                return _EmptyMessage('まだ怪談を投稿していません');
              }
              return Column(
                children: posts
                    .map((p) => _PostTile(
                          post: p,
                          date: DateFormat('yyyy年MM月dd日').format(p.createdAt),
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 32),
          // Bookmarks
          _SectionHeader('保存した怪談'),
          const SizedBox(height: 12),
          bookmarkedAsync.when(
            loading: () => const SizedBox(height: 60),
            error: (_, __) => const SizedBox.shrink(),
            data: (posts) {
              if (posts.isEmpty) {
                return _EmptyMessage('保存した怪談はありません');
              }
              return Column(
                children: posts
                    .map((p) => _PostTile(
                          post: p,
                          date: DateFormat('yyyy年MM月dd日').format(p.createdAt),
                          isBookmark: true,
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: OutlinedButton(
              onPressed: () => _confirmSignOut(context, ref),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF888888),
                side: const BorderSide(color: Color(0xFF333333)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
              ),
              child: Text(
                'ログアウト',
                style: GoogleFonts.notoSerifJp(fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 40,
        color: const Color(0xFF2A2A2A),
        margin: const EdgeInsets.symmetric(horizontal: 24),
      );

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('ログアウトしますか？',
            style: TextStyle(color: Color(0xFFEEEEEE))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('キャンセル',
                style: TextStyle(color: Color(0xFF888888))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('ログアウト',
                style: TextStyle(color: Color(0xFFCC0000))),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final router = GoRouter.of(context);
    await ref.read(authProvider.notifier).signOut();
    router.go('/login');
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.notoSerifJp(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFCC0000),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.notoSerifJp(
              fontSize: 10, color: const Color(0xFF888888)),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        text,
        style: GoogleFonts.notoSerifJp(
          fontSize: 13,
          color: const Color(0xFF888888),
          letterSpacing: 1,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.notoSerifJp(
            color: const Color(0xFF555555), fontSize: 13),
      ),
    );
  }
}

class _PostTile extends StatelessWidget {
  const _PostTile({
    required this.post,
    required this.date,
    this.isBookmark = false,
  });
  final PostModel post;
  final String date;
  final bool isBookmark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/post/${post.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF222222)),
        ),
        child: Row(
          children: [
            if (isBookmark)
              const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(Icons.bookmark, color: Color(0xFFCC0000), size: 14),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: GoogleFonts.notoSerifJp(
                      fontSize: 14,
                      color: const Color(0xFFDDDDDD),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(date,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF666666))),
                ],
              ),
            ),
            Row(
              children: [
                const Icon(Icons.favorite, color: Color(0xFFCC0000), size: 14),
                const SizedBox(width: 4),
                Text('${post.likeCount}',
                    style: const TextStyle(
                        color: Color(0xFF888888), fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
