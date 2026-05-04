import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

class PostPage extends ConsumerStatefulWidget {
  const PostPage({super.key});
  @override
  ConsumerState<PostPage> createState() => _PostPageState();
}

class _PostPageState extends ConsumerState<PostPage> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.isEmpty || _bodyCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { context.go('/login'); return; }
    try {
      final id = const Uuid().v4();
      await FirebaseFirestore.instance.collection('posts').doc(id).set({
        'id': id,
        'authorId': user.uid,
        'authorName': user.displayName ?? '名無し',
        'title': _titleCtrl.text.trim(),
        'body': _bodyCtrl.text.trim(),
        'likeCount': 0,
        'commentCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('怪談を投稿しました')));
        context.go('/feed');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('怪談を投稿'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _submit,
            child: const Text('投稿', style: TextStyle(color: Color(0xFFCC0000))),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              hintText: 'タイトル',
              border: InputBorder.none,
            ),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          Expanded(
            child: TextField(
              controller: _bodyCtrl,
              decoration: const InputDecoration(
                hintText: 'ここに怪談を書いてください...',
                border: InputBorder.none,
              ),
              maxLines: null,
              expands: true,
              style: const TextStyle(height: 1.8),
            ),
          ),
        ]),
      ),
    );
  }
}
