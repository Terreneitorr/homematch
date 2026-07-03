import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../viewmodels/property_viewmodel.dart';
import '../widgets/property_card_grid.dart';
import 'create_property_view.dart';
import '../../domain/entities/property_entity.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../favorites/presentation/viewmodels/favorites_viewmodel.dart';

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
          if (role == 'SELLER' || role == 'AGENCY' || role == 'ADMIN')
            IconButton(
              icon: Icon(Icons.add_circle_outline,
                  color: theme.colorScheme.primary),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CreatePropertyView())),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              child: CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primary,
                child: Text(
                  authVM.user?.name.substring(0, 1).toUpperCase() ?? 'U',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Buscador
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
                  '${vm.properties.length} propiedades',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
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
                child: const Text('Reintentar'),
              ),
            ],
          ),
        );
      case PropertyStatus2.loaded:
        if (vm.properties.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.home_work_outlined,
                    size: 64, color: theme.colorScheme.outlineVariant),
                const SizedBox(height: 16),
                Text('No hay propiedades',
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
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
          itemCount: vm.properties.length,
          itemBuilder: (_, i) {
            final prop = vm.properties[i];
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