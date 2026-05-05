import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/post_provider.dart';
import '../feed/widgets/post_card.dart';

const _tags = ['体験談', '心霊', '都市伝説', '怪談', '不思議'];

class SearchPage extends ConsumerWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final selectedTag = ref.watch(selectedTagProvider);
    final resultsAsync = ref.watch(searchResultsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        titleSpacing: 16,
        title: _SearchField(
          initialValue: query,
          onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF1E1E1E)),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TagFilterRow(selected: selectedTag),
          const SizedBox(height: 4),
          Expanded(
            child: resultsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFFCC0000), strokeWidth: 2),
              ),
              error: (e, _) => Center(
                child: Text('エラーが発生しました',
                    style: GoogleFonts.notoSerifJp(
                        color: const Color(0xFF888888))),
              ),
              data: (posts) {
                if (query.isEmpty && selectedTag == null) {
                  return _EmptySearch();
                }
                if (posts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off,
                            color: Color(0xFF333333), size: 48),
                        const SizedBox(height: 12),
                        Text(
                          '怪談が見つかりませんでした',
                          style: GoogleFonts.notoSerifJp(
                              color: const Color(0xFF555555), fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: posts.length,
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  itemBuilder: (_, i) => PostCard(post: posts[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField({required this.initialValue, required this.onChanged});
  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      autofocus: false,
      style: GoogleFonts.notoSerifJp(
          color: const Color(0xFFEEEEEE), fontSize: 14),
      decoration: InputDecoration(
        hintText: '怪談を検索...',
        hintStyle: const TextStyle(color: Color(0xFF555555), fontSize: 14),
        prefixIcon: const Icon(Icons.search, color: Color(0xFF555555), size: 20),
        suffixIcon: _ctrl.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear,
                    color: Color(0xFF555555), size: 18),
                onPressed: () {
                  _ctrl.clear();
                  widget.onChanged('');
                },
              )
            : null,
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFCC0000)),
        ),
      ),
      onChanged: widget.onChanged,
    );
  }
}

class _TagFilterRow extends ConsumerWidget {
  const _TagFilterRow({required this.selected});
  final String? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          _TagChip(
            label: '全て',
            isSelected: selected == null,
            onTap: () => ref.read(selectedTagProvider.notifier).state = null,
          ),
          ..._tags.map((tag) => _TagChip(
                label: tag,
                isSelected: selected == tag,
                onTap: () {
                  ref.read(selectedTagProvider.notifier).state =
                      selected == tag ? null : tag;
                },
              )),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip(
      {required this.label,
      required this.isSelected,
      required this.onTap});
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFCC0000) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFCC0000)
                : const Color(0xFF2A2A2A),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.notoSerifJp(
            fontSize: 12,
            color: isSelected
                ? Colors.white
                : const Color(0xFF888888),
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.manage_search,
              color: Color(0xFF333333), size: 52),
          const SizedBox(height: 16),
          Text(
            'キーワードまたはタグで検索',
            style: GoogleFonts.notoSerifJp(
                color: const Color(0xFF555555), fontSize: 14),
          ),
        ],
      ),
    );
  }
}
