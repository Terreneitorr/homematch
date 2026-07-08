import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/property_entity.dart';

class CompareView extends StatelessWidget {
  final List<PropertyEntity> properties;

  const CompareView({super.key, required this.properties});

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '\$${(price / 1000000).toStringAsFixed(2)}M';
    }
    if (price >= 1000) return '\$${(price / 1000).toStringAsFixed(0)}K';
    return '\$${price.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p1 = properties[0];
    final p2 = properties[1];

    return Scaffold(
      appBar: AppBar(
        title: Text('Comparar propiedades',
            style: theme.textTheme.titleLarge),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Headers
            Row(
              children: [
                const SizedBox(width: 120),
                Expanded(
                  child: _PropertyHeader(theme: theme, property: p1),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PropertyHeader(theme: theme, property: p2),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Comparación
            _CompareRow(
              theme: theme,
              label: 'Precio',
              value1: _formatPrice(p1.price),
              value2: _formatPrice(p2.price),
              isBetter1: p1.price <= p2.price,
            ),
            _CompareRow(
              theme: theme,
              label: 'Habitaciones',
              value1: '${p1.bedrooms}',
              value2: '${p2.bedrooms}',
              isBetter1: p1.bedrooms >= p2.bedrooms,
            ),
            _CompareRow(
              theme: theme,
              label: 'Baños',
              value1: '${p1.bathrooms}',
              value2: '${p2.bathrooms}',
              isBetter1: p1.bathrooms >= p2.bathrooms,
            ),
            _CompareRow(
              theme: theme,
              label: 'Superficie',
              value1: '${p1.area.toInt()} m²',
              value2: '${p2.area.toInt()} m²',
              isBetter1: p1.area >= p2.area,
            ),
            _CompareRow(
              theme: theme,
              label: 'Cochera',
              value1: p1.hasGarage ? 'Sí' : 'No',
              value2: p2.hasGarage ? 'Sí' : 'No',
              isBetter1: p1.hasGarage,
            ),
            _CompareRow(
              theme: theme,
              label: 'Jardín',
              value1: p1.hasGarden ? 'Sí' : 'No',
              value2: p2.hasGarden ? 'Sí' : 'No',
              isBetter1: p1.hasGarden,
            ),
            _CompareRow(
              theme: theme,
              label: 'Operación',
              value1: p1.operationType == OperationType.sale
                  ? 'Venta'
                  : 'Renta',
              value2: p2.operationType == OperationType.sale
                  ? 'Venta'
                  : 'Renta',
              isBetter1: null,
            ),
            _CompareRow(
              theme: theme,
              label: 'Ciudad',
              value1: p1.city,
              value2: p2.city,
              isBetter1: null,
            ),
            _CompareRow(
              theme: theme,
              label: 'Zona',
              value1: p1.zone,
              value2: p2.zone,
              isBetter1: null,
            ),

            const SizedBox(height: 24),

            // Precio por m2
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Precio por m²',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              _formatPrice(p1.price / p1.area),
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color:
                                theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            Text('/m²',
                                style: theme.textTheme.labelSmall
                                    ?.copyWith(
                                  color: theme.colorScheme
                                      .onPrimaryContainer
                                      .withOpacity(0.7),
                                )),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: theme.colorScheme.onPrimaryContainer
                            .withOpacity(0.2),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              _formatPrice(p2.price / p2.area),
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color:
                                theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            Text('/m²',
                                style: theme.textTheme.labelSmall
                                    ?.copyWith(
                                  color: theme.colorScheme
                                      .onPrimaryContainer
                                      .withOpacity(0.7),
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PropertyHeader extends StatelessWidget {
  final ThemeData theme;
  final PropertyEntity property;

  const _PropertyHeader(
      {required this.theme, required this.property});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.home_work_rounded,
                color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 8),
          Text(
            property.title,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _CompareRow extends StatelessWidget {
  final ThemeData theme;
  final String label;
  final String value1;
  final String value2;
  final bool? isBetter1;

  const _CompareRow({
    required this.theme,
    required this.label,
    required this.value1,
    required this.value2,
    required this.isBetter1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: _ValueCell(
              theme: theme,
              value: value1,
              isBetter: isBetter1,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ValueCell(
              theme: theme,
              value: value2,
              isBetter: isBetter1 == null ? null : !isBetter1!,
            ),
          ),
        ],
      ),
    );
  }
}

class _ValueCell extends StatelessWidget {
  final ThemeData theme;
  final String value;
  final bool? isBetter;

  const _ValueCell(
      {required this.theme, required this.value, required this.isBetter});

  @override
  Widget build(BuildContext context) {
    Color? bg;
    Color? textColor;
    if (isBetter == true) {
      bg = theme.colorScheme.secondaryContainer;
      textColor = theme.colorScheme.onSecondaryContainer;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: textColor ?? theme.colorScheme.onSurface,
          fontWeight:
          isBetter == true ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}