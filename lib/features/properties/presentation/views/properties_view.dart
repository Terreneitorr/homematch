import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../viewmodels/property_viewmodel.dart';
import '../widgets/property_card_grid.dart';
import 'create_property_view.dart';
import '../../domain/entities/property_entity.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../auth/presentation/views/main_navigation_view.dart';
import '../../../favorites/presentation/viewmodels/favorites_viewmodel.dart';
import '../../../recommendations/presentation/views/recommendations_view.dart';
import '../../../../core/network/dio_client.dart';
import '../../../notifications/presentation/views/notifications_view.dart';

class PropertiesView extends StatefulWidget {
  const PropertiesView({super.key});

  @override
  State<PropertiesView> createState() => _PropertiesViewState();
}

class _PropertiesViewState extends State<PropertiesView> {
  int _filterIndex = 0;
  final _filters = ['Todos', 'Venta', 'Renta', 'Casa', 'Depto'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<PropertyViewModel>().loadProperties());
  }

  List<PropertyEntity> _getFilteredProperties(PropertyViewModel vm) {
    switch (_filterIndex) {
      case 1: // Venta
        return vm.properties
            .where((p) => p.operationType == OperationType.sale)
            .toList();
      case 2: // Renta
        return vm.properties
            .where((p) => p.operationType == OperationType.rent)
            .toList();
      case 3: // Casa
        return vm.properties
            .where((p) =>
        p.title.toLowerCase().contains('casa') ||
            p.description.toLowerCase().contains('casa'))
            .toList();
      case 4: // Depto
        return vm.properties
            .where((p) =>
        p.title.toLowerCase().contains('depto') ||
            p.title.toLowerCase().contains('departamento') ||
            p.description.toLowerCase().contains('departamento'))
            .toList();
      default: // Todos
        return vm.properties;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PropertyViewModel>();
    final theme = Theme.of(context);
    final authVM = context.watch<AuthViewModel>();
    final favVM = context.watch<FavoritesViewModel>();
    final role = authVM.user?.role ?? 'USER';

    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'HomeMatch ',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              TextSpan(
                text: 'AI',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Campana con badge
          const _NotificationBell(),
          if (role == 'SELLER' || role == 'AGENCY' || role == 'ADMIN')
            IconButton(
              icon: Icon(Icons.add_circle_outline,
                  color: theme.colorScheme.primary),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CreatePropertyView())),
            ),
          IconButton(
            icon: Icon(Icons.auto_awesome_outlined,
                color: theme.colorScheme.primary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const RecommendationsView()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.primary,
              backgroundImage: (authVM.user?.avatar != null &&
                  authVM.user!.avatar!.isNotEmpty)
                  ? NetworkImage(authVM.user!.avatar!) as ImageProvider
                  : null,
              child: (authVM.user?.avatar == null ||
                  authVM.user!.avatar!.isEmpty)
                  ? Text(
                authVM.user?.name.substring(0, 1).toUpperCase() ?? 'U',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              )
                  : null,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Buscador
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: GestureDetector(
              onTap: () {
                // Navegar al tab de Buscar (index 1)
                final navState = context
                    .findAncestorStateOfType<MainNavigationViewState>();
                navState?.goToTab(1);
              },
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Icon(Icons.search,
                        color: theme.colorScheme.outline, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Buscar propiedades...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Chips filtro
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final sel = _filterIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => _filterIndex = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: sel
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: sel
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _filters[i],
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: sel
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Contador
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Text(
                  '${_getFilteredProperties(vm).length} propiedades',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (_filterIndex != 0) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _filterIndex = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.close,
                              size: 12,
                              color: theme.colorScheme.onErrorContainer),
                          const SizedBox(width: 4),
                          Text(
                            'Limpiar filtro',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Grid
          Expanded(
            child: _buildBody(vm, theme, favVM, authVM),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(PropertyViewModel vm, ThemeData theme,
      FavoritesViewModel favVM, AuthViewModel authVM) {
    switch (vm.status) {
      case PropertyStatus2.loading:
      case PropertyStatus2.initial:
        return Center(
            child: CircularProgressIndicator(
                color: theme.colorScheme.primary));
      case PropertyStatus2.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text(vm.errorMessage ?? 'Error',
                  style: TextStyle(color: theme.colorScheme.error)),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => vm.loadProperties(),
                style: FilledButton.styleFrom(
                    minimumSize: const Size(160, 44)),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        );
      case PropertyStatus2.loaded:
        final filtered = _getFilteredProperties(vm);

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.home_work_outlined,
                    size: 64,
                    color: theme.colorScheme.outlineVariant),
                const SizedBox(height: 16),
                Text(
                  vm.properties.isEmpty
                      ? 'No hay propiedades'
                      : 'Sin resultados para este filtro',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (vm.properties.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => setState(() => _filterIndex = 0),
                    child: const Text('Ver todas'),
                  ),
                ],
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.7,
          ),
          itemCount: filtered.length,
          itemBuilder: (_, i) {
            final prop = filtered[i];
            return PropertyCardGrid(
              property: prop,
              segmento: vm.getSegmento(prop.id),
              onDelete: () => vm.deleteProperty(prop.id),
              isFavorite: favVM.isFavorite(prop.id),
              onFavorite: () => favVM.toggleFavorite(
                  authVM.user?.id ?? '', prop),
            );
          },
        );
    }
  }
}

class _NotificationBell extends StatefulWidget {
  const _NotificationBell();

  @override
  State<_NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<_NotificationBell> {
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  Future<void> _loadCount() async {
    try {
      final res =
      await DioClient().dio.get('/notifications/unread-count');
      setState(() => _count = res.data['count'] ?? 0);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        IconButton(
          icon: Icon(
            _count > 0
                ? Icons.notifications_rounded
                : Icons.notifications_outlined,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const NotificationsView()),
            );
            _loadCount();
          },
        ),
        if (_count > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: theme.colorScheme.error,
                shape: BoxShape.circle,
                border: Border.all(
                    color: theme.colorScheme.surface, width: 1.5),
              ),
              child: Center(
                child: Text(
                  _count > 9 ? '9+' : '$_count',
                  style: TextStyle(
                    color: theme.colorScheme.onError,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
