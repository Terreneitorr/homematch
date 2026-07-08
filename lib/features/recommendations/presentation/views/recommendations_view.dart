import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:homematch_ai/core/network/dio_client.dart';
import 'package:homematch_ai/features/properties/data/models/property_model.dart';
import 'package:homematch_ai/features/properties/presentation/widgets/property_card_grid.dart';
import 'package:homematch_ai/features/favorites/presentation/viewmodels/favorites_viewmodel.dart';
import 'package:homematch_ai/features/auth/presentation/viewmodels/auth_viewmodel.dart';

class RecommendationsView extends StatefulWidget {
  const RecommendationsView({super.key});

  @override
  State<RecommendationsView> createState() => _RecommendationsViewState();
}

class _RecommendationsViewState extends State<RecommendationsView> {
  List<PropertyModel> _recommendations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final favRes = await DioClient().dio.get('/favorites/');
      final favIds = (favRes.data as List)
          .map((f) => f['property_id'] as String)
          .toList();

      final propRes = await DioClient().dio.get('/properties/');
      final allProps = (propRes.data as List)
          .map((p) => PropertyModel.fromJson(p))
          .toList();

      // Propiedades favoritas del usuario
      final favProps = allProps.where((p) => favIds.contains(p.id)).toList();

      if (favIds.isEmpty || favProps.isEmpty) {
        // Sin favoritos — mostrar todas mezcladas
        allProps.shuffle();
        setState(() {
          _recommendations = allProps.take(6).toList();
          _loading = false;
        });
        return;
      }

      // Calcular características promedio de los favoritos
      final avgPrice =
          favProps.map((p) => p.price).reduce((a, b) => a + b) / favProps.length;
      final avgBedrooms =
          favProps.map((p) => p.bedrooms).reduce((a, b) => a + b) /
              favProps.length;
      final avgArea =
          favProps.map((p) => p.area).reduce((a, b) => a + b) / favProps.length;

      // Solo propiedades que NO son favoritas
      final candidates =
          allProps.where((p) => !favIds.contains(p.id)).toList();

      if (candidates.isEmpty) {
        // Todas las propiedades son favoritas, mostrar las favoritas
        setState(() {
          _recommendations = favProps;
          _loading = false;
        });
        return;
      }

      // Ordenar por similitud — menor score = más similar
      candidates.sort((a, b) {
        final scoreA = _similarityScore(a, avgPrice, avgBedrooms, avgArea);
        final scoreB = _similarityScore(b, avgPrice, avgBedrooms, avgArea);
        return scoreA.compareTo(scoreB); // ascendente = más similares primero
      });

      setState(() {
        _recommendations = candidates.take(6).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudieron cargar recomendaciones';
        _loading = false;
      });
    }
  }

  double _similarityScore(
      PropertyModel p, double avgPrice, double avgBedrooms, double avgArea) {
    // Normalizar diferencias — menor diferencia = más similar
    final priceDiff = (p.price - avgPrice).abs() / (avgPrice + 1);
    final bedroomsDiff = (p.bedrooms - avgBedrooms).abs() / (avgBedrooms + 1);
    final areaDiff = (p.area - avgArea).abs() / (avgArea + 1);
    // Peso: precio 50%, área 30%, habitaciones 20%
    return priceDiff * 0.5 + areaDiff * 0.3 + bedroomsDiff * 0.2;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favVM = context.watch<FavoritesViewModel>();
    final authVM = context.read<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Para ti', style: theme.textTheme.titleLarge),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.colorScheme.primary),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Analizando tus preferencias...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: theme.colorScheme.error),
                      const SizedBox(height: 12),
                      Text(_error!, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _load,
                        style: FilledButton.styleFrom(
                            minimumSize: const Size(160, 44)),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primaryContainer,
                                theme.colorScheme.secondaryContainer,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.auto_awesome,
                                  color: theme.colorScheme.primary, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Recomendaciones personalizadas',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                        color: theme.colorScheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Basadas en tus favoritos y búsquedas',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: theme.colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_recommendations.isEmpty)
                      SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.favorite_border,
                                  size: 64,
                                  color: theme.colorScheme.outlineVariant),
                              const SizedBox(height: 16),
                              Text(
                                'Guarda favoritos para ver\nrecomendaciones personalizadas',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        sliver: SliverGrid(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => PropertyCardGrid(
                              property: _recommendations[i],
                              onDelete: () {},
                              isFavorite:
                                  favVM.isFavorite(_recommendations[i].id),
                              onFavorite: () => favVM.toggleFavorite(
                                  authVM.user?.id ?? '', _recommendations[i]),
                            ),
                            childCount: _recommendations.length,
                          ),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.7,
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}
