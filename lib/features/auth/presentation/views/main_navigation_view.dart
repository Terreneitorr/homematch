import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../../properties/presentation/views/properties_view.dart';
import '../../../favorites/presentation/views/favorites_view.dart';
import '../../../search/presentation/views/search_view.dart';

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
      final authVM = context.read<AuthViewModel>();
      final propVM = context.read<dynamic>();
      await context.read<dynamic>().loadProperties();
    });
  }

  List<Widget> _getPages(String role) {
    switch (role) {
      case 'SELLER':
        return const [
          PropertiesView(),
          _SellerDashboardView(),
          _ProfileView(),
        ];
      case 'AGENCY':
        return const [
          PropertiesView(),
          _AgencyDashboardView(),
          _ProfileView(),
        ];
      case 'ADMIN':
        return const [
          PropertiesView(),
          _AdminView(),
          _ProfileView(),
        ];
      default: // USER
        return const [
          PropertiesView(),
          SearchView(),
          FavoritesView(),
          _ProfileView(),
        ];
    }
  }

  List<BottomNavigationBarItem> _getNavItems(String role) {
    switch (role) {
      case 'SELLER':
        return const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_work_rounded),
            label: 'Mis Propiedades',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ];
      case 'AGENCY':
        return const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_work_rounded),
            label: 'Propiedades',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ];
      case 'ADMIN':
        return const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_work_rounded),
            label: 'Propiedades',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings_rounded),
            label: 'Admin',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ];
      default: // USER
        return const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_work_rounded),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_rounded),
            label: 'Buscar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_rounded),
            label: 'Favoritos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthViewModel>().user?.role ?? 'USER';
    final pages = _getPages(role);
    final navItems = _getNavItems(role);
    final safeIndex = _currentIndex >= pages.length ? 0 : _currentIndex;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: pages[safeIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        backgroundColor: const Color(0xFF1D1E33),
        selectedItemColor: const Color(0xFF4A90E2),
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        items: navItems,
      ),
    );
  }
}

// ─── SELLER DASHBOARD ───────────────────────────────────────────
class _SellerDashboardView extends StatelessWidget {
  const _SellerDashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E21),
        title: const Text('Mi Dashboard', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Resumen', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                _statCard('Propiedades', '3', Icons.home_work_rounded, Colors.blue),
                const SizedBox(width: 12),
                _statCard('Activas', '2', Icons.check_circle_rounded, Colors.green),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _statCard('Citas', '1', Icons.calendar_today_rounded, Colors.orange),
                const SizedBox(width: 12),
                _statCard('Mensajes', '0', Icons.message_rounded, Colors.purple),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Acciones rápidas', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _actionTile(Icons.add_home_rounded, 'Publicar propiedad', 'Agrega una nueva propiedad', () {}),
            _actionTile(Icons.edit_rounded, 'Gestionar propiedades', 'Edita o elimina tus publicaciones', () {}),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1D1E33),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _actionTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF4A90E2)),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
        onTap: onTap,
      ),
    );
  }
}

// ─── AGENCY DASHBOARD ───────────────────────────────────────────
class _AgencyDashboardView extends StatelessWidget {
  const _AgencyDashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E21),
        title: const Text('Dashboard Inmobiliaria', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Estadísticas', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                _statCard('Propiedades', '12', Icons.home_work_rounded, Colors.blue),
                const SizedBox(width: 12),
                _statCard('Agentes', '3', Icons.people_rounded, Colors.green),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _statCard('Citas', '5', Icons.calendar_today_rounded, Colors.orange),
                const SizedBox(width: 12),
                _statCard('Clientes', '8', Icons.person_rounded, Colors.purple),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Gestión', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _actionTile(Icons.people_alt_rounded, 'Gestionar agentes', 'Administra tu equipo', () {}),
            _actionTile(Icons.bar_chart_rounded, 'Reportes', 'Consulta estadísticas avanzadas', () {}),
            _actionTile(Icons.verified_rounded, 'Cuenta verificada', 'Estado de verificación', () {}),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1D1E33),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _actionTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF4A90E2)),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
        onTap: onTap,
      ),
    );
  }
}

// ─── ADMIN VIEW ─────────────────────────────────────────────────
class _AdminView extends StatelessWidget {
  const _AdminView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E21),
        title: const Text('Panel Admin', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Administración', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _actionTile(Icons.people_rounded, 'Gestionar usuarios', 'Ver, bloquear o activar cuentas', () {}),
            _actionTile(Icons.verified_user_rounded, 'Validar inmobiliarias', 'Aprobar cuentas de agencias', () {}),
            _actionTile(Icons.report_rounded, 'Reportes de contenido', 'Revisar publicaciones reportadas', () {}),
            _actionTile(Icons.block_rounded, 'Cuentas bloqueadas', 'Gestionar bloqueos', () {}),
            _actionTile(Icons.analytics_rounded, 'Estadísticas globales', 'Métricas de la plataforma', () {}),
          ],
        ),
      ),
    );
  }

  Widget _actionTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.redAccent),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
        onTap: onTap,
      ),
    );
  }
}

// ─── PROFILE VIEW ───────────────────────────────────────────────
class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final user = authVM.user;
    final role = user?.role ?? 'USER';

    Color roleColor;
    String roleLabel;
    switch (role) {
      case 'SELLER':
        roleColor = Colors.orange;
        roleLabel = 'Vendedor';
        break;
      case 'AGENCY':
        roleColor = Colors.purple;
        roleLabel = 'Inmobiliaria';
        break;
      case 'ADMIN':
        roleColor = Colors.redAccent;
        roleLabel = 'Administrador';
        break;
      default:
        roleColor = const Color(0xFF4A90E2);
        roleLabel = 'Usuario';
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E21),
        title: const Text('Mi Perfil', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 32),
            CircleAvatar(
              radius: 48,
              backgroundColor: roleColor,
              child: Text(
                user?.name.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user?.name ?? '',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(user?.email ?? '', style: const TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: roleColor),
              ),
              child: Text(
                roleLabel,
                style: TextStyle(color: roleColor, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 40),
            const Divider(color: Colors.white12),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.white54),
              title: const Text('Versión', style: TextStyle(color: Colors.white70)),
              trailing: const Text('1.0.0', style: TextStyle(color: Colors.white38)),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => authVM.logout(),
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text('Cerrar sesión', style: TextStyle(color: Colors.white, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.withOpacity(0.8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}