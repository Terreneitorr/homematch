import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/search_viewmodel.dart';
import '../../../properties/presentation/viewmodels/property_viewmodel.dart';
import '../../../properties/presentation/widgets/property_card.dart';
import '../../../properties/domain/entities/property_entity.dart';
import '../../../favorites/presentation/viewmodels/favorites_viewmodel.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';

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
  Widget build(BuildContext context) {
    final searchVM = context.watch<SearchViewModel>();
    final favVM = context.watch<FavoritesViewModel>();
    final authVM = context.read<AuthViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Buscar', style: theme.textTheme.titleLarge),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Casa con jardín cerca del centro...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchCtrl.clear();
                    searchVM.search('');
                  },
                )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: searchVM.search,
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                _filterChip(context, 'Todos', searchVM.filterType == null,
                        () => searchVM.setFilterType(null)),
                const SizedBox(width: 8),
                _filterChip(context, 'Venta',
                    searchVM.filterType == OperationType.sale,
                        () => searchVM.setFilterType(OperationType.sale)),
                const SizedBox(width: 8),
                _filterChip(context, 'Renta',
                    searchVM.filterType == OperationType.rent,
                        () => searchVM.setFilterType(OperationType.rent)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
          Expanded(
            child: searchVM.results.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off,
                      size: 64,
                      color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text('Sin resultados',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      )),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: searchVM.results.length,
              itemBuilder: (_, i) {
                final property = searchVM.results[i];
                return Stack(
                  children: [
                    PropertyCard(
                      property: property,
                      onDelete: () {},
                    ),
                    Positioned(
                      top: 8,
                      right: 48,
                      child: IconButton(
                        icon: Icon(
                          favVM.isFavorite(property.id)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: favVM.isFavorite(property.id)
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () => favVM.toggleFavorite(
                            authVM.user?.id ?? '', property),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(
      BuildContext context, String label, bool selected, VoidCallback onTap) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: selected
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurfaceVariant,
            fontWeight:
            selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}