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
import '../../../../core/network/dio_client.dart';

class MainNavigationView extends StatefulWidget {
  const MainNavigationView({super.key});

  @override
  State<MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends State<MainNavigationView> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!mounted) return;
      final propVM = context.read<PropertyViewModel>();
      final favVM = context.read<FavoritesViewModel>();
      final authVM = context.read<AuthViewModel>();
      await propVM.loadProperties();
      await favVM.loadFavorites(
          authVM.user?.id ?? '', propVM.properties);
    });
  }

  List<Widget> _getPages(String role) {
    switch (role) {
      case 'SELLER':
        return const [PropertiesView(), _SellerDashboard(), _ProfileView()];
      case 'AGENCY':
        return const [PropertiesView(), _AgencyDashboard(), _ProfileView()];
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
class _AgencyDashboard extends StatelessWidget {
  const _AgencyDashboard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard Inmobiliaria', style: theme.textTheme.titleLarge),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                _StatCard(theme: theme, icon: Icons.home_work, value: '0', label: 'Propiedades', color: theme.colorScheme.primary),
                _StatCard(theme: theme, icon: Icons.people, value: '0', label: 'Agentes', color: theme.colorScheme.secondary),
                _StatCard(theme: theme, icon: Icons.calendar_today, value: '0', label: 'Citas', color: theme.colorScheme.tertiary),
                _StatCard(theme: theme, icon: Icons.person, value: '0', label: 'Clientes', color: theme.colorScheme.error),
              ],
            ),
            const SizedBox(height: 24),
            Text('Gestión', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _ActionTile(theme: theme, icon: Icons.people_alt, title: 'Gestionar agentes', subtitle: 'Administra tu equipo'),
            _ActionTile(theme: theme, icon: Icons.bar_chart, title: 'Reportes', subtitle: 'Estadísticas avanzadas'),
            _ActionTile(theme: theme, icon: Icons.verified, title: 'Cuenta verificada', subtitle: 'Estado de verificación'),
          ],
        ),
      ),
    );
  }
}

// ─── ADMIN PANEL ──────────────────────────────────────────────────
class _AdminPanel extends StatelessWidget {
  const _AdminPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Administración', style: theme.textTheme.titleLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ActionTile(theme: theme, icon: Icons.people, title: 'Gestionar usuarios', subtitle: 'Ver, bloquear o activar cuentas', iconColor: theme.colorScheme.error),
          _ActionTile(theme: theme, icon: Icons.verified_user, title: 'Validar inmobiliarias', subtitle: 'Aprobar cuentas de agencias', iconColor: theme.colorScheme.error),
          _ActionTile(theme: theme, icon: Icons.report, title: 'Contenido reportado', subtitle: 'Revisar publicaciones reportadas', iconColor: theme.colorScheme.error),
          _ActionTile(theme: theme, icon: Icons.block, title: 'Cuentas bloqueadas', subtitle: 'Gestionar bloqueos', iconColor: theme.colorScheme.error),
          _ActionTile(theme: theme, icon: Icons.analytics, title: 'Estadísticas globales', subtitle: 'Métricas de la plataforma', iconColor: theme.colorScheme.error),
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
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      user?.name.substring(0, 1).toUpperCase() ?? 'U',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 36,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                  _ProfileTile(theme: theme, icon: Icons.help_outline, title: 'Centro de ayuda'),
                  _ProfileTile(theme: theme, icon: Icons.description_outlined, title: 'Términos y condiciones'),
                  _ProfileTile(theme: theme, icon: Icons.privacy_tip_outlined, title: 'Política de privacidad'),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary, size: 20),
        title: Text(title, style: theme.textTheme.bodyMedium),
        trailing: Icon(Icons.arrow_forward_ios,
            size: 12, color: theme.colorScheme.outline),
        onTap: onTap,
        dense: true,
      ),
    );
  }
}
