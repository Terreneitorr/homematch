import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/favorites_viewmodel.dart';
import '../../../properties/presentation/widgets/property_card_grid.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';

class FavoritesView extends StatelessWidget {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favVM = context.watch<FavoritesViewModel>();
    final authVM = context.read<AuthViewModel>();

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
                size: 72, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text('Aún no tienes favoritos',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                )),
            const SizedBox(height: 8),
            Text('Guarda propiedades que te interesen',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                minimumSize: const Size(200, 48),
              ),
              child: const Text('Explorar propiedades'),
            ),
          ],
        ),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.7,
        ),
        itemCount: favVM.favoriteProperties.length,
        itemBuilder: (_, i) {
          final prop = favVM.favoriteProperties[i];
          return PropertyCardGrid(
            property: prop,
            isFavorite: true,
            onDelete: () {},
            onFavorite: () => favVM.toggleFavorite(
                authVM.user?.id ?? '', prop),
          );
        },
      ),
    );
  }
}