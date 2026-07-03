import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:homematch_ai/features/search/presentation/viewmodels/search_viewmodel.dart';
import 'package:homematch_ai/features/properties/presentation/viewmodels/property_viewmodel.dart';
import 'package:homematch_ai/features/properties/presentation/widgets/property_card_grid.dart';
import 'package:homematch_ai/features/properties/domain/entities/property_entity.dart';
import 'package:homematch_ai/features/favorites/presentation/viewmodels/favorites_viewmodel.dart';
import 'package:homematch_ai/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:homematch_ai/core/network/dio_client.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final properties = context.read<PropertyViewModel>().properties;
    context.read<SearchViewModel>().setProperties(properties);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchVM = context.watch<SearchViewModel>();
    final favVM = context.watch<FavoritesViewModel>();
    final authVM = context.read<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Buscar', style: theme.textTheme.titleLarge),
        actions: [
          IconButton(
            icon: Icon(Icons.tune, color: theme.colorScheme.onSurface),
            onPressed: () => _showFilters(context, searchVM, theme),
          ),
        ],
      ),
      body: Column(
        children: [
          // Buscador
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Casa con jardín cerca del centro...',
                prefixIcon: Icon(Icons.search, color: theme.colorScheme.outline),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, color: theme.colorScheme.outline),
                  onPressed: () {
                    _searchCtrl.clear();
                    searchVM.search('');
                    setState(() {});
                  },
                )
                    : null,
              ),
              onChanged: (v) {
                searchVM.search(v);
                setState(() {});

                // Guardar búsqueda en el historial
                if (v.length > 3) {
                  DioClient().dio.post(
                    '/history/',
                    queryParameters: {'query': v},
                  ).then((_) {}).catchError((_) {
                    // Al usar .then() primero, el catchError ya no requiere devolver un Response
                  });
                }
              },
            ),
          ),
          // Chips filtro rápido
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  theme: theme,
                  label: 'Todos',
                  selected: searchVM.filterType == null,
                  onTap: () => searchVM.setFilterType(null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  theme: theme,
                  label: 'Venta',
                  selected: searchVM.filterType == OperationType.sale,
                  onTap: () => searchVM.setFilterType(OperationType.sale),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  theme: theme,
                  label: 'Renta',
                  selected: searchVM.filterType == OperationType.rent,
                  onTap: () => searchVM.setFilterType(OperationType.rent),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Contador
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${searchVM.results.length} resultados',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Resultados
          Expanded(
            child: searchVM.results.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off,
                      size: 64, color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text('Sin resultados',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      )),
                  const SizedBox(height: 8),
                  Text('Intenta con otros términos',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      )),
                ],
              ),
            )
                : GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.7,
              ),
              itemCount: searchVM.results.length,
              itemBuilder: (_, i) {
                final prop = searchVM.results[i];
                return PropertyCardGrid(
                  property: prop,
                  onDelete: () {},
                  isFavorite: favVM.isFavorite(prop.id),
                  onFavorite: () => favVM.toggleFavorite(
                      authVM.user?.id ?? '', prop),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFilters(
      BuildContext context, SearchViewModel searchVM, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FiltersSheet(searchVM: searchVM, theme: theme),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final ThemeData theme;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.theme,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: selected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _FiltersSheet extends StatefulWidget {
  final SearchViewModel searchVM;
  final ThemeData theme;
  const _FiltersSheet({required this.searchVM, required this.theme});

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  OperationType? _type;
  RangeValues _priceRange = const RangeValues(0, 5000000);

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24, right: 24, top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Filtros', style: theme.textTheme.titleLarge),
          const SizedBox(height: 20),
          Text('Tipo de operación',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
          const SizedBox(height: 8),
          Row(
            children: [
              _TypeButton(
                theme: theme,
                label: 'Venta',
                selected: _type == OperationType.sale,
                onTap: () => setState(() =>
                _type = _type == OperationType.sale ? null : OperationType.sale),
              ),
              const SizedBox(width: 8),
              _TypeButton(
                theme: theme,
                label: 'Renta',
                selected: _type == OperationType.rent,
                onTap: () => setState(() =>
                _type = _type == OperationType.rent ? null : OperationType.rent),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Rango de precio',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('\$${(_priceRange.start / 1000).toStringAsFixed(0)}K',
                  style: theme.textTheme.bodySmall),
              Text('\$${(_priceRange.end / 1000).toStringAsFixed(0)}K',
                  style: theme.textTheme.bodySmall),
            ],
          ),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 5000000,
            divisions: 50,
            activeColor: theme.colorScheme.primary,
            inactiveColor: theme.colorScheme.outlineVariant,
            onChanged: (v) => setState(() => _priceRange = v),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _type = null;
                      _priceRange = const RangeValues(0, 5000000);
                    });
                    widget.searchVM.clearFilters();
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                  child: const Text('Limpiar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: () {
                    widget.searchVM.setFilterType(_type);
                    widget.searchVM.setMaxPrice(_priceRange.end);
                    Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                  child: const Text('Aplicar filtros'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final ThemeData theme;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TypeButton({required this.theme, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Text(label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: selected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            )),
      ),
    );
  }
}
