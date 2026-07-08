import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';

class AgencyProfileView extends StatefulWidget {
  const AgencyProfileView({super.key});

  @override
  State<AgencyProfileView> createState() => _AgencyProfileViewState();
}

class _AgencyProfileViewState extends State<AgencyProfileView> {
  Map<String, dynamic>? _analytics;
  List<dynamic> _myProperties = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final userId = context.read<AuthViewModel>().user?.id ?? '';
      final propRes = await DioClient().dio.get('/properties/');
      final analyticsRes = await DioClient().dio.get('/analytics/');
      final aptRes = await DioClient().dio.get('/appointments/');

      final myProps = (propRes.data as List)
          .where((p) => p['owner_id'] == userId)
          .toList();

      setState(() {
        _myProperties = myProps;
        _analytics = {
          ...analyticsRes.data,
          'my_properties': myProps.length,
          'my_active': myProps
              .where((p) => p['status'] == 'available')
              .length,
          'my_appointments': (aptRes.data as List).length,
        };
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthViewModel>().user;

    return Scaffold(
      body: _loading
          ? Center(
          child: CircularProgressIndicator(
              color: theme.colorScheme.primary))
          : RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  bottom: 24,
                  left: 20,
                  right: 20,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primaryContainer,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            Icons.business,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.name ?? 'Inmobiliaria',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user?.email ?? '',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(
                                  color:
                                  Colors.white.withOpacity(0.8),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                  Colors.white.withOpacity(0.2),
                                  borderRadius:
                                  BorderRadius.circular(20),
                                  border: Border.all(
                                    color:
                                    Colors.white.withOpacity(0.4),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified,
                                        size: 12,
                                        color: Colors.white),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Inmobiliaria',
                                      style: theme
                                          .textTheme.labelSmall
                                          ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Stats rápidos
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Resumen',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _MiniStat(
                          theme: theme,
                          value:
                          '${_analytics?['my_properties'] ?? 0}',
                          label: 'Propiedades',
                          icon: Icons.home_work_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        _MiniStat(
                          theme: theme,
                          value:
                          '${_analytics?['my_active'] ?? 0}',
                          label: 'Activas',
                          icon: Icons.check_circle_outline,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        _MiniStat(
                          theme: theme,
                          value:
                          '${_analytics?['my_appointments'] ?? 0}',
                          label: 'Citas',
                          icon: Icons.calendar_today_outlined,
                          color: theme.colorScheme.tertiary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Mis propiedades
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Mis propiedades',
                            style: theme.textTheme.titleMedium),
                        Text(
                          '${_myProperties.length} total',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_myProperties.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: theme.colorScheme.outlineVariant),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.home_work_outlined,
                                  size: 40,
                                  color: theme
                                      .colorScheme.outlineVariant),
                              const SizedBox(height: 8),
                              Text('No tienes propiedades aún',
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(
                                    color: theme.colorScheme
                                        .onSurfaceVariant,
                                  )),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._myProperties.map((prop) => _PropertyRow(
                        theme: theme,
                        prop: prop,
                      )),

                    const SizedBox(height: 24),

                    // Analytics del mercado
                    Text('Estadísticas del mercado',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                        theme.colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: theme.colorScheme.outlineVariant),
                      ),
                      child: Column(
                        children: [
                          _AnalyticsRow(
                            theme: theme,
                            label: 'Total propiedades en plataforma',
                            value:
                            '${_analytics?['total_properties'] ?? 0}',
                            icon: Icons.home_work,
                          ),
                          Divider(
                              color: theme.colorScheme.outlineVariant,
                              height: 24),
                          _AnalyticsRow(
                            theme: theme,
                            label: 'Precio promedio',
                            value: _formatPrice(
                              (_analytics?['average_price'] ?? 0)
                                  .toDouble(),
                            ),
                            icon: Icons.attach_money,
                          ),
                          if ((_analytics?['by_operation_type']
                          as List? ??
                              [])
                              .isNotEmpty) ...[
                            Divider(
                                color:
                                theme.colorScheme.outlineVariant,
                                height: 24),
                            ...(_analytics!['by_operation_type']
                            as List)
                                .map(
                                  (item) => Padding(
                                padding:
                                const EdgeInsets.only(bottom: 8),
                                child: _AnalyticsRow(
                                  theme: theme,
                                  label: item['type'] == 'sale'
                                      ? 'En venta'
                                      : 'En renta',
                                  value: '${item['count']}',
                                  icon: item['type'] == 'sale'
                                      ? Icons.sell_outlined
                                      : Icons.key_outlined,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Sesión
                    Text('Sesión', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () => context.read<AuthViewModel>().logout(),
                        icon: Icon(Icons.logout, color: theme.colorScheme.error),
                        label: Text(
                          'Cerrar sesión empresarial',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: theme.colorScheme.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '\$${(price / 1000000).toStringAsFixed(1)}M';
    }
    if (price >= 1000) return '\$${(price / 1000).toStringAsFixed(0)}K';
    return '\$${price.toStringAsFixed(0)}';
  }
}

class _MiniStat extends StatelessWidget {
  final ThemeData theme;
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _MiniStat({
    required this.theme,
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PropertyRow extends StatelessWidget {
  final ThemeData theme;
  final Map<String, dynamic> prop;

  const _PropertyRow({required this.theme, required this.prop});

  @override
  Widget build(BuildContext context) {
    final status = prop['status'] ?? 'available';
    Color statusColor;
    String statusLabel;

    switch (status) {
      case 'reserved':
        statusColor = theme.colorScheme.tertiary;
        statusLabel = 'Reservada';
        break;
      case 'sold':
        statusColor = theme.colorScheme.outline;
        statusLabel = 'Vendida';
        break;
      case 'rented':
        statusColor = theme.colorScheme.outline;
        statusLabel = 'Rentada';
        break;
      default:
        statusColor = theme.colorScheme.secondary;
        statusLabel = 'Disponible';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.home_work_outlined,
                size: 22, color: theme.colorScheme.outline),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prop['title'] ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '\$${prop['price']} · ${prop['city']}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border:
              Border.all(color: statusColor.withOpacity(0.4)),
            ),
            child: Text(
              statusLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsRow extends StatelessWidget {
  final ThemeData theme;
  final String label;
  final String value;
  final IconData icon;

  const _AnalyticsRow({
    required this.theme,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: theme.textTheme.bodyMedium),
        ),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}