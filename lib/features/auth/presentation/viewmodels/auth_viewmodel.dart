import 'package:flutter/material.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/login_with_google_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../data/datasources/auth_remote_datasource.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthViewModel extends ChangeNotifier {
  final LoginWithGoogleUseCase loginWithGoogleUseCase;
  final LogoutUseCase logoutUseCase;
  final AuthRemoteDataSourceImpl _dataSource = AuthRemoteDataSourceImpl();

  AuthViewModel({
    required this.loginWithGoogleUseCase,
    required this.logoutUseCase,
  }) {
    _checkSession();
  }

  AuthStatus _status = AuthStatus.initial;
  UserEntity? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserEntity? get user => _user;
  String? get errorMessage => _errorMessage;

  Future<void> _checkSession() async {
    try {
      final token = await _dataSource.getStoredToken();
      if (token == null || token.isEmpty) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }
      final user = await _dataSource.getCurrentUser()
          .timeout(const Duration(seconds: 6));
      if (user != null && user.id.isNotEmpty) {
        _user = user;
        _status = AuthStatus.authenticated;
      } else {
        await _dataSource.clearToken();
        _status = AuthStatus.unauthenticated;
      }
    } catch (_) {
      await _dataSource.clearToken();
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> loginWithGoogle(String role) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _dataSource.loginWithGoogle(role: role);
      _status = AuthStatus.authenticated;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('cancelado')) {
        _status = AuthStatus.unauthenticated;
        _errorMessage = null;
      } else {
        _status = AuthStatus.error;
        _errorMessage = msg.replaceAll('Exception: ', '');
      }
    }
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();

    // Limpiar en background
    try {
      await _dataSource.logout();
    } catch (_) {}
  }

  Future<void> refreshUser() async {
    try {
      final user = await _dataSource.getCurrentUser();
      if (user != null) {
        _user = user;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> updateUser(String name) async {
    await refreshUser();
  }
}