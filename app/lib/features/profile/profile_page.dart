import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('プロフィール')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const CircleAvatar(
            radius: 48,
            backgroundColor: Color(0xFF333333),
            child: Icon(Icons.person, size: 48, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Text(user?.displayName ?? '名無し',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(user?.email ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 48),
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFFCC0000)),
            title: const Text('ログアウト'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}
