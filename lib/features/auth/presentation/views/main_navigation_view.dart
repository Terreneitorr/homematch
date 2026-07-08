import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:homematch_ai/features/analytics/presentation/views/analytics_view.dart' hide AnalyticsView;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../../properties/presentation/views/properties_view.dart';
import '../../../favorites/presentation/views/favorites_view.dart';
import '../../../search/presentation/views/search_view.dart';
import '../../../properties/presentation/viewmodels/property_viewmodel.dart';
import '../../../favorites/presentation/viewmodels/favorites_viewmodel.dart';
import '../../../appointments/presentation/views/appointments_view.dart';
import '../../../appointments/presentation/views/appointments_view.dart';
import '../../../analytics/presentation/views/analytics_view.dart';
import '../../../../features/profile/presentation/views/edit_profile_view.dart';
import '../../../../features/history/presentation/views/history_view.dart';
import '../../../properties/presentation/views/create_property_view.dart';
import '../../../../features/profile/presentation/views/agency_profile_view.dart';
import '../../../../features/info/presentation/views/help_center_view.dart';
import '../../../../features/info/presentation/views/terms_view.dart';
import '../../../../features/info/presentation/views/privacy_view.dart';
import '../../../../core/network/dio_client.dart';

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
    Future.microtask(() async {
      if (!mounted) return;

      final authVM = context.read<AuthViewModel>();

      // Si el usuario está vacío, hacer logout y regresar al login
      if (authVM.user == null || authVM.user!.id.isEmpty) {
        await authVM.logout();
        return;
      }

      final propVM = context.read<PropertyViewModel>();
      final favVM = context.read<FavoritesViewModel>();

      await propVM.loadProperties();
      if (propVM.properties.isNotEmpty) {
        await favVM.loadFavorites(
          authVM.user?.id ?? '',
          propVM.properties,
        );
      }
    });
  }

  List<Widget> _getPages(String role) {
    switch (role) {
      case 'SELLER':
        return const [PropertiesView(), _SellerDashboard(), _ProfileView()];
      case 'AGENCY':
        return const [PropertiesView(), _AgencyDashboard(), AgencyProfileView()];
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
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ];
      case 'AGENCY':
        return const [
          NavigationDestination(icon: Icon(Icons.home_work_outlined), selectedIcon: Icon(Icons.home_work), label: 'Propiedades'),
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
          'messages': 0,
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
                    icon: Icons.bar_chart,
                    value: '${_stats['total_views']}',
                    label: 'En plataforma',
                    color: theme.colorScheme.error,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Propiedades recientes
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
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.verified, color: theme.colorScheme.secondary),
            const SizedBox(width: 8),
            const Text('Verificación'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle,
                      color: theme.colorScheme.secondary, size: 20),
                  const SizedBox(width: 8),
                  Text('Cuenta activa',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      )),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tu cuenta de inmobiliaria está activa. Para obtener el sello de verificación, contacta al administrador.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
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

class _AdminPanelState extends State<_AdminPanel> {
  List<dynamic> _users = [];
  Map<String, dynamic> _analytics = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final usersRes = await DioClient().dio.get('/users/');
      final analyticsRes = await DioClient().dio.get('/analytics/');
      setState(() {
        _users = usersRes.data;
        _analytics = analyticsRes.data;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleUser(String userId, bool currentStatus) async {
    try {
      await DioClient().dio.put('/users/$userId/toggle-active');
      _load();
    } catch (_) {}
  }

  Future<void> _changeRole(BuildContext context, ThemeData theme, String userId) async {
    final roles = ['USER', 'SELLER', 'AGENCY', 'ADMIN'];
    final selected = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cambiar rol'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: roles.map((r) => ListTile(
            title: Text(r),
            onTap: () => Navigator.pop(context, r),
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Rol actualizado a $selected'),
              backgroundColor: theme.colorScheme.secondary,
            ),
          );
        }
      } catch (_) {}
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
              // Stats globales
              Text('Estadísticas globales',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatCard(
                    theme: theme,
                    icon: Icons.people,
                    value: '${_users.length}',
                    label: 'Usuarios',
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    theme: theme,
                    icon: Icons.home_work,
                    value: '${_analytics['total_properties'] ?? 0}',
                    label: 'Propiedades',
                    color: theme.colorScheme.secondary,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Lista de usuarios
              Text('Gestión de usuarios',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              ..._users.map((user) => _UserAdminCard(
                theme: theme,
                user: user,
                onToggle: () => _toggleUser(
                    user['id'], user['is_active'] ?? true),
                onChangeRole: () =>
                    _changeRole(context, theme, user['id']),
              )),
            ],
          ),
        ),
      ),
    );
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
                        ? NetworkImage(user.avatar!)
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
                    icon: Icons.history,
                    title: 'Historial de búsquedas',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const HistoryView())),
                  ),
                  _ProfileTile(
                    theme: theme,
                    icon: Icons.calendar_today_outlined,
                    title: 'Mis citas',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AppointmentsView())),
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
