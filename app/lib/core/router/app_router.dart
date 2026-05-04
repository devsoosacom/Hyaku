import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/login_page.dart';
import '../../features/feed/feed_page.dart';
import '../../features/post/post_page.dart';
import '../../features/profile/profile_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/feed',
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/feed', builder: (_, __) => const FeedPage()),
          GoRoute(path: '/post', builder: (_, __) => const PostPage()),
          GoRoute(
              path: '/profile', builder: (_, __) => const ProfilePage()),
        ],
      ),
    ],
  );
});

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0A0A0A),
        selectedItemColor: const Color(0xFFCC0000),
        unselectedItemColor: const Color(0xFF888888),
        currentIndex: _currentIndex(context),
        onTap: (i) {
          switch (i) {
            case 0:
              context.go('/feed');
            case 1:
              context.go('/post');
            case 2:
              context.go('/profile');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '怪談'),
          BottomNavigationBarItem(icon: Icon(Icons.create), label: '投稿'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'プロフィール'),
        ],
      ),
    );
  }

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).uri.path;
    if (loc.startsWith('/post')) return 1;
    if (loc.startsWith('/profile')) return 2;
    return 0;
  }
}
