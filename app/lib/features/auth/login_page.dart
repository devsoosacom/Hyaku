import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() { _loading = true; _error = null; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (mounted) context.go('/feed');
    } on FirebaseAuthException catch (e) {
      setState(() { _error = e.message; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _register() async {
    setState(() { _loading = true; _error = null; });
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (mounted) context.go('/feed');
    } on FirebaseAuthException catch (e) {
      setState(() { _error = e.message; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('百物語',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFCC0000))),
              const SizedBox(height: 8),
              const Text('ホラー怪談SNS',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF888888))),
              const SizedBox(height: 48),
              TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'メールアドレス',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passCtrl,
                decoration: const InputDecoration(
                  labelText: 'パスワード',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!,
                    style: const TextStyle(color: Color(0xFFCC0000))),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _signIn,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCC0000)),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('ログイン'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _loading ? null : _register,
                child: const Text('新規登録'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
