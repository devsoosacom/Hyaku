import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/mock/mock_auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository();
});

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  AuthNotifier(this._repo) : super(const AsyncValue.loading()) {
    _repo.authStateChanges.listen(
      (user) => state = AsyncValue.data(user),
      onError: (e) => state = AsyncValue.error(e, StackTrace.current),
    );
  }

  final AuthRepository _repo;

  UserModel? get currentUser => _repo.currentUser;

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repo.signIn(email, password),
    );
  }

  Future<void> signUp(
      String email, String password, String displayName) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repo.signUp(email, password, displayName),
    );
  }

  Future<void> signOut() async {
    await _repo.signOut();
  }

  Future<void> updateProfile({String? displayName, String? bio}) async {
    await _repo.updateProfile(displayName: displayName, bio: bio);
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).valueOrNull;
});
