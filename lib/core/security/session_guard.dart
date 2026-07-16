import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart'; // Importar para acceder al navigatorKey
import '../security/inactivity_manager.dart';
import '../../features/auth/presentation/viewmodels/auth_viewmodel.dart';

class SessionGuard extends StatefulWidget {
  final Widget child;
  const SessionGuard({super.key, required this.child});

  @override
  State<SessionGuard> createState() => _SessionGuardState();
}

class _SessionGuardState extends State<SessionGuard> {
  bool _dialogShown = false;
  AuthStatus? _lastStatus;

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final authStatus = authVM.status;

    // Si el usuario acaba de autenticarse, reseteamos la sesión de inactividad
    if (_lastStatus != AuthStatus.authenticated && authStatus == AuthStatus.authenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<InactivityManager>().resetSession();
      });
    }
    _lastStatus = authStatus;

    return Consumer<InactivityManager>(
      builder: (context, manager, child) {
        // Solo mostrar el diálogo si la sesión expiró Y el usuario está autenticado
        if (manager.sessionExpired && !_dialogShown && authStatus == AuthStatus.authenticated) {
          _dialogShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleSessionExpired(context);
          });
        }
        return child!;
      },
      child: widget.child,
    );
  }

  Future<void> _handleSessionExpired(BuildContext context) async {
    // Usamos el contexto de navegación global para asegurar que el diálogo se muestre correctamente
    final navContext = navigatorKey.currentContext;
    if (navContext == null) return;

    final theme = Theme.of(navContext);

    await showDialog(
      context: navContext,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock_clock, color: theme.colorScheme.error),
            const SizedBox(width: 8),
            const Text('Sesión expirada'),
          ],
        ),
        content: const Text(
          'Tu sesión ha sido cerrada por seguridad debido a inactividad. Por favor inicia sesión nuevamente.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(navContext);
              _logout(navContext);
            },
            child: const Text('Iniciar sesión'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final authVM = context.read<AuthViewModel>();
    final inactivityMgr = context.read<InactivityManager>();

    await authVM.logout();
    inactivityMgr.resetSession();
    _dialogShown = false;

    // Navegación forzada al inicio usando el navigatorKey global
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/',
      (route) => false,
    );
  }
}
