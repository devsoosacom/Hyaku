import 'dart:async';
import '../follow_repository.dart';

class MockFollowRepository implements FollowRepository {
  // followerId → Set of targetIds
  final _following = <String, Set<String>>{
    'seed-user': {'seed-user2', 'seed-user3'},
    'seed-user2': {'seed-user', 'seed-user4'},
    'seed-user3': {'seed-user'},
    'seed-user4': {'seed-user2', 'seed-user5'},
    'seed-user5': {'seed-user', 'seed-user3'},
  };

  final _followingCtrl = <String, StreamController<Set<String>>>{};
  final _followersCtrl = <String, StreamController<Set<String>>>{};

  Set<String> _getFollowingSet(String userId) =>
      _following[userId] ?? {};

  Set<String> _getFollowersSet(String userId) {
    return _following.entries
        .where((e) => e.value.contains(userId))
        .map((e) => e.key)
        .toSet();
  }

  void _notifyAll(String userId) {
    _followingCtrl[userId]?.add(_getFollowingSet(userId));
    _followersCtrl[userId]?.add(_getFollowersSet(userId));
    // notify followers/following of the target too
    for (final id in _getFollowingSet(userId)) {
      _followersCtrl[id]?.add(_getFollowersSet(id));
    }
  }

  @override
  Stream<Set<String>> getFollowing(String userId) {
    _followingCtrl.putIfAbsent(
      userId,
      () => StreamController<Set<String>>.broadcast(),
    );
    Future.microtask(
        () => _followingCtrl[userId]!.add(_getFollowingSet(userId)));
    return _followingCtrl[userId]!.stream;
  }

  @override
  Stream<Set<String>> getFollowers(String userId) {
    _followersCtrl.putIfAbsent(
      userId,
      () => StreamController<Set<String>>.broadcast(),
    );
    Future.microtask(
        () => _followersCtrl[userId]!.add(_getFollowersSet(userId)));
    return _followersCtrl[userId]!.stream;
  }

  @override
  Future<void> follow(String followerId, String targetId) async {
    _following.putIfAbsent(followerId, () => {});
    _following[followerId]!.add(targetId);
    _notifyAll(followerId);
    _followersCtrl[targetId]?.add(_getFollowersSet(targetId));
  }

  @override
  Future<void> unfollow(String followerId, String targetId) async {
    _following[followerId]?.remove(targetId);
    _notifyAll(followerId);
    _followersCtrl[targetId]?.add(_getFollowersSet(targetId));
  }
}
