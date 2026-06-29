import 'package:flutter/material.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/login_with_google_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthViewModel extends ChangeNotifier {
  final LoginWithGoogleUseCase loginWithGoogleUseCase;
  final LogoutUseCase logoutUseCase;

  AuthViewModel({
    required this.loginWithGoogleUseCase,
    required this.logoutUseCase,
  });

  AuthStatus _status = AuthStatus.initial;
  UserEntity? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserEntity? get user => _user;
  String? get errorMessage => _errorMessage;

  Future<void> loginWithGoogle() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      _user = await loginWithGoogleUseCase();
      _status = AuthStatus.authenticated;
    } catch (e) {
      _errorMessage = e.toString();
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
}