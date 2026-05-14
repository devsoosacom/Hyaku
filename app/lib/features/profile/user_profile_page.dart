import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/post_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/follow_provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/user_avatar.dart';

class UserProfilePage extends ConsumerWidget {
  const UserProfilePage({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final userAsync = ref.watch(userProfileProvider(userId));
    final userPostsAsync = ref.watch(userPostsProvider(userId));
    final followersAsync = ref.watch(followersProvider(userId));
    final followingAsync = ref.watch(followingProvider(userId));
    final isOwnProfile = currentUser?.id == userId;
    final isFollowing = currentUser != null && !isOwnProfile
        ? ref.watch(isFollowingProvider('${currentUser.id}::$userId'))
        : false;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF888888)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF1E1E1E)),
        ),
      ),
      body: userAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFCC0000)),
        ),
        error: (_, __) => Center(
          child: Text('読み込みエラー',
              style: GoogleFonts.notoSerifJp(color: Colors.grey)),
        ),
        data: (user) {
          if (user == null) {
            return Center(
              child: Text('ユーザーが見つかりません',
                  style: GoogleFonts.notoSerifJp(color: Colors.grey)),
            );
          }
          return ListView(
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
              if (currentUser != null && !isOwnProfile) ...[
                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: () => ref
                        .read(followNotifierProvider.notifier)
                        .toggle(currentUser.id, userId, isFollowing),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 9),
                      decoration: BoxDecoration(
                        color: isFollowing
                            ? Colors.transparent
                            : const Color(0xFFCC0000),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isFollowing
                              ? const Color(0xFF444444)
                              : const Color(0xFFCC0000),
                        ),
                      ),
                      child: Text(
                        isFollowing ? 'フォロー中' : 'フォローする',
                        style: GoogleFonts.notoSerifJp(
                          fontSize: 13,
                          color: isFollowing
                              ? const Color(0xFF888888)
                              : Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: userPostsAsync.when(
                  loading: () => const SizedBox(height: 40),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (posts) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Stat('${posts.length}', '怪談'),
                      _divider(),
                      followersAsync.when(
                        data: (s) => GestureDetector(
                          onTap: () => context.push('/followers/$userId'),
                          child: _Stat('${s.length}', 'フォロワー'),
                        ),
                        loading: () => _Stat('-', 'フォロワー'),
                        error: (_, __) => _Stat('0', 'フォロワー'),
                      ),
                      _divider(),
                      followingAsync.when(
                        data: (s) => GestureDetector(
                          onTap: () => context.push('/following/$userId'),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '投稿した怪談',
                  style: GoogleFonts.notoSerifJp(
                    fontSize: 13,
                    color: const Color(0xFF888888),
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              userPostsAsync.when(
                loading: () => const SizedBox(height: 60),
                error: (_, __) => const SizedBox.shrink(),
                data: (posts) {
                  if (posts.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'まだ怪談を投稿していません',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSerifJp(
                            color: const Color(0xFF555555), fontSize: 13),
                      ),
                    );
                  }
                  return Column(
                    children: posts.map((p) => _PostTile(post: p)).toList(),
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 40,
        color: const Color(0xFF2A2A2A),
        margin: const EdgeInsets.symmetric(horizontal: 24),
      );
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

class _PostTile extends StatelessWidget {
  const _PostTile({required this.post});
  final PostModel post;

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
                  Text(
                    DateFormat('yyyy年MM月dd日').format(post.createdAt),
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF666666)),
                  ),
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
