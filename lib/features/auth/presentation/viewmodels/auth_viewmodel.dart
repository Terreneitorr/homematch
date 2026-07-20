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

  // Rol que el usuario ELIGIÓ en el login (Vendedor/Inmobiliaria), pero que
  // todavía no tiene realmente porque no ha pagado. Se usa en main.dart para
  // decidir si hay que mandarlo a la pantalla de pago antes de dejarlo
  // entrar a la app. Se limpia una vez que ya no aplica (pagó, o decidió
  // seguir como comprador gratis).
  String? _pendingUpgradeRole;

  AuthStatus get status => _status;
  UserEntity? get user => _user;
  String? get errorMessage => _errorMessage;
  String? get pendingUpgradeRole => _pendingUpgradeRole;

  void setPendingUpgradeRole(String? role) {
    _pendingUpgradeRole = role;
    notifyListeners();
  }

  void clearPendingUpgradeRole() {
    _pendingUpgradeRole = null;
    notifyListeners();
  }

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

    // Si eligió un rol de pago, lo recordamos ANTES de llamar al backend —
    // el backend siempre va a crear/mantener al usuario como USER hasta que
    // pague de verdad, así que esta es la única forma de saber qué quería.
    _pendingUpgradeRole = (role == 'SELLER' || role == 'AGENCY') ? role : null;

    try {
      _user = await _dataSource.loginWithGoogle(role: role);
      _status = AuthStatus.authenticated;

      // Si ya tiene ese rol de verdad (ya había pagado antes), no hace
      // falta mandarlo a pagar de nuevo.
      if (_user!.role == _pendingUpgradeRole) {
        _pendingUpgradeRole = null;
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('cancelado')) {
        _status = AuthStatus.unauthenticated;
        _errorMessage = null;
      } else {
        _status = AuthStatus.error;
        _errorMessage = msg.replaceAll('Exception: ', '');
      }
      _pendingUpgradeRole = null;
    }
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    _pendingUpgradeRole = null;
    notifyListeners();
    try {
      await _dataSource.logout();
    } catch (_) {}
  }

  Future<void> refreshUser() async {
    try {
      final user = await _dataSource.getCurrentUser();
      if (user != null) {
        _user = user;
        // Si tras refrescar ya tiene el rol que estaba pendiente (se
        // confirmó el pago), dejamos de bloquear el acceso.
        if (_pendingUpgradeRole != null && user.role == _pendingUpgradeRole) {
          _pendingUpgradeRole = null;
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> updateUser(String name) async {
    await refreshUser();
  }
}