import 'package:flutter/material.dart';
import '../../../../core/network/dio_client.dart';

class ScheduleConfigView extends StatefulWidget {
  const ScheduleConfigView({super.key});

  @override
  State<ScheduleConfigView> createState() => _ScheduleConfigViewState();
}

class _ScheduleConfigViewState extends State<ScheduleConfigView> {
  bool _loading = true;
  bool _saving = false;

  Map<String, bool> _days = {
    'Lunes': true,
    'Martes': true,
    'Miércoles': true,
    'Jueves': true,
    'Viernes': true,
    'Sábado': false,
    'Domingo': false,
  };

  int _startHour = 9;
  int _endHour = 18;
  int _slotDuration = 60;

  final List<int> _hours = List.generate(24, (i) => i);
  final List<Map<String, dynamic>> _durations = [
    {'label': '30 minutos', 'value': 30},
    {'label': '1 hora', 'value': 60},
    {'label': '1.5 horas', 'value': 90},
    {'label': '2 horas', 'value': 120},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await DioClient().dio.get('/schedules/me');
      final data = res.data;
      setState(() {
        _days = {
          'Lunes': data['monday'] ?? true,
          'Martes': data['tuesday'] ?? true,
          'Miércoles': data['wednesday'] ?? true,
          'Jueves': data['thursday'] ?? true,
          'Viernes': data['friday'] ?? true,
          'Sábado': data['saturday'] ?? false,
          'Domingo': data['sunday'] ?? false,
        };
        _startHour = data['start_hour'] ?? 9;
        _endHour = data['end_hour'] ?? 18;
        _slotDuration = data['slot_duration'] ?? 60;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await DioClient().dio.put('/schedules/me', data: {
        'monday': _days['Lunes'],
        'tuesday': _days['Martes'],
        'wednesday': _days['Miércoles'],
        'thursday': _days['Jueves'],
        'friday': _days['Viernes'],
        'saturday': _days['Sábado'],
        'sunday': _days['Domingo'],
        'start_hour': _startHour,
        'end_hour': _endHour,
        'slot_duration': _slotDuration,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Horario guardado exitosamente'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
        Navigator.pop(context);
      }
    } catch (_) {
      setState(() => _saving = false);
    }
  }

  String _formatHour(int hour) {
    final period = hour < 12 ? 'AM' : 'PM';
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$h:00 $period';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Horario de atención',
            style: theme.textTheme.titleLarge),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _saving ? null : _save,
              child: Text(
                'Guardar',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: _saving
                      ? theme.colorScheme.outline
                      : theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? Center(
          child: CircularProgressIndicator(
              color: theme.colorScheme.primary))
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Configura tus días y horarios de atención. Los compradores solo podrán agendar citas en estos horarios.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Días
          _SectionLabel(theme: theme, label: 'Días de atención'),
          const SizedBox(height: 12),
          ..._days.entries.map((entry) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: entry.value
                  ? theme.colorScheme.primaryContainer
                  .withOpacity(0.5)
                  : theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: entry.value
                    ? theme.colorScheme.primary.withOpacity(0.5)
                    : theme.colorScheme.outlineVariant,
              ),
            ),
            child: SwitchListTile(
              title: Text(
                entry.key,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: entry.value
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
              value: entry.value,
              onChanged: (v) =>
                  setState(() => _days[entry.key] = v),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16),
              dense: true,
            ),
          )),

          const SizedBox(height: 24),

          // Horario
          _SectionLabel(theme: theme, label: 'Horario'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hora inicio',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        )),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      value: _startHour,
                      decoration: const InputDecoration(),
                      items: _hours
                          .where((h) => h < _endHour)
                          .map((h) => DropdownMenuItem(
                        value: h,
                        child: Text(_formatHour(h)),
                      ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _startHour = v!),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hora fin',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        )),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      value: _endHour,
                      decoration: const InputDecoration(),
                      items: _hours
                          .where((h) => h > _startHour)
                          .map((h) => DropdownMenuItem(
                        value: h,
                        child: Text(_formatHour(h)),
                      ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _endHour = v!),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Duración de cita
          Text('Duración por cita',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
          const SizedBox(height: 6),
          DropdownButtonFormField<int>(
            value: _slotDuration,
            decoration: const InputDecoration(),
            items: _durations
                .map((d) => DropdownMenuItem<int>(
              value: d['value'] as int,
              child: Text(d['label'] as String),
            ))
                .toList(),
            onChanged: (v) => setState(() => _slotDuration = v!),
          ),

          const SizedBox(height: 24),

          // Preview
          _SectionLabel(theme: theme, label: 'Vista previa de slots'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: theme.colorScheme.outlineVariant),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _generateSlots().map((slot) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  slot,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 32),

          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.onPrimary,
              ),
            )
                : const Text('Guardar horario'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  List<String> _generateSlots() {
    final slots = <String>[];
    int hour = _startHour;
    while (hour < _endHour) {
      final period = hour < 12 ? 'AM' : 'PM';
      final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      slots.add('$h:00 $period');
      hour += (_slotDuration ~/ 60);
      if (slots.length > 12) break;
    }
    return slots;
  }
}

class _SectionLabel extends StatelessWidget {
  final ThemeData theme;
  final String label;
  const _SectionLabel({required this.theme, required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.outline,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}