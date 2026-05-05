import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../models/user_model.dart';
import '../auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  static const _uuid = Uuid();

  final _controller = StreamController<UserModel?>.broadcast();
  final _users = <String, _StoredUser>{};
  UserModel? _currentUser;

  MockAuthRepository() {
    _initFromPrefs();
  }

  Future<void> _initFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId != null) {
      final email = prefs.getString('userEmail') ?? '';
      final name = prefs.getString('userName') ?? '';
      final bio = prefs.getString('userBio');
      final postCount = prefs.getInt('userPostCount') ?? 0;
      final createdAt = DateTime.fromMillisecondsSinceEpoch(
        prefs.getInt('userCreatedAt') ?? DateTime.now().millisecondsSinceEpoch,
      );
      _currentUser = UserModel(
        id: userId,
        displayName: name,
        email: email,
        bio: bio,
        postCount: postCount,
        createdAt: createdAt,
      );
      _users[email] = _StoredUser(
        id: userId,
        email: email,
        password: prefs.getString('userPassword') ?? '',
        displayName: name,
        bio: bio,
        postCount: postCount,
        createdAt: createdAt,
      );
      _controller.add(_currentUser);
    } else {
      _controller.add(null);
    }
  }

  Future<void> _saveToPrefs(UserModel user, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', user.id);
    await prefs.setString('userEmail', user.email);
    await prefs.setString('userName', user.displayName);
    await prefs.setString('userPassword', password);
    if (user.bio != null) await prefs.setString('userBio', user.bio!);
    await prefs.setInt('userPostCount', user.postCount);
    await prefs.setInt('userCreatedAt', user.createdAt.millisecondsSinceEpoch);
  }

  Future<void> _clearPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  @override
  Stream<UserModel?> get authStateChanges => _controller.stream;

  @override
  UserModel? get currentUser => _currentUser;

  @override
  Future<UserModel> signIn(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final stored = _users[email.toLowerCase()];
    if (stored == null || stored.password != password) {
      throw Exception('メールアドレスまたはパスワードが正しくありません');
    }
    final user = UserModel(
      id: stored.id,
      displayName: stored.displayName,
      email: stored.email,
      bio: stored.bio,
      postCount: stored.postCount,
      createdAt: stored.createdAt,
    );
    _currentUser = user;
    await _saveToPrefs(user, password);
    _controller.add(user);
    return user;
  }

  @override
  Future<UserModel> signUp(
      String email, String password, String displayName) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final lowerEmail = email.toLowerCase();
    if (_users.containsKey(lowerEmail)) {
      throw Exception('このメールアドレスはすでに使用されています');
    }
    if (password.length < 6) {
      throw Exception('パスワードは6文字以上で設定してください');
    }
    final id = _uuid.v4();
    final now = DateTime.now();
    final stored = _StoredUser(
      id: id,
      email: lowerEmail,
      password: password,
      displayName: displayName,
      createdAt: now,
    );
    _users[lowerEmail] = stored;
    final user = UserModel(
      id: id,
      displayName: displayName,
      email: lowerEmail,
      createdAt: now,
    );
    _currentUser = user;
    await _saveToPrefs(user, password);
    _controller.add(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    await _clearPrefs();
    _controller.add(null);
  }

  @override
  Future<void> updateProfile({String? displayName, String? bio}) async {
    if (_currentUser == null) return;
    final updated = _currentUser!.copyWith(
      displayName: displayName,
      bio: bio,
    );
    final stored = _users[_currentUser!.email];
    if (stored != null) {
      _users[_currentUser!.email] = stored.copyWith(
        displayName: displayName,
        bio: bio,
      );
    }
    _currentUser = updated;
    final prefs = await SharedPreferences.getInstance();
    if (displayName != null) await prefs.setString('userName', displayName);
    if (bio != null) await prefs.setString('userBio', bio);
    _controller.add(updated);
  }

  void incrementPostCount(String userId) {
    if (_currentUser?.id == userId) {
      final updated = _currentUser!.copyWith(
        postCount: _currentUser!.postCount + 1,
      );
      _currentUser = updated;
      _controller.add(updated);
    }
  }
}

class _StoredUser {
  final String id;
  final String email;
  final String password;
  final String displayName;
  final String? bio;
  final int postCount;
  final DateTime createdAt;

  _StoredUser({
    required this.id,
    required this.email,
    required this.password,
    required this.displayName,
    this.bio,
    this.postCount = 0,
    required this.createdAt,
  });

  _StoredUser copyWith({String? displayName, String? bio}) {
    return _StoredUser(
      id: id,
      email: email,
      password: password,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      postCount: postCount,
      createdAt: createdAt,
    );
  }
}
