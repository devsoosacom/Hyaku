import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/follow_provider.dart';
import '../../models/post_model.dart';
import '../../providers/post_provider.dart';
import '../../widgets/ad_banner.dart';
import 'widgets/post_card.dart';

final _feedTabProvider = StateProvider<int>((ref) => 0);

enum FeedSort { newest, popular, weekly, monthly }

final _feedSortProvider = StateProvider<FeedSort>((ref) => FeedSort.newest);
final _feedTagProvider = StateProvider<String?>((ref) => null);

class FeedPage extends ConsumerWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postsProvider);
    final currentUser = ref.watch(currentUserProvider);
    final tab = ref.watch(_feedTabProvider);
    final sort = ref.watch(_feedSortProvider);
    final selectedTag = ref.watch(_feedTagProvider);

    final followingAsync = currentUser != null
        ? ref.watch(followingProvider(currentUser.id))
        : null;

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
          preferredSize: const Size.fromHeight(80),
          child: Column(
            children: [
              Container(height: 1, color: const Color(0xFF1E1E1E)),
              // タブ行
              SizedBox(
                height: 40,
                child: Row(
                  children: [
                    _Tab(
                      label: '全て',
                      selected: tab == 0,
                      onTap: () =>
                          ref.read(_feedTabProvider.notifier).state = 0,
                    ),
                    _Tab(
                      label: 'フォロー中',
                      selected: tab == 1,
                      onTap: () =>
                          ref.read(_feedTabProvider.notifier).state = 1,
                    ),
                  ],
                ),
              ),
              // ソート行
              SizedBox(
                height: 38,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: FeedSort.values.map((s) {
                      return _SortChip(
                        label: _sortLabel(s),
                        icon: _sortIcon(s),
                        selected: sort == s,
                        onTap: () =>
                            ref.read(_feedSortProvider.notifier).state = s,
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: postsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFCC0000)),
        ),
        error: (e, _) => Center(
          child: Text('エラーが発生しました',
              style: TextStyle(color: Colors.grey[600])),
        ),
        data: (allPosts) {
          // タブフィルタ
          var posts = (tab == 1 && currentUser != null)
              ? followingAsync?.valueOrNull != null
                  ? allPosts
                      .where((p) =>
                          followingAsync!.valueOrNull!.contains(p.userId))
                      .toList()
                  : <PostModel>[]
              : List<PostModel>.from(allPosts);

          // タグフィルタ
          if (selectedTag != null) {
            posts = posts.where((p) => p.tags.contains(selectedTag)).toList();
          }

          // ソート
          final now = DateTime.now();
          switch (sort) {
            case FeedSort.newest:
              break;
            case FeedSort.popular:
              posts.sort((a, b) => b.likeCount.compareTo(a.likeCount));
            case FeedSort.weekly:
              final cutoff = now.subtract(const Duration(days: 7));
              posts =
                  posts.where((p) => p.createdAt.isAfter(cutoff)).toList();
              posts.sort((a, b) => b.likeCount.compareTo(a.likeCount));
            case FeedSort.monthly:
              final cutoff = now.subtract(const Duration(days: 30));
              posts =
                  posts.where((p) => p.createdAt.isAfter(cutoff)).toList();
              posts.sort((a, b) => b.likeCount.compareTo(a.likeCount));
          }

          // 人気タグを抽出
          final tagFreq = <String, int>{};
          for (final p in allPosts) {
            for (final t in p.tags) {
              tagFreq[t] = (tagFreq[t] ?? 0) + 1;
            }
          }
          final popularTags = tagFreq.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          if (posts.isEmpty) {
            return Column(
              children: [
                if (popularTags.isNotEmpty)
                  _TagFilterBar(
                    tags: popularTags.take(15).map((e) => e.key).toList(),
                    selectedTag: selectedTag,
                    onTagSelected: (t) =>
                        ref.read(_feedTagProvider.notifier).state = t,
                  ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          tab == 1
                              ? Icons.people_outline
                              : Icons.auto_stories,
                          size: 48,
                          color: Colors.grey[800],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _emptyMessage(tab, sort, selectedTag),
                          style: GoogleFonts.notoSerifJp(
                              color: Colors.grey[600], fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              if (popularTags.isNotEmpty)
                _TagFilterBar(
                  tags: popularTags.take(15).map((e) => e.key).toList(),
                  selectedTag: selectedTag,
                  onTagSelected: (t) =>
                      ref.read(_feedTagProvider.notifier).state = t,
                ),
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFFCC0000),
                  backgroundColor: const Color(0xFF1A1A1A),
                  onRefresh: () async => ref.invalidate(postsProvider),
                  child: _buildFeedList(posts),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFeedList(List<PostModel> posts) {
    // 5件ごとに広告を挿入
    final items = <dynamic>[];
    for (int i = 0; i < posts.length; i++) {
      items.add(posts[i]);
      if ((i + 1) % 5 == 0 && i + 1 < posts.length) {
        items.add('ad');
      }
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        if (item is String) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: AdBannerWidget(height: 100),
          );
        }
        return PostCard(post: item as PostModel);
      },
    );
  }

  String _sortLabel(FeedSort s) {
    switch (s) {
      case FeedSort.newest:
        return '新着';
      case FeedSort.popular:
        return '人気';
      case FeedSort.weekly:
        return '週間';
      case FeedSort.monthly:
        return '月間';
    }
  }

  IconData _sortIcon(FeedSort s) {
    switch (s) {
      case FeedSort.newest:
        return Icons.access_time;
      case FeedSort.popular:
        return Icons.local_fire_department;
      case FeedSort.weekly:
        return Icons.emoji_events_outlined;
      case FeedSort.monthly:
        return Icons.calendar_month_outlined;
    }
  }

  String _emptyMessage(int tab, FeedSort sort, String? tag) {
    if (tag != null) return '「$tag」の怪談はまだありません';
    if (tab == 1) return 'フォロー中のユーザーの怪談はありません';
    if (sort == FeedSort.weekly) return '今週の怪談はまだありません';
    if (sort == FeedSort.monthly) return '今月の怪談はまだありません';
    return 'まだ怪談がありません';
  }
}

class _TagFilterBar extends StatelessWidget {
  const _TagFilterBar({
    required this.tags,
    required this.selectedTag,
    required this.onTagSelected,
  });
  final List<String> tags;
  final String? selectedTag;
  final ValueChanged<String?> onTagSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1A1A1A))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            _TagChip(
              label: 'すべて',
              selected: selectedTag == null,
              onTap: () => onTagSelected(null),
            ),
            ...tags.map((t) => _TagChip(
                  label: t,
                  selected: selectedTag == t,
                  onTap: () => onTagSelected(selectedTag == t ? null : t),
                )),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF3A0000) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? const Color(0xFFCC0000)
                : const Color(0xFF2A2A2A),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.notoSerifJp(
            fontSize: 11,
            color: selected
                ? const Color(0xFFCC0000)
                : const Color(0xFF888888),
            fontWeight:
                selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1A0000) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: selected
                ? const Color(0xFFCC0000)
                : const Color(0xFF333333),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 11,
              color: selected
                  ? const Color(0xFFCC0000)
                  : const Color(0xFF666666),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.notoSerifJp(
                fontSize: 11,
                color: selected
                    ? const Color(0xFFCC0000)
                    : const Color(0xFF666666),
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color:
                  selected ? const Color(0xFFCC0000) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.notoSerifJp(
            fontSize: 13,
            color: selected
                ? const Color(0xFFEEEEEE)
                : const Color(0xFF666666),
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
