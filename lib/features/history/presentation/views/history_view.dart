import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/dio_client.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  List<dynamic> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await DioClient().dio.get('/history/');
      setState(() {
        _history = res.data;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpiar historial'),
        content: const Text('¿Deseas eliminar todo el historial de búsquedas?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() {
        _history = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Historial de búsquedas', style: theme.textTheme.titleLarge),
        actions: [
          if (_history.isNotEmpty)
            TextButton(
              onPressed: _clear,
              child: Text(
                'Limpiar',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : _history.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history,
                size: 64, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text('Sin historial de búsquedas',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
            const SizedBox(height: 8),
            Text('Tus búsquedas aparecerán aquí',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                )),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _history.length,
          separatorBuilder: (_, __) =>
              Divider(color: theme.colorScheme.outlineVariant),
          itemBuilder: (_, i) {
            final item = _history[i];
            DateTime? date;
            try {
              date = DateTime.parse(item['searched_at']);
            } catch (_) {}
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.search,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              title: Text(
                item['query'] ?? '',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: date != null
                  ? Text(
                DateFormat('dd/MM/yyyy HH:mm').format(date),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              )
                  : null,
              trailing: Icon(
                Icons.north_west,
                size: 16,
                color: theme.colorScheme.outline,
              ),
            );
          },
        ),
      ),
    );
  }
}