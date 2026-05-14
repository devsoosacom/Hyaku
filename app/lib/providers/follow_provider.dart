import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/follow_repository.dart';
import '../repositories/firebase/firestore_follow_repository.dart';

final followRepositoryProvider = Provider<FollowRepository>(
  (ref) => FirestoreFollowRepository(),
);

final followingProvider = StreamProvider.family<Set<String>, String>((ref, userId) {
  return ref.watch(followRepositoryProvider).getFollowing(userId);
});

final followersProvider = StreamProvider.family<Set<String>, String>((ref, userId) {
  return ref.watch(followRepositoryProvider).getFollowers(userId);
});

// key = "followerId::targetId"
final isFollowingProvider = Provider.family<bool, String>((ref, key) {
  final parts = key.split('::');
  if (parts.length != 2) return false;
  return ref.watch(followingProvider(parts[0])).maybeWhen(
        data: (set) => set.contains(parts[1]),
        orElse: () => false,
      );
});

class FollowNotifier extends StateNotifier<bool> {
  FollowNotifier(this._repo) : super(false);
  final FollowRepository _repo;

  Future<void> toggle(String followerId, String targetId, bool isFollowing) async {
    state = true;
    try {
      if (isFollowing) {
        await _repo.unfollow(followerId, targetId);
      } else {
        await _repo.follow(followerId, targetId);
      }
    } finally {
      state = false;
    }
  }
}

final followNotifierProvider =
    StateNotifierProvider<FollowNotifier, bool>((ref) {
  return FollowNotifier(ref.watch(followRepositoryProvider));
});
