import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/property_entity.dart';

class PropertyDetailView extends StatelessWidget {
  final PropertyEntity property;
  final String? segmento;

  const PropertyDetailView({
    super.key,
    required this.property,
    this.segmento,
  });

  String _formatPrice(double price) {
    if (price >= 1000000) return '\$${(price / 1000000).toStringAsFixed(2)}M';
    if (price >= 1000) return '\$${(price / 1000).toStringAsFixed(0)}K';
    return '\$${price.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRent = property.operationType == OperationType.rent;
    final price = isRent
        ? '${_formatPrice(property.price)}/mes'
        : _formatPrice(property.price);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar con imagen
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: theme.colorScheme.surface,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleButton(
                theme: theme,
                icon: Icons.arrow_back,
                onTap: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: CircleButton(
                  theme: theme,
                  icon: Icons.share_outlined,
                  onTap: () {},
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: theme.colorScheme.surfaceContainerHigh,
                    child: Icon(
                      Icons.home_work_rounded,
                      size: 80,
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                  // Badge
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isRent
                            ? theme.colorScheme.tertiaryContainer
                            : theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isRent ? 'RENTA' : 'VENTA',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: isRent
                              ? theme.colorScheme.onTertiaryContainer
                              : theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Contenido
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Precio y título
                  Text(
                    price,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    property.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 16, color: theme.colorScheme.outline),
                      const SizedBox(width: 4),
                      Text(
                        '${property.zone}, ${property.city}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),

                  // Tag IA
                  if (segmento != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome,
                              size: 14,
                              color: theme.colorScheme.onSecondaryContainer),
                          const SizedBox(width: 6),
                          Text(
                            'IA: $segmento',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  Divider(color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: 20),

                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        theme: theme,
                        icon: Icons.bed_outlined,
                        value: '${property.bedrooms}',
                        label: 'Habitaciones',
                      ),
                      _Divider(theme: theme),
                      _StatItem(
                        theme: theme,
                        icon: Icons.bathtub_outlined,
                        value: '${property.bathrooms}',
                        label: 'Baños',
                      ),
                      _Divider(theme: theme),
                      _StatItem(
                        theme: theme,
                        icon: Icons.square_foot,
                        value: '${property.area.toInt()}',
                        label: 'm²',
                      ),
                      if (property.hasGarage) ...[
                        _Divider(theme: theme),
                        _StatItem(
                          theme: theme,
                          icon: Icons.garage_outlined,
                          value: '1',
                          label: 'Cochera',
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 24),
                  Divider(color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: 20),

                  // Descripción
                  Text('Descripción',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: 8),
                  Text(
                    property.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 24),
                  Divider(color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: 20),

                  // Características
                  Text('Características',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FeatureChip(
                          theme: theme,
                          icon: Icons.bed_outlined,
                          label: '${property.bedrooms} habitaciones'),
                      _FeatureChip(
                          theme: theme,
                          icon: Icons.bathtub_outlined,
                          label: '${property.bathrooms} baños'),
                      _FeatureChip(
                          theme: theme,
                          icon: Icons.square_foot,
                          label: '${property.area.toInt()} m²'),
                      if (property.hasGarage)
                        _FeatureChip(
                            theme: theme,
                            icon: Icons.garage_outlined,
                            label: 'Cochera'),
                      if (property.hasGarden)
                        _FeatureChip(
                            theme: theme,
                            icon: Icons.yard_outlined,
                            label: 'Jardín'),
                    ],
                  ),

                  // Espacio para el bottom bar
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom bar
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.of(context).padding.bottom + 12,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  side: BorderSide(color: theme.colorScheme.primary),
                ),
                child: Text(
                  'Agendar visita',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                child: const Text('Contactar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CircleButton extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final VoidCallback onTap;

  const CircleButton({
    super.key,
    required this.theme,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.1),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: theme.colorScheme.onSurface),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.theme,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: theme.colorScheme.primary),
        const SizedBox(height: 6),
        Text(value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            )),
        Text(label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            )),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  final ThemeData theme;
  const _Divider({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: theme.colorScheme.outlineVariant,
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final String label;

  const _FeatureChip({
    required this.theme,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              )),
        ],
      ),
    );
  }
}