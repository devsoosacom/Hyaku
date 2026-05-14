import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';

const _availableTags = ['体験談', '心霊', '都市伝説', '怪談', '不思議'];

class PostPage extends ConsumerStatefulWidget {
  const PostPage({super.key});

  @override
  ConsumerState<PostPage> createState() => _PostPageState();
}

class _PostPageState extends ConsumerState<PostPage> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _selectedTags = <String>{};

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('タイトルと本文を入力してください')),
      );
      return;
    }
    if (title.length > 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('タイトルは60文字以内で入力してください')),
      );
      return;
    }
    final user = ref.read(currentUserProvider);
    if (user == null) {
      context.go('/login');
      return;
    }
    await ref.read(postActionsProvider.notifier).createPost(
          userId: user.id,
          authorName: user.displayName,
          title: title,
          content: body,
          tags: _selectedTags.toList(),
          authorPhotoUrl: user.photoUrl,
        );
    if (mounted) {
      _titleCtrl.clear();
      _bodyCtrl.clear();
      setState(() => _selectedTags.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('怪談を投稿しました')),
      );
      context.go('/feed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(postActionsProvider);
    final bodyLength = _bodyCtrl.text.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        title: Text(
          '怪談を語る',
          style: GoogleFonts.notoSerifJp(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFEEEEEE),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF1E1E1E)),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: isLoading ? null : _submit,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFCC0000),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text('投稿',
                      style: GoogleFonts.notoSerifJp(
                          fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleCtrl,
              onChanged: (_) => setState(() {}),
              maxLength: 60,
              style: GoogleFonts.notoSerifJp(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFEEEEEE),
                height: 1.4,
              ),
              decoration: InputDecoration(
                hintText: 'タイトル',
                hintStyle: GoogleFonts.notoSerifJp(
                  fontSize: 20,
                  color: const Color(0xFF444444),
                  fontWeight: FontWeight.w700,
                ),
                border: InputBorder.none,
                counterStyle: const TextStyle(
                    color: Color(0xFF555555), fontSize: 11),
              ),
              textInputAction: TextInputAction.next,
            ),
            Container(height: 1, color: const Color(0xFF2A2A2A)),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text(
                    'タグ：',
                    style: GoogleFonts.notoSerifJp(
                        fontSize: 11, color: const Color(0xFF555555)),
                  ),
                  const SizedBox(width: 8),
                  ..._availableTags.map((tag) {
                    final selected = _selectedTags.contains(tag);
                    return GestureDetector(
                      onTap: () => setState(() {
                        if (selected) {
                          _selectedTags.remove(tag);
                        } else {
                          _selectedTags.add(tag);
                        }
                      }),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFFCC0000)
                              : const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFFCC0000)
                                : const Color(0xFF333333),
                          ),
                        ),
                        child: Text(
                          tag,
                          style: GoogleFonts.notoSerifJp(
                            fontSize: 11,
                            color: selected
                                ? Colors.white
                                : const Color(0xFF777777),
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: const Color(0xFF1E1E1E)),
            const SizedBox(height: 8),
            TextField(
              controller: _bodyCtrl,
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.notoSerifJp(
                fontSize: 15,
                color: const Color(0xFFCCCCCC),
                height: 1.9,
              ),
              decoration: InputDecoration(
                hintText: 'ここに怪談を書いてください...\n\nある夜のことだった——',
                hintStyle: GoogleFonts.notoSerifJp(
                  fontSize: 15,
                  color: const Color(0xFF3A3A3A),
                  height: 1.9,
                ),
                border: InputBorder.none,
              ),
              maxLines: null,
              minLines: 15,
              textAlignVertical: TextAlignVertical.top,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '$bodyLength 文字',
                style: const TextStyle(color: Color(0xFF555555), fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
