import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/firebase/firebase_auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
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
    try {
      final user = await _repo.signIn(email, password);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signUp(
      String email, String password, String displayName) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.signUp(email, password, displayName);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
  }

  Future<void> updateProfile({String? displayName, String? bio}) async {
    await _repo.updateProfile(displayName: displayName, bio: bio);
  }

  Future<String> updateProfilePhoto(List<int> bytes, String fileName) async {
    final url = await _repo.updateProfilePhoto(bytes, fileName);
    // Refresh state so UI picks up new photoUrl
    if (state.valueOrNull != null) {
      state = AsyncValue.data(
        state.valueOrNull!.copyWith(photoUrl: url),
      );
    }
    return url;
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
