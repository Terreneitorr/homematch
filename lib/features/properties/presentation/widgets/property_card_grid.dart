import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:homematch_ai/core/network/upload_service.dart';
import 'package:homematch_ai/features/properties/domain/entities/property_entity.dart';
import 'package:homematch_ai/features/properties/presentation/views/property_detail_view.dart';

class PropertyCardGrid extends StatelessWidget {
  final PropertyEntity property;
  final String? segmento;
  final VoidCallback onDelete;
  final bool isFavorite;
  final VoidCallback? onFavorite;

  const PropertyCardGrid({
    super.key,
    required this.property,
    required this.onDelete,
    this.segmento,
    this.isFavorite = false,
    this.onFavorite,
  });

  String _formatPrice(double price) {
    if (price >= 1000000) return '\$${(price / 1000000).toStringAsFixed(1)}M';
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

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PropertyDetailView(
              property: property,
              segmento: segmento,
            ),
          ),
        );
      },
      onLongPress: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Propiedad seleccionada para comparar'),
            action: SnackBarAction(
              label: 'Comparar',
              onPressed: () {
                // Navegar al comparador si hay 2 seleccionadas
              },
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: property.photos.isNotEmpty
                      ? CachedNetworkImage(
                    imageUrl: UploadService.getFullUrl(property.photos.first),
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 120,
                      color: theme.colorScheme.surfaceContainerHigh,
                      child: Icon(
                        Icons.home_work_rounded,
                        size: 40,
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 120,
                      color: theme.colorScheme.surfaceContainerHigh,
                      child: Icon(
                        Icons.home_work_rounded,
                        size: 40,
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                  )
                      : Container(
                    height: 120,
                    width: double.infinity,
                    color: theme.colorScheme.surfaceContainerHigh,
                    child: Icon(
                      Icons.home_work_rounded,
                      size: 40,
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                ),
                // Badge
                Positioned(
                  top: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isRent
                          ? theme.colorScheme.tertiaryContainer
                          : theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isRent ? 'RENTA' : 'VENTA',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isRent
                            ? theme.colorScheme.onTertiaryContainer
                            : theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
                // Favorito
                Positioned(
                  top: 4, right: 4,
                  child: GestureDetector(
                    onTap: onFavorite,
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLowest.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 14,
                        color: isFavorite
                            ? theme.colorScheme.error
                            : theme.colorScheme.outline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Contenido
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    price,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    property.title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 10, color: theme.colorScheme.outline),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          '${property.zone}, ${property.city}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline, fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _stat(theme, Icons.bed_outlined, '${property.bedrooms}'),
                      const SizedBox(width: 8),
                      _stat(theme, Icons.bathtub_outlined, '${property.bathrooms}'),
                      const SizedBox(width: 8),
                      _stat(theme, Icons.square_foot, '${property.area.toInt()}m²'),
                    ],
                  ),
                  if (segmento != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome,
                              size: 9,
                              color: theme.colorScheme.onSecondaryContainer),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              segmento!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSecondaryContainer,
                                fontSize: 9,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(ThemeData theme, IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 2),
        Text(value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant, fontSize: 10,
            )),
      ],
    );
  }
}
