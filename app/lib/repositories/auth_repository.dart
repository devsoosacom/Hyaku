import '../models/user_model.dart';

abstract class AuthRepository {
  Stream<UserModel?> get authStateChanges;
  UserModel? get currentUser;
  Future<UserModel> signIn(String email, String password);
  Future<UserModel> signUp(String email, String password, String displayName);
  Future<void> signOut();
  Future<void> updateProfile({String? displayName, String? bio});
  Future<String> updateProfilePhoto(List<int> bytes, String fileName);
}
