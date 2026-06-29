import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/favorites_viewmodel.dart';
import '../../../properties/presentation/widgets/property_card.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';

class FavoritesView extends StatelessWidget {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context) {
    final favVM = context.watch<FavoritesViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Favoritos', style: theme.textTheme.titleLarge),
      ),
      body: favVM.favoriteProperties.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border,
                size: 64, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text('Aún no tienes favoritos',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
            const SizedBox(height: 8),
            Text('Busca propiedades y guárdalas aquí',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                )),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: favVM.favoriteProperties.length,
        itemBuilder: (_, i) {
          final property = favVM.favoriteProperties[i];
          return PropertyCard(
            property: property,
            onDelete: () => favVM.toggleFavorite(
              context.read<AuthViewModel>().user?.id ?? '',
              property,
            ),
          );
        },
      ),
    );
  }
}