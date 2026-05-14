import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/register_page.dart';
import '../../features/feed/feed_page.dart';
import '../../features/search/search_page.dart';
import '../../features/post/post_page.dart';
import '../../features/post/post_detail_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/profile/edit_profile_page.dart';
import '../../features/notifications/notifications_page.dart';
import '../../features/profile/user_profile_page.dart';
import '../../features/profile/following_list_page.dart';

class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterRefreshNotifier();
  ref.listen(authProvider, (_, __) => notifier.refresh());
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/feed',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      if (authState.isLoading) return null;
      final isLoggedIn = authState.valueOrNull != null;
      final loc = state.matchedLocation;

      final isAuthRoute = loc == '/login' || loc == '/register';
      final isPublicRoute = loc.startsWith('/feed') ||
          loc.startsWith('/search') ||
          loc.startsWith('/post/') ||
          loc.startsWith('/user/');

      if (isLoggedIn && isAuthRoute) return '/feed';
      if (!isLoggedIn && !isAuthRoute && !isPublicRoute) return '/login';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
      // StatefulShellRoute: 各タブが独立した Navigator を持つ。
      // ShellRoute と異なり boundary crossing 時もナビゲーターが安定する。
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/feed', builder: (_, __) => const FeedPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/search', builder: (_, __) => const SearchPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/post', builder: (_, __) => const PostPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
          ]),
        ],
      ),
      GoRoute(
        path: '/post/:id',
        builder: (context, state) =>
            PostDetailPage(postId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationsPage()),
      GoRoute(path: '/profile/edit', builder: (_, __) => const EditProfilePage()),
      GoRoute(
        path: '/user/:id',
        builder: (context, state) =>
            UserProfilePage(userId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/following/:id',
        builder: (context, state) =>
            FollowingListPage(userId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/followers/:id',
        builder: (context, state) =>
            FollowingListPage(userId: state.pathParameters['id']!, showFollowers: true),
      ),
    ],
  );
});

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0A0A0A),
        selectedItemColor: const Color(0xFFCC0000),
        unselectedItemColor: const Color(0xFF555555),
        currentIndex: navigationShell.currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle:
            const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        onTap: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.auto_stories), label: '怪談'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: '検索'),
          BottomNavigationBarItem(icon: Icon(Icons.edit), label: '投稿'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'マイページ'),
        ],
      ),
    );
  }
}
