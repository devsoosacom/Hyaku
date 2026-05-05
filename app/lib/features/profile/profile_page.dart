import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    final userPostsAsync = ref.watch(userPostsProvider(user.id));

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
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF666666), size: 20),
            onPressed: () => _confirmSignOut(context, ref),
          ),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 32),
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: const Color(0xFF2A2A2A),
                  child: Text(
                    user.displayName.isNotEmpty ? user.displayName[0] : '?',
                    style: GoogleFonts.notoSerifJp(
                      fontSize: 32,
                      color: const Color(0xFFCC0000),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
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
                  child:
                      CircularProgressIndicator(color: Color(0xFFCC0000), strokeWidth: 2),
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (posts) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Text(
                        '${posts.length}',
                        style: GoogleFonts.notoSerifJp(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFCC0000),
                        ),
                      ),
                      Text(
                        '怪談',
                        style: GoogleFonts.notoSerifJp(
                          fontSize: 11,
                          color: const Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: const Color(0xFF2A2A2A),
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                  ),
                  Column(
                    children: [
                      Text(
                        posts.fold(0, (sum, p) => sum + p.likeCount).toString(),
                        style: GoogleFonts.notoSerifJp(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFCC0000),
                        ),
                      ),
                      Text(
                        '累計いいね',
                        style: GoogleFonts.notoSerifJp(
                          fontSize: 11,
                          color: const Color(0xFF888888),
                        ),
                      ),
                    ],
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
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    'まだ怪談を投稿していません',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSerifJp(
                      color: const Color(0xFF555555),
                      fontSize: 13,
                    ),
                  ),
                );
              }
              return Column(
                children: posts
                    .map((post) => _ProfilePostTile(
                          title: post.title,
                          date: DateFormat('yyyy年MM月dd日').format(post.createdAt),
                          likeCount: post.likeCount,
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

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('ログアウトしますか？',
            style: TextStyle(color: Color(0xFFEEEEEE))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル',
                style: TextStyle(color: Color(0xFF888888))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ログアウト',
                style: TextStyle(color: Color(0xFFCC0000))),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(authProvider.notifier).signOut();
    }
  }
}

class _ProfilePostTile extends StatelessWidget {
  const _ProfilePostTile({
    required this.title,
    required this.date,
    required this.likeCount,
  });
  final String title;
  final String date;
  final int likeCount;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  title,
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
                  date,
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
              Text(
                '$likeCount',
                style: const TextStyle(
                    color: Color(0xFF888888), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
