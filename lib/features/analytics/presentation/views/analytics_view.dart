import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/dio_client.dart';

class AnalyticsView extends StatefulWidget {
  const AnalyticsView({super.key});

  @override
  State<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<AnalyticsView> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await DioClient().dio.get('/analytics/');
      setState(() {
        _data = response.data;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Estadísticas', style: theme.textTheme.titleLarge),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : _data == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 64, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text('Sin datos disponibles',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () { setState(() => _loading = true); _load(); },
              style: FilledButton.styleFrom(minimumSize: const Size(160, 44)),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: () async { setState(() => _loading = true); await _load(); },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Stats principales
            Row(
              children: [
                _StatCard(
                  theme: theme,
                  label: 'Total propiedades',
                  value: '${_data!['total_properties'] ?? 0}',
                  icon: Icons.home_work_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  theme: theme,
                  label: 'Precio promedio',
                  value: _formatPrice(_data!['average_price']?.toDouble() ?? 0),
                  icon: Icons.attach_money,
                  color: theme.colorScheme.secondary,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Por ciudad
            Text('Por ciudad',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 12),
            ...(_data!['by_city'] as List? ?? []).map((item) =>
                _BarItem(
                  theme: theme,
                  label: item['city'] ?? '',
                  value: item['count'] ?? 0,
                  total: _data!['total_properties'] ?? 1,
                ),
            ),

            const SizedBox(height: 24),

            // Por tipo
            Text('Por tipo de operación',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 12),
            ...(_data!['by_operation_type'] as List? ?? []).map((item) =>
                _BarItem(
                  theme: theme,
                  label: item['type'] == 'sale' ? 'Venta' : 'Renta',
                  value: item['count'] ?? 0,
                  total: _data!['total_properties'] ?? 1,
                  color: item['type'] == 'sale'
                      ? theme.colorScheme.primary
                      : theme.colorScheme.tertiary,
                ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000000) return '\$${(price / 1000000).toStringAsFixed(1)}M';
    if (price >= 1000) return '\$${(price / 1000).toStringAsFixed(0)}K';
    return '\$${price.toStringAsFixed(0)}';
  }
}

class _StatCard extends StatelessWidget {
  final ThemeData theme;
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.theme,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(value,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                )),
            const SizedBox(height: 4),
            Text(label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
          ],
        ),
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  final ThemeData theme;
  final String label;
  final int value;
  final int total;
  final Color? color;

  const _BarItem({
    required this.theme,
    required this.label,
    required this.value,
    required this.total,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? value / total : 0.0;
    final barColor = color ?? theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: theme.textTheme.bodyMedium),
              Text('$value',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: barColor,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct.toDouble(),
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }
}