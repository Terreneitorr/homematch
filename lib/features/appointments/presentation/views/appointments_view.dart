import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/dio_client.dart';

class AppointmentsView extends StatefulWidget {
  const AppointmentsView({super.key});

  @override
  State<AppointmentsView> createState() => _AppointmentsViewState();
}

class _AppointmentsViewState extends State<AppointmentsView> {
  List<dynamic> _appointments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await DioClient().dio.get('/appointments/');
      setState(() {
        _appointments = res.data;
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
        title: Text('Mis citas', style: theme.textTheme.titleLarge),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : _appointments.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 64, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text('No tienes citas programadas',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _appointments.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final apt = _appointments[i];
            return _AppointmentCard(
              theme: theme,
              apt: apt,
              onCancel: () => _cancel(apt['id']),
            );
          },
        ),
      ),
    );
  }

  Future<void> _cancel(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar cita'),
        content: const Text('¿Estás seguro de que deseas cancelar esta cita?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sí, cancelar')),
        ],
      ),
    );
    if (confirmed == true) {
      await DioClient().dio.delete('/appointments/$id');
      _load();
    }
  }
}

class _AppointmentCard extends StatelessWidget {
  final ThemeData theme;
  final Map<String, dynamic> apt;
  final VoidCallback onCancel;

  const _AppointmentCard({
    required this.theme,
    required this.apt,
    required this.onCancel,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmada': return theme.colorScheme.secondary;
      case 'cancelada': return theme.colorScheme.outline;
      case 'reagendada': return theme.colorScheme.primary;
      default: return theme.colorScheme.tertiary;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'confirmada': return 'Confirmada';
      case 'cancelada': return 'Cancelada';
      case 'reagendada': return 'Reagendada';
      default: return 'Pendiente';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = apt['status'] ?? 'pendiente';
    final statusColor = _statusColor(status);
    DateTime? scheduledAt;
    try {
      scheduledAt = DateTime.parse(apt['scheduled_at']);
    } catch (_) {}

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.home_work_outlined,
                  size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Propiedad ${apt['property_id']?.substring(0, 8) ?? ''}...',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.4)),
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
          const SizedBox(height: 12),
          if (scheduledAt != null) ...[
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  DateFormat('dd/MM/yyyy').format(scheduledAt),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time,
                    size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  DateFormat('HH:mm').format(scheduledAt),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          Row(
            children: [
              Icon(
                apt['appointment_type'] == 'virtual'
                    ? Icons.videocam_outlined
                    : Icons.location_on_outlined,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                apt['appointment_type'] == 'virtual'
                    ? 'Visita virtual'
                    : apt['appointment_type'] == 'telefonica'
                    ? 'Telefónica'
                    : 'Visita presencial',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (status == 'pendiente') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  side: BorderSide(color: theme.colorScheme.error),
                ),
                child: Text('Cancelar cita',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.error,
                    )),
              ),
            ),
          ],
        ],
      ),
    );
  }
}