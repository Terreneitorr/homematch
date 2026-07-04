import 'package:flutter/material.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/login_with_google_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../data/datasources/auth_remote_datasource.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthViewModel extends ChangeNotifier {
  final LoginWithGoogleUseCase loginWithGoogleUseCase;
  final LogoutUseCase logoutUseCase;
  final AuthRemoteDataSource _dataSource = AuthRemoteDataSourceImpl();

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
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      final user = await _dataSource.getCurrentUser();
      if (user != null) {
        _user = user;
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> loginWithGoogle() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _user = await loginWithGoogleUseCase();
      _status = AuthStatus.authenticated;
    } catch (e) {
      _errorMessage = 'Error al iniciar sesión. Intenta de nuevo.';
      _status = AuthStatus.error;
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await logoutUseCase();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> updateUser(String name) async {
    try {
      final response = await _dataSource.getCurrentUser();
      if (response != null) {
        _user = response;
        notifyListeners();
      }
    } catch (_) {}
  }
}