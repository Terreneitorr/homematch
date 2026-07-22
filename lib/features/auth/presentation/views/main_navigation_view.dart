import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:homematch_ai/features/analytics/presentation/views/analytics_view.dart' hide AnalyticsView;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:homematch_ai/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:homematch_ai/features/properties/presentation/views/properties_view.dart';
import 'package:homematch_ai/features/favorites/presentation/views/favorites_view.dart';
import 'package:homematch_ai/features/search/presentation/views/search_view.dart';
import 'package:homematch_ai/features/properties/presentation/viewmodels/property_viewmodel.dart';
import 'package:homematch_ai/features/favorites/presentation/viewmodels/favorites_viewmodel.dart';
import 'package:homematch_ai/features/appointments/presentation/views/appointments_view.dart';
import 'package:homematch_ai/features/analytics/presentation/views/analytics_view.dart';
import 'package:homematch_ai/features/profile/presentation/views/edit_profile_view.dart';
import 'package:homematch_ai/features/history/presentation/views/history_view.dart';
import 'package:homematch_ai/features/properties/presentation/views/create_property_view.dart';
import 'package:homematch_ai/features/profile/presentation/views/agency_profile_view.dart';
import 'package:homematch_ai/features/schedules/presentation/views/schedule_config_view.dart';
import 'package:homematch_ai/features/info/presentation/views/help_center_view.dart';
import 'package:homematch_ai/features/info/presentation/views/terms_view.dart';
import 'package:homematch_ai/features/info/presentation/views/privacy_view.dart';
import 'package:homematch_ai/features/notifications/presentation/views/notifications_view.dart';
import 'package:homematch_ai/features/chat/presentation/views/conversations_view.dart';
import 'package:homematch_ai/features/payments/presentation/views/payment_view.dart';
import 'package:homematch_ai/core/network/dio_client.dart';
import 'package:homematch_ai/core/network/upload_service.dart' as upload;
import 'package:homematch_ai/core/security/fcm_security_service.dart';
import 'package:homematch_ai/features/profile/presentation/views/verification_document_view.dart';
import 'package:homematch_ai/core/security/inactivity_manager.dart';

class MainNavigationView extends StatefulWidget {
  const MainNavigationView({super.key});

  @override
  State<MainNavigationView> createState() => MainNavigationViewState();
}

class MainNavigationViewState extends State<MainNavigationView> {
  int _currentIndex = 0;

  void goToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  void initState() {
    super.initState();

    // Cualquiera que haya sido el estado del timer de inactividad antes
    // (venir de un logout manual, del pago, o de una sesión anterior que
    // expiró), al entrar de verdad a la app se reinicia limpio. Sin esto,
    // un timer que se cumple de fondo durante el login puede dejar
    // "sessionExpired" en true y el diálogo aparece apenas entras.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<InactivityManager>().resetSession();
      }
    });

    // Inicializar FCM con el context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FcmSecurityService.initialize(context);
    });

    Future.microtask(() async {
      if (!mounted) return;

      final authVM = context.read<AuthViewModel>();

      // Si el usuario está vacío, hacer logout y regresar al login
      if (authVM.user == null || authVM.user!.id.isEmpty) {
        await authVM.logout();
        return;
      }

      // ELIMINADO: propVM.loadProperties() y favVM.loadFavorites()
      // Razón: PropertiesView ya se encarga de cargar sus propios datos al iniciar,
      // llamar esto aquí duplica la carga y ralentiza el inicio.
    });
  }

  List<Widget> _getPages(String role) {
    switch (role) {
      case 'SELLER':
        return const [PropertiesView(), SearchView(), _SellerDashboard(), _ProfileView()];
      case 'AGENCY':
        return const [PropertiesView(), SearchView(), _AgencyDashboard(), AgencyProfileView()];
      case 'ADMIN':
        return const [PropertiesView(), _AdminPanel(), _ProfileView()];
      default:
        return const [PropertiesView(), SearchView(), FavoritesView(), _ProfileView()];
    }
  }

  List<NavigationDestination> _getDestinations(String role) {
    switch (role) {
      case 'SELLER':
        return const [
          NavigationDestination(icon: Icon(Icons.home_work_outlined), selectedIcon: Icon(Icons.home_work), label: 'Propiedades'),
          NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search), label: 'Buscar'),
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ];
      case 'AGENCY':
        return const [
          NavigationDestination(icon: Icon(Icons.home_work_outlined), selectedIcon: Icon(Icons.home_work), label: 'Propiedades'),
          NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search), label: 'Buscar'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ];
      case 'ADMIN':
        return const [
          NavigationDestination(icon: Icon(Icons.home_work_outlined), selectedIcon: Icon(Icons.home_work), label: 'Propiedades'),
          NavigationDestination(icon: Icon(Icons.admin_panel_settings_outlined), selectedIcon: Icon(Icons.admin_panel_settings), label: 'Admin'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ];
      default:
        return const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search), label: 'Buscar'),
          NavigationDestination(icon: Icon(Icons.favorite_outline), selectedIcon: Icon(Icons.favorite), label: 'Favoritos'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = context.watch<AuthViewModel>().user?.role ?? 'USER';
    final pages = _getPages(role);
    final destinations = _getDestinations(role);
    final safeIndex = _currentIndex >= pages.length ? 0 : _currentIndex;

    return Scaffold(
      body: pages[safeIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
          ),
        ),
        child: NavigationBar(
          selectedIndex: safeIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          backgroundColor: theme.colorScheme.surfaceContainerLowest,
          indicatorColor: theme.colorScheme.primaryContainer,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          elevation: 0,
          destinations: destinations,
        ),
      ),
    );
  }
}

// ─── SELLER DASHBOARD ────────────────────────────────────────────
class _SellerDashboard extends StatefulWidget {
  const _SellerDashboard();

  @override
  State<_SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<_SellerDashboard> {
  Map<String, dynamic> _stats = {
    'properties': 0,
    'active': 0,
    'appointments': 0,
    'messages': 0,
  };
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final propRes = await DioClient().dio.get('/properties/');
      final aptRes = await DioClient().dio.get('/appointments/');
      final convRes = await DioClient().dio.get('/chat/conversations');
      final userId = context.read<AuthViewModel>().user?.id ?? '';
      final props = (propRes.data as List)
          .where((p) => p['owner_id'] == userId)
          .toList();
      final active = props.where((p) => p['status'] == 'available').length;
      setState(() {
        _stats = {
          'properties': props.length,
          'active': active,
          'appointments': (aptRes.data as List).length,
          'messages': (convRes.data as List).length,
        };
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Mi Dashboard', style: theme.textTheme.titleLarge),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.colorScheme.primary),
            onPressed: () { setState(() => _loading = true); _load(); },
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Resumen', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _StatCard(
                    theme: theme,
                    icon: Icons.home_work,
                    value: '${_stats['properties']}',
                    label: 'Mis propiedades',
                    color: theme.colorScheme.primary,
                  ),
                  _StatCard(
                    theme: theme,
                    icon: Icons.check_circle,
                    value: '${_stats['active']}',
                    label: 'Activas',
                    color: theme.colorScheme.secondary,
                  ),
                  _StatCard(
                    theme: theme,
                    icon: Icons.calendar_today,
                    value: '${_stats['appointments']}',
                    label: 'Citas',
                    color: theme.colorScheme.tertiary,
                  ),
                  _StatCard(
                    theme: theme,
                    icon: Icons.message,
                    value: '${_stats['messages']}',
                    label: 'Mensajes',
                    color: theme.colorScheme.error,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Acciones rápidas', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              _ActionTile(
                theme: theme,
                icon: Icons.add_home,
                title: 'Publicar propiedad',
                subtitle: 'Agrega una nueva publicación',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CreatePropertyView())),
              ),
              _ActionTile(
                theme: theme,
                icon: Icons.calendar_month,
                title: 'Ver mis citas',
                subtitle: 'Administra tus visitas agendadas',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AppointmentsView())),
              ),
              _ActionTile(
                theme: theme,
                icon: Icons.chat_bubble_outline,
                title: 'Mis mensajes',
                subtitle: 'Chatea con interesados',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ConversationsView())),
              ),
              _ActionTile(
                theme: theme,
                icon: Icons.schedule_outlined,
                title: 'Configurar horario',
                subtitle: 'Define disponibilidad para visitas',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ScheduleConfigView())),
              ),
              _ActionTile(
                theme: theme,
                icon: Icons.analytics_outlined,
                title: 'Estadísticas del mercado',
                subtitle: 'Métricas y tendencias',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AnalyticsView())),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── AGENCY DASHBOARD ────────────────────────────────────────────
class _AgencyDashboard extends StatefulWidget {
  const _AgencyDashboard();

  @override
  State<_AgencyDashboard> createState() => _AgencyDashboardState();
}

class _AgencyDashboardState extends State<_AgencyDashboard> {
  Map<String, dynamic> _stats = {
    'properties': 0,
    'active': 0,
    'appointments': 0,
    'messages': 0,
    'total_views': 0,
  };
  List<dynamic> _recentProperties = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final propRes = await DioClient().dio.get('/properties/');
      final aptRes = await DioClient().dio.get('/appointments/');
      final convRes = await DioClient().dio.get('/chat/conversations');
      final analyticsRes = await DioClient().dio.get('/analytics/');
      final userId = context.read<AuthViewModel>().user?.id ?? '';

      final props = (propRes.data as List)
          .where((p) => p['owner_id'] == userId)
          .toList();
      final active = props.where((p) => p['status'] == 'available').length;

      setState(() {
        _stats = {
          'properties': props.length,
          'active': active,
          'appointments': (aptRes.data as List).length,
          'messages': (convRes.data as List).length,
          'total_views': analyticsRes.data['total_properties'] ?? 0,
        };
        _recentProperties = props.take(3).toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard Inmobiliaria', style: theme.textTheme.titleLarge),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.colorScheme.primary),
            onPressed: () { setState(() => _loading = true); _load(); },
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats grid
              Text('Estadísticas', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _StatCard(
                    theme: theme,
                    icon: Icons.home_work,
                    value: '${_stats['properties']}',
                    label: 'Propiedades',
                    color: theme.colorScheme.primary,
                  ),
                  _StatCard(
                    theme: theme,
                    icon: Icons.chat_bubble_outline,
                    value: '${_stats['messages']}',
                    label: 'Mensajes',
                    color: theme.colorScheme.secondary,
                  ),
                  _StatCard(
                    theme: theme,
                    icon: Icons.calendar_today,
                    value: '${_stats['appointments']}',
                    label: 'Citas',
                    color: theme.colorScheme.tertiary,
                  ),
                  _StatCard(
                    theme: theme,
                    icon: Icons.bar_chart,
                    value: '${_stats['total_views']}',
                    label: 'En plataforma',
                    color: theme.colorScheme.error,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Mis propiedades recientes
              if (_recentProperties.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Mis propiedades recientes',
                        style: theme.textTheme.titleMedium),
                    TextButton(
                      onPressed: () {},
                      child: Text('Ver todas',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          )),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._recentProperties.map((prop) => _PropertyListItem(
                  theme: theme,
                  prop: prop,
                )),
                const SizedBox(height: 16),
              ],

              // Acciones rápidas
              Text('Acciones rápidas', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              _ActionTile(
                theme: theme,
                icon: Icons.add_home,
                title: 'Publicar propiedad',
                subtitle: 'Agrega una nueva publicación',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CreatePropertyView())),
              ),
              _ActionTile(
                theme: theme,
                icon: Icons.calendar_month,
                title: 'Ver citas',
                subtitle: 'Gestiona visitas agendadas',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AppointmentsView())),
              ),
              _ActionTile(
                theme: theme,
                icon: Icons.chat_bubble_outline,
                title: 'Mis mensajes',
                subtitle: 'Chatea con interesados',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ConversationsView())),
              ),
              _ActionTile(
                theme: theme,
                icon: Icons.schedule_outlined,
                title: 'Configurar horario',
                subtitle: 'Define disponibilidad para visitas',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ScheduleConfigView())),
              ),
              _ActionTile(
                theme: theme,
                icon: Icons.analytics_outlined,
                title: 'Estadísticas del mercado',
                subtitle: 'Métricas y tendencias de la plataforma',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AnalyticsView())),
              ),
              _ActionTile(
                theme: theme,
                icon: Icons.verified_outlined,
                title: 'Estado de verificación',
                subtitle: 'Verifica el estado de tu cuenta',
                onTap: () => _showVerificationDialog(context, theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVerificationDialog(BuildContext context, ThemeData theme) {
    final status = context.read<AuthViewModel>().user?.verificationStatus;

    IconData icon;
    Color color;
    String title;
    String message;
    bool showUploadButton = false;

    switch (status) {
      case 'approved':
        icon = Icons.verified;
        color = theme.colorScheme.secondary;
        title = 'Cuenta verificada';
        message = 'Tu inmobiliaria ya está verificada por HomeMatch AI.';
        break;
      case 'pending':
        icon = Icons.hourglass_top;
        color = theme.colorScheme.tertiary;
        title = 'En revisión';
        message = 'Tu documento está siendo revisado por el equipo de HomeMatch AI.';
        break;
      case 'rejected':
        icon = Icons.error_outline;
        color = theme.colorScheme.error;
        title = 'Documento rechazado';
        message = 'Tu documento fue rechazado. Sube uno nuevo para volver a intentarlo.';
        showUploadButton = true;
        break;
      default:
        icon = Icons.upload_file;
        color = theme.colorScheme.outline;
        title = 'Sin verificar';
        message = 'Aún no has subido tu documento de verificación (RFC/cédula). '
            'Sin verificación, tu cuenta sigue activa pero sin el sello de confianza.';
        showUploadButton = true;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(color: color),
              ),
            ),
          ],
        ),
        actions: [
          if (showUploadButton)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const VerificationDocumentView()));
              },
              child: const Text('Subir documento'),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}

class _PropertyListItem extends StatelessWidget {
  final ThemeData theme;
  final Map<String, dynamic> prop;

  const _PropertyListItem({required this.theme, required this.prop});

  @override
  Widget build(BuildContext context) {
    final status = prop['status'] ?? 'available';
    Color statusColor;
    String statusLabel;

    switch (status) {
      case 'reserved':
        statusColor = theme.colorScheme.tertiary;
        statusLabel = 'Reservada';
        break;
      case 'sold':
      case 'rented':
        statusColor = theme.colorScheme.outline;
        statusLabel = status == 'sold' ? 'Vendida' : 'Rentada';
        break;
      default:
        statusColor = theme.colorScheme.secondary;
        statusLabel = 'Disponible';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.home_work_outlined,
                size: 24, color: theme.colorScheme.outline),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prop['title'] ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '\$${prop['price']}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withOpacity(0.4)),
            ),
            child: Text(
              statusLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ADMIN PANEL ──────────────────────────────────────────────────
class _AdminPanel extends StatefulWidget {
  const _AdminPanel();

  @override
  State<_AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<_AdminPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _users = [];
  Map<String, dynamic> _stats = {};
  List<dynamic> _pendingVerifications = [];
  Map<String, dynamic> _dashboardStats = {};
  bool _loading = true;
  String _searchQuery = '';
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _load();
    // Auto-refresh de las estadísticas cada 60 segundos, sin que el admin
    // tenga que jalar hacia abajo o darle a refrescar manualmente.
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final usersRes = await DioClient().dio.get('/users/');
      final statsRes = await DioClient().dio.get('/users/stats');
      List<dynamic> pending = [];
      try {
        final pendingRes =
        await DioClient().dio.get('/users/admin/verifications/pending');
        pending = pendingRes.data;
      } catch (_) {}
      Map<String, dynamic> dashboard = {};
      try {
        final dashRes = await DioClient().dio.get('/users/admin/dashboard-stats');
        dashboard = dashRes.data;
      } catch (_) {}
      setState(() {
        _users = usersRes.data;
        _stats = statsRes.data;
        _pendingVerifications = pending;
        _dashboardStats = dashboard;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  List<dynamic> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    return _users.where((u) =>
    (u['name'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (u['email'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  List<dynamic> get _activeUsers =>
      _filteredUsers.where((u) => u['is_active'] == true).toList();

  List<dynamic> get _inactiveUsers =>
      _filteredUsers.where((u) => u['is_active'] == false).toList();

  Future<void> _activate(String userId, String name) async {
    try {
      await DioClient().dio.put('/users/$userId/activate');
      _load();
      if (mounted) _showSnack('✓ $name activado', true);
    } catch (_) {}
  }

  Future<void> _deactivate(String userId, String name) async {
    final theme = Theme.of(context);
    final reason = await _showReasonDialog('Desactivar cuenta', name);
    if (reason == null) return;
    try {
      await DioClient().dio.put(
        '/users/$userId/deactivate',
        data: {'reason': reason},
      );
      _load();
      if (mounted) _showSnack('✓ $name desactivado', true);
    } catch (_) {}
  }

  Future<void> _deleteUser(String userId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: theme.colorScheme.error),
              const SizedBox(width: 8),
              const Text('Eliminar permanente'),
            ],
          ),
          content: Text(
            '¿Estás seguro de eliminar a "$name" permanentemente?\n\nEsta acción NO se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      try {
        await DioClient().dio.delete('/users/$userId');
        _load();
        if (mounted) _showSnack('✓ $name eliminado', true);
      } catch (_) {}
    }
  }

  Future<void> _changeRole(String userId, String name) async {
    final roles = ['USER', 'SELLER', 'AGENCY', 'ADMIN'];
    final theme = Theme.of(context);
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cambiar rol de $name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: roles.map((r) => ListTile(
            leading: Icon(_roleIcon(r), color: theme.colorScheme.primary),
            title: Text(_roleLabel(r)),
            onTap: () => Navigator.pop(ctx, r),
          )).toList(),
        ),
      ),
    );
    if (selected != null) {
      try {
        await DioClient().dio.put(
          '/users/$userId/role',
          queryParameters: {'role': selected},
        );
        _load();
        if (mounted) _showSnack('✓ Rol de $name cambiado a $selected', true);
      } catch (_) {}
    }
  }

  Future<String?> _showReasonDialog(String title, String name) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$title — $name'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Razón (opcional)',
            hintText: 'Ej: Incumplimiento de términos',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success
          ? Theme.of(context).colorScheme.secondary
          : Theme.of(context).colorScheme.error,
    ));
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'ADMIN': return Icons.admin_panel_settings;
      case 'AGENCY': return Icons.business;
      case 'SELLER': return Icons.home_work;
      default: return Icons.person;
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'ADMIN': return 'Administrador';
      case 'AGENCY': return 'Inmobiliaria';
      case 'SELLER': return 'Vendedor';
      default: return 'Comprador';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Administración', style: theme.textTheme.titleLarge),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.colorScheme.primary),
            onPressed: _load,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.outline,
          indicatorColor: theme.colorScheme.primary,
          tabs: [
            Tab(text: 'Stats'),
            Tab(text: 'Activos (${_activeUsers.length})'),
            Tab(text: 'Inactivos (${_inactiveUsers.length})'),
            Tab(text: 'Verificaciones (${_pendingVerifications.length})'),
          ],
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(
          color: theme.colorScheme.primary))
          : Column(
        children: [
          // Buscador
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar usuario...',
                prefixIcon: Icon(Icons.search,
                    color: theme.colorScheme.outline),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () =>
                      setState(() => _searchQuery = ''),
                )
                    : null,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // ── STATS ──
                _buildStats(theme),

                // ── ACTIVOS ──
                _buildUserList(theme, _activeUsers, true),

                // ── INACTIVOS ──
                _buildUserList(theme, _inactiveUsers, false),

                // ── VERIFICACIONES ──
                _buildVerifications(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Resumen general
          Row(
            children: [
              _StatCard(
                theme: theme,
                icon: Icons.people,
                value: '${_stats['total'] ?? 0}',
                label: 'Total usuarios',
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              _StatCard(
                theme: theme,
                icon: Icons.check_circle,
                value: '${_stats['active'] ?? 0}',
                label: 'Activos',
                color: theme.colorScheme.secondary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatCard(
                theme: theme,
                icon: Icons.block,
                value: '${_stats['inactive'] ?? 0}',
                label: 'Inactivos',
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: 12),
              _StatCard(
                theme: theme,
                icon: Icons.business,
                value: '${(_stats['by_role'] ?? {})['AGENCY'] ?? 0}',
                label: 'Inmobiliarias',
                color: theme.colorScheme.tertiary,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Distribución por rol
          Text('Distribución por rol',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          ...[
            ('USER', 'Compradores', theme.colorScheme.primary),
            ('SELLER', 'Vendedores', theme.colorScheme.secondary),
            ('AGENCY', 'Inmobiliarias', theme.colorScheme.tertiary),
            ('ADMIN', 'Admins', theme.colorScheme.error),
          ].map((item) {
            final count = (_stats['by_role'] ?? {})[item.$1] ?? 0;
            final total = _stats['total'] ?? 1;
            final pct = total > 0 ? count / total : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.$2, style: theme.textTheme.bodyMedium),
                      Text('$count',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: item.$3,
                            fontWeight: FontWeight.bold,
                          )),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct.toDouble(),
                      minHeight: 8,
                      backgroundColor:
                      theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(item.$3),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 24),

          // Publicaciones totales + quién publica más
          Text('Publicaciones', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          _StatCard(
            theme: theme,
            icon: Icons.home_work,
            value: '${_dashboardStats['total_properties'] ?? 0}',
            label: 'Propiedades publicadas en total',
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),

          if ((_dashboardStats['top_publishers'] as List?)?.isNotEmpty ?? false) ...[
            Text('Quién publica más', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            ...(_dashboardStats['top_publishers'] as List).map((p) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(p['name'] ?? '',
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    Text('${p['properties_count']}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        )),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
          ],

          // Gráfica de actividad de los últimos 7 días
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Actividad (últimos 7 días)',
                  style: theme.textTheme.titleMedium),
              Text('Se actualiza solo cada minuto',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  )),
            ],
          ),
          const SizedBox(height: 12),
          _ActivityChart(
            theme: theme,
            data: (_dashboardStats['activity_last_7_days'] as List?) ?? [],
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(
      ThemeData theme, List<dynamic> users, bool isActive) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline,
                size: 64, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text(
              isActive ? 'No hay usuarios activos' : 'No hay usuarios inactivos',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final user = users[i];
          final role = user['role'] ?? 'USER';
          final active = user['is_active'] ?? true;

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active
                    ? theme.colorScheme.outlineVariant
                    : theme.colorScheme.error.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: active
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.errorContainer,
                      child: Text(
                        (user['name'] ?? 'U').substring(0, 1).toUpperCase(),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: active
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user['name'] ?? '',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            user['email'] ?? '',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Badge de rol
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _roleLabel(role),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),

                // Badge de suscripción de pago (si aplica)
                if (user['subscription_plan'] != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.workspace_premium,
                            size: 12,
                            color: theme.colorScheme.onTertiaryContainer),
                        const SizedBox(width: 4),
                        Text(
                          '${user['subscription_plan'] == 'agency' ? 'Plan Inmobiliaria' : 'Plan Premium'}'
                              ' · ${user['subscription_status'] ?? 'sin estado'}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onTertiaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Badge de verificación (solo para inmobiliarias)
                if (role == 'AGENCY' && user['verification_status'] != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: user['verification_status'] == 'approved'
                          ? theme.colorScheme.secondaryContainer
                          : user['verification_status'] == 'rejected'
                          ? theme.colorScheme.errorContainer
                          : theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      user['verification_status'] == 'approved'
                          ? 'Verificada'
                          : user['verification_status'] == 'rejected'
                          ? 'Verificación rechazada'
                          : 'Verificación pendiente',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 10),

                // Acciones
                Row(
                  children: [
                    // Cambiar rol
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _changeRole(user['id'], user['name']),
                        icon: Icon(Icons.manage_accounts,
                            size: 14,
                            color: theme.colorScheme.primary),
                        label: Text('Rol',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                            )),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 34),
                          side: BorderSide(
                              color: theme.colorScheme.outlineVariant),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Activar/Desactivar
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: active
                            ? () => _deactivate(user['id'], user['name'])
                            : () => _activate(user['id'], user['name']),
                        icon: Icon(
                          active ? Icons.block : Icons.check_circle_outline,
                          size: 14,
                          color: active
                              ? theme.colorScheme.error
                              : theme.colorScheme.secondary,
                        ),
                        label: Text(
                          active ? 'Bloquear' : 'Activar',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: active
                                ? theme.colorScheme.error
                                : theme.colorScheme.secondary,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 34),
                          side: BorderSide(
                            color: active
                                ? theme.colorScheme.error.withOpacity(0.5)
                                : theme.colorScheme.secondary
                                .withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Eliminar permanente
                    OutlinedButton(
                      onPressed: () =>
                          _deleteUser(user['id'], user['name']),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(34, 34),
                        padding: EdgeInsets.zero,
                        side: BorderSide(
                            color: theme.colorScheme.error.withOpacity(0.5)),
                      ),
                      child: Icon(Icons.delete_forever,
                          size: 16, color: theme.colorScheme.error),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVerifications(ThemeData theme) {
    if (_pendingVerifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_outlined,
                size: 64, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text('No hay verificaciones pendientes',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingVerifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final v = _pendingVerifications[i];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(v['name'] ?? '',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
                Text(v['email'] ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    )),
                const SizedBox(height: 10),
                if (v['document_url'] != null)
                  GestureDetector(
                    onTap: () => _viewDocument(context, v['document_url']),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl:
                        upload.UploadService.getFullUrl(v['document_url']),
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          height: 160,
                          color: theme.colorScheme.surfaceContainerHigh,
                        ),
                        errorWidget: (_, __, ___) => Container(
                          height: 160,
                          color: theme.colorScheme.surfaceContainerHigh,
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () =>
                            _approveVerification(v['id'], v['name']),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Aprobar'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          backgroundColor: theme.colorScheme.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _rejectVerification(v['id'], v['name']),
                        icon: Icon(Icons.close,
                            size: 16, color: theme.colorScheme.error),
                        label: Text('Rechazar',
                            style: TextStyle(color: theme.colorScheme.error)),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          side: BorderSide(
                              color: theme.colorScheme.error.withOpacity(0.5)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _viewDocument(BuildContext context, String documentUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          child: CachedNetworkImage(
            imageUrl: upload.UploadService.getFullUrl(documentUrl),
          ),
        ),
      ),
    );
  }

  Future<void> _approveVerification(String userId, String name) async {
    try {
      await DioClient().dio.post('/users/admin/verifications/$userId/approve');
      _load();
      if (mounted) _showSnack('✓ $name verificado', true);
    } catch (_) {}
  }

  Future<void> _rejectVerification(String userId, String name) async {
    try {
      await DioClient().dio.post('/users/admin/verifications/$userId/reject');
      _load();
      if (mounted) _showSnack('✗ Verificación de $name rechazada', false);
    } catch (_) {}
  }
}

class _UserAdminCard extends StatelessWidget {
  final ThemeData theme;
  final Map<String, dynamic> user;
  final VoidCallback onToggle;
  final VoidCallback onChangeRole;

  const _UserAdminCard({
    required this.theme,
    required this.user,
    required this.onToggle,
    required this.onChangeRole,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = user['is_active'] ?? true;
    final role = user['role'] ?? 'USER';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? theme.colorScheme.outlineVariant
              : theme.colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: isActive
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.errorContainer,
                child: Text(
                  (user['name'] ?? 'U').substring(0, 1).toUpperCase(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: isActive
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name'] ?? '',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      user['email'] ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  role,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onChangeRole,
                  icon: Icon(Icons.manage_accounts,
                      size: 14, color: theme.colorScheme.primary),
                  label: Text('Cambiar rol',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      )),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onToggle,
                  icon: Icon(
                    isActive ? Icons.block : Icons.check_circle_outline,
                    size: 14,
                    color: isActive
                        ? theme.colorScheme.error
                        : theme.colorScheme.secondary,
                  ),
                  label: Text(
                    isActive ? 'Bloquear' : 'Activar',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isActive
                          ? theme.colorScheme.error
                          : theme.colorScheme.secondary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    side: BorderSide(
                      color: isActive
                          ? theme.colorScheme.error.withOpacity(0.5)
                          : theme.colorScheme.secondary.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── PROFILE ──────────────────────────────────────────────────────
class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authVM = context.watch<AuthViewModel>();
    final user = authVM.user;
    final role = user?.role ?? 'USER';

    final roleLabel = {'USER': 'Usuario', 'SELLER': 'Vendedor', 'AGENCY': 'Inmobiliaria', 'ADMIN': 'Administrador'}[role] ?? 'Usuario';
    final roleColor = {'USER': theme.colorScheme.primary, 'SELLER': theme.colorScheme.tertiary, 'AGENCY': theme.colorScheme.secondary, 'ADMIN': theme.colorScheme.error}[role] ?? theme.colorScheme.primary;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header con degradado
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                bottom: 24,
                left: 16,
                right: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primaryContainer,
                  ],
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    backgroundImage: (user?.avatar != null && user!.avatar!.isNotEmpty)
                        ? CachedNetworkImageProvider(upload.UploadService.getFullUrl(user.avatar))
                        : null,
                    child: (user?.avatar == null || user!.avatar!.isEmpty)
                        ? Text(
                      user?.name.substring(0, 1).toUpperCase() ?? 'U',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 36,
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? '',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      roleLabel,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Secciones
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(theme: theme, title: 'Mi cuenta'),
                  _ProfileTile(
                    theme: theme,
                    icon: Icons.edit_outlined,
                    title: 'Editar perfil',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const EditProfileView())),
                  ),
                  _ProfileTile(
                    theme: theme,
                    icon: Icons.chat_bubble_outline,
                    title: 'Mensajes',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const ConversationsView())),
                  ),
                  _ProfileTile(
                    theme: theme,
                    icon: Icons.workspace_premium_outlined,
                    title: 'Obtener Premium',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const PaymentView())),
                  ),
                  _ProfileTile(
                    theme: theme,
                    icon: Icons.history,
                    title: 'Historial de búsquedas',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const HistoryView())),
                  ),
                  _ProfileTile(
                    theme: theme,
                    icon: Icons.calendar_today_outlined,
                    title: 'Mis citas',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AppointmentsView())),
                  ),
                  _ProfileTile(
                    theme: theme,
                    icon: Icons.notifications_outlined,
                    title: 'Notificaciones',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NotificationsView())),
                  ),
                  const SizedBox(height: 16),
                  _SectionHeader(theme: theme, title: 'Soporte'),
                  _ProfileTile(
                    theme: theme,
                    icon: Icons.help_outline,
                    title: 'Centro de ayuda',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const HelpCenterView())),
                  ),
                  _ProfileTile(
                    theme: theme,
                    icon: Icons.description_outlined,
                    title: 'Términos y condiciones',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const TermsView())),
                  ),
                  _ProfileTile(
                    theme: theme,
                    icon: Icons.privacy_tip_outlined,
                    title: 'Política de privacidad',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const PrivacyView())),
                  ),
                  _ProfileTile(
                    theme: theme,
                    icon: Icons.star_outline,
                    title: 'Calificar la app',
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Próximamente en Play Store')),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionHeader(theme: theme, title: 'Sesión'),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => authVM.logout(),
                      icon: Icon(Icons.logout, color: theme.colorScheme.error),
                      label: Text(
                        'Cerrar sesión',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.colorScheme.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text('v1.0.0',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        )),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SHARED WIDGETS ───────────────────────────────────────────────
class _ActivityChart extends StatelessWidget {
  final ThemeData theme;
  final List<dynamic> data;

  const _ActivityChart({required this.theme, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Text('Sin datos de actividad todavía',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            )),
      );
    }

    // Actividad total del día = propiedades nuevas + búsquedas + citas
    final totals = data.map((d) {
      final props = (d['properties'] ?? 0) as int;
      final searches = (d['searches'] ?? 0) as int;
      final appointments = (d['appointments'] ?? 0) as int;
      return props + searches + appointments;
    }).toList();

    final maxValue = totals.isEmpty
        ? 1
        : totals.reduce((a, b) => a > b ? a : b).clamp(1, 1 << 30);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(data.length, (i) {
          final day = data[i];
          final total = totals[i];
          final barHeight = total == 0 ? 4.0 : (total / maxValue) * 90.0 + 4.0;
          final dateStr = (day['date'] ?? '').toString();
          final dayLabel = dateStr.length >= 10
              ? dateStr.substring(8, 10)
              : '';

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$total',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  )),
              const SizedBox(height: 4),
              Container(
                width: 22,
                height: barHeight,
                decoration: BoxDecoration(
                  color: total == 0
                      ? theme.colorScheme.surfaceContainerHighest
                      : theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              Text(dayLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  )),
            ],
          );
        }),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.theme,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
          Text(value,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: color, fontWeight: FontWeight.bold,
              )),
          Text(label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? iconColor;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.theme,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: ListTile(
        leading: Icon(icon,
            color: iconColor ?? theme.colorScheme.primary),
        title: Text(title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            )),
        subtitle: Text(subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            )),
        trailing: Icon(Icons.arrow_forward_ios,
            size: 14, color: theme.colorScheme.outline),
        onTap: onTap,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final ThemeData theme;
  final String title;
  const _SectionHeader({required this.theme, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.outline,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const _ProfileTile({
    required this.theme,
    required this.icon,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: Icon(icon, color: theme.colorScheme.primary, size: 20),
          title: Text(title, style: theme.textTheme.bodyMedium),
          trailing: Icon(Icons.arrow_forward_ios,
              size: 12, color: theme.colorScheme.outline),
          onTap: onTap,
          dense: true,
        ),
      ),
    );
  }
}