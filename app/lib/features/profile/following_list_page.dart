import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/follow_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/user_avatar.dart';

class FollowingListPage extends ConsumerWidget {
  const FollowingListPage({
    super.key,
    required this.userId,
    this.showFollowers = false,
  });
  final String userId;
  final bool showFollowers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followingAsync = showFollowers
        ? ref.watch(followersProvider(userId))
        : ref.watch(followingProvider(userId));

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF888888)),
        title: Text(
          showFollowers ? 'フォロワー' : 'フォロー中',
          style: GoogleFonts.notoSerifJp(
            fontSize: 16,
            color: const Color(0xFFEEEEEE),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF1E1E1E)),
        ),
      ),
      body: followingAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFCC0000)),
        ),
        error: (_, __) => Center(
          child: Text('読み込みエラー',
              style: GoogleFonts.notoSerifJp(color: Colors.grey)),
        ),
        data: (userIds) {
          if (userIds.isEmpty) {
            return Center(
              child: Text(
                showFollowers ? 'フォロワーはいません' : 'フォロー中のユーザーはいません',
                style: GoogleFonts.notoSerifJp(
                    color: const Color(0xFF555555), fontSize: 14),
              ),
            );
          }
          return ListView.builder(
            itemCount: userIds.length,
            itemBuilder: (context, index) {
              final uid = userIds.elementAt(index);
              return _UserRow(userId: uid);
            },
          );
        },
      ),
    );
  }
}

class _UserRow extends ConsumerWidget {
  const _UserRow({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider(userId));
    return userAsync.when(
      loading: () => const SizedBox(
        height: 64,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child:
                CircularProgressIndicator(color: Color(0xFFCC0000), strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        return GestureDetector(
          onTap: () => context.push('/user/$userId'),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: Color(0xFF1A1A1A))),
            ),
            child: Row(
              children: [
                UserAvatar(
                  photoUrl: user.photoUrl,
                  displayName: user.displayName,
                  radius: 22,
                  fontSize: 16,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: GoogleFonts.notoSerifJp(
                          fontSize: 14,
                          color: const Color(0xFFEEEEEE),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (user.bio != null && user.bio!.isNotEmpty)
                        Text(
                          user.bio!,
                          style: GoogleFonts.notoSerifJp(
                              fontSize: 11, color: const Color(0xFF777777)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: Color(0xFF444444), size: 18),
              ],
            ),
          ),
        );
      },
    );
  }
}
