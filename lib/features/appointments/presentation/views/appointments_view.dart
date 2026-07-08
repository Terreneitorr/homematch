import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:homematch_ai/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/network/dio_client.dart';

class AppointmentsView extends StatefulWidget {
  const AppointmentsView({super.key});

  @override
  State<AppointmentsView> createState() => _AppointmentsViewState();
}

class _AppointmentsViewState extends State<AppointmentsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _upcoming = [];
  List<dynamic> _past = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await DioClient().dio.get('/appointments/');
      final all = res.data as List;
      final now = DateTime.now();
      setState(() {
        _upcoming = all.where((a) {
          try {
            final date = DateTime.parse(a['scheduled_at']);
            return date.isAfter(now) && a['status'] != 'cancelada';
          } catch (_) {
            return true;
          }
        }).toList();
        _past = all.where((a) {
          try {
            final date = DateTime.parse(a['scheduled_at']);
            return date.isBefore(now) || a['status'] == 'cancelada';
          } catch (_) {
            return false;
          }
        }).toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    try {
      await DioClient().dio.put('/appointments/$id/status', queryParameters: {
        'status': status,
      });
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'confirmada' ? 'Cita confirmada' : 'Cita rechazada'),
            backgroundColor: status == 'confirmada' ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al actualizar estado')),
        );
      }
    }
  }

  Future<void> _cancel(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar cita'),
        content: const Text('¿Seguro que deseas cancelar esta cita?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await DioClient().dio.delete('/appointments/$id');
        _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Cita cancelada'),
              backgroundColor: Theme.of(context).colorScheme.secondary,
            ),
          );
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Mis citas', style: theme.textTheme.titleLarge),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.outline,
          indicatorColor: theme.colorScheme.primary,
          tabs: [
            Tab(text: 'Próximas (${_upcoming.length})'),
            Tab(text: 'Pasadas (${_past.length})'),
          ],
        ),
      ),
      body: _loading
          ? Center(
          child: CircularProgressIndicator(
              color: theme.colorScheme.primary))
          : RefreshIndicator(
        onRefresh: _load,
        child: TabBarView(
          controller: _tabController,
          children: [
            _AppointmentList(
              theme: theme,
              appointments: _upcoming,
              onCancel: _cancel,
              onStatusUpdate: _updateStatus,
              emptyMessage: 'No tienes citas próximas',
              emptyIcon: Icons.calendar_today_outlined,
            ),
            _AppointmentList(
              theme: theme,
              appointments: _past,
              onCancel: null,
              onStatusUpdate: null,
              emptyMessage: 'No hay citas pasadas',
              emptyIcon: Icons.history,
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentList extends StatelessWidget {
  final ThemeData theme;
  final List<dynamic> appointments;
  final Function(String)? onCancel;
  final Function(String, String)? onStatusUpdate;
  final String emptyMessage;
  final IconData emptyIcon;

  const _AppointmentList({
    required this.theme,
    required this.appointments,
    required this.onCancel,
    this.onStatusUpdate,
    required this.emptyMessage,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 64, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text(emptyMessage,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _AppointmentCard(
        theme: theme,
        apt: appointments[i],
        onCancel: onCancel,
        onStatusUpdate: onStatusUpdate,
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final ThemeData theme;
  final Map<String, dynamic> apt;
  final Function(String)? onCancel;
  final Function(String, String)? onStatusUpdate;

  const _AppointmentCard({
    required this.theme,
    required this.apt,
    required this.onCancel,
    this.onStatusUpdate,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmada':
        return theme.colorScheme.secondary;
      case 'cancelada':
        return theme.colorScheme.outline;
      case 'reagendada':
        return theme.colorScheme.primary;
      default:
        return theme.colorScheme.tertiary;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'confirmada':
        return 'Confirmada';
      case 'cancelada':
        return 'Cancelada';
      case 'reagendada':
        return 'Reagendada';
      default:
        return 'Pendiente';
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'virtual':
        return 'Visita virtual';
      case 'telefonica':
        return 'Llamada telefónica';
      default:
        return 'Visita presencial';
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'virtual':
        return Icons.videocam_outlined;
      case 'telefonica':
        return Icons.phone_outlined;
      default:
        return Icons.location_on_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = apt['status'] ?? 'pendiente';
    final statusColor = _statusColor(status);
    final type = apt['appointment_type'] ?? 'presencial';
    final userId = context.read<AuthViewModel>().user?.id;
    final isOwner = apt['seller_id'] == userId;

    DateTime? scheduledAt;
    try {
      scheduledAt = DateTime.parse(apt['scheduled_at']);
    } catch (_) {}

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: status == 'cancelada'
              ? theme.colorScheme.outlineVariant
              : statusColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          // Header con estado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(_typeIcon(type), size: 16, color: statusColor),
                const SizedBox(width: 8),
                Text(
                  _typeLabel(type),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: statusColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenido
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.home_work_outlined,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'ID Propiedad: ${apt['property_id']?.toString().substring(0, 8) ?? 'N/A'}...',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                if (scheduledAt != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.calendar_today,
                            size: 18,
                            color: theme.colorScheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE, dd MMMM yyyy', 'es')
                                .format(scheduledAt),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            DateFormat('HH:mm').format(scheduledAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
                if (apt['notes'] != null &&
                    apt['notes'].toString().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.notes,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            apt['notes'],
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (status == 'pendiente') ...[
                  const SizedBox(height: 12),
                  if (isOwner && onStatusUpdate != null)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => onStatusUpdate!(apt['id'], 'cancelada'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.colorScheme.error,
                              side: BorderSide(color: theme.colorScheme.error.withOpacity(0.5)),
                            ),
                            child: const Text('Rechazar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => onStatusUpdate!(apt['id'], 'confirmada'),
                            style: FilledButton.styleFrom(
                              backgroundColor: theme.colorScheme.secondary,
                            ),
                            child: const Text('Aceptar'),
                          ),
                        ),
                      ],
                    )
                  else if (!isOwner && onCancel != null)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => onCancel!(apt['id']),
                        icon: Icon(Icons.cancel_outlined,
                            size: 16,
                            color: theme.colorScheme.error),
                        label: Text('Cancelar cita',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.error,
                            )),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          side: BorderSide(
                              color:
                              theme.colorScheme.error.withOpacity(0.5)),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
