import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  late TextEditingController _nameCtrl;
  late TextEditingController _bioCtrl;
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameCtrl = TextEditingController(text: user?.displayName ?? '');
    _bioCtrl = TextEditingController(text: user?.bio ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).updateProfile(
            displayName: _nameCtrl.text.trim(),
            bio: _bioCtrl.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('プロフィールを更新しました')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: Color(0xFF888888), size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'プロフィール編集',
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
          TextButton(
            onPressed: _loading ? null : _save,
            child: Text(
              '保存',
              style: GoogleFonts.notoSerifJp(
                color: _loading
                    ? const Color(0xFF444444)
                    : const Color(0xFFCC0000),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 16),
            _Label('表示名'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameCtrl,
              maxLength: 20,
              style: GoogleFonts.notoSerifJp(
                  color: const Color(0xFFEEEEEE), fontSize: 14),
              decoration: _inputDecoration('怪談師の名前'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return '名前を入力してください';
                if (v.trim().length > 20) return '20文字以内で入力してください';
                return null;
              },
            ),
            const SizedBox(height: 20),
            _Label('自己紹介'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _bioCtrl,
              maxLength: 160,
              maxLines: 4,
              style: GoogleFonts.notoSerifJp(
                  color: const Color(0xFFEEEEEE), fontSize: 14),
              decoration: _inputDecoration('あなたの怪談について...'),
            ),
            const SizedBox(height: 40),
            if (_loading)
              const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFFCC0000), strokeWidth: 2),
              )
            else
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCC0000),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                  elevation: 0,
                ),
                child: Text(
                  '保存する',
                  style: GoogleFonts.notoSerifJp(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          const TextStyle(color: Color(0xFF555555), fontSize: 14),
      filled: true,
      fillColor: const Color(0xFF141414),
      counterStyle:
          const TextStyle(color: Color(0xFF555555), fontSize: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFFCC0000)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFFCC0000)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFFCC0000)),
      ),
      errorStyle: const TextStyle(color: Color(0xFFCC0000)),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.notoSerifJp(
        fontSize: 12,
        color: const Color(0xFF888888),
        letterSpacing: 1,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
