import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/post_provider.dart';
import 'widgets/post_card.dart';

class FeedPage extends ConsumerWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        title: Text(
          '百物語',
          style: GoogleFonts.notoSerifJp(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFCC0000),
            letterSpacing: 4,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF1E1E1E)),
        ),
      ),
      body: postsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFCC0000)),
        ),
        error: (e, _) => Center(
          child: Text('エラーが発生しました', style: TextStyle(color: Colors.grey[600])),
        ),
        data: (posts) {
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_stories,
                      size: 48, color: Colors.grey[800]),
                  const SizedBox(height: 16),
                  Text(
                    'まだ怪談がありません',
                    style: GoogleFonts.notoSerifJp(
                      color: Colors.grey[600],
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '最初の一話を語りましょう',
                    style: GoogleFonts.notoSerifJp(
                      color: Colors.grey[700],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            color: const Color(0xFFCC0000),
            backgroundColor: const Color(0xFF1A1A1A),
            onRefresh: () async {
              ref.invalidate(postsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: posts.length,
              itemBuilder: (_, i) => PostCard(post: posts[i]),
            ),
          );
        },
      ),
    );
  }
}
