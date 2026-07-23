import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/dio_client.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  List<dynamic> _notifications = [];
  bool _loading = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await DioClient().dio.get('/notifications/');
      final countRes =
      await DioClient().dio.get('/notifications/unread-count');
      setState(() {
        _notifications = res.data;
        _unreadCount = countRes.data['count'] ?? 0;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      await DioClient().dio.put('/notifications/read-all');
      _load();
    } catch (_) {}
  }

  Future<void> _markRead(String id) async {
    try {
      await DioClient().dio.put('/notifications/$id/read');
      setState(() {
        final notif = _notifications.firstWhere((n) => n['id'] == id);
        notif['is_read'] = true;
        _unreadCount = (_unreadCount - 1).clamp(0, 999);
      });
    } catch (_) {}
  }

  Future<void> _deleteOne(String id) async {
    final removed = _notifications.firstWhere((n) => n['id'] == id);
    final wasUnread = removed['is_read'] == false;
    setState(() {
      _notifications.removeWhere((n) => n['id'] == id);
      if (wasUnread) _unreadCount = (_unreadCount - 1).clamp(0, 999);
    });
    try {
      await DioClient().dio.delete('/notifications/$id');
    } catch (_) {
      // Si falla en el servidor, recargamos para no dejar la UI desincronizada
      _load();
    }
  }

  Future<void> _clearAll() async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpiar notificaciones'),
        content: const Text('¿Deseas eliminar todas tus notificaciones?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await DioClient().dio.delete('/notifications/');
      setState(() {
        _notifications = [];
        _unreadCount = 0;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No se pudo limpiar, intenta de nuevo'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'appointment':
        return Icons.calendar_today_rounded;
      case 'property':
        return Icons.home_work_rounded;
      case 'favorite':
        return Icons.favorite_rounded;
      case 'message':
        return Icons.message_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getColor(String type, ThemeData theme) {
    switch (type) {
      case 'appointment':
        return theme.colorScheme.tertiary;
      case 'property':
        return theme.colorScheme.secondary;
      case 'favorite':
        return theme.colorScheme.error;
      case 'message':
        return theme.colorScheme.primary;
      default:
        return theme.colorScheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('Notificaciones', style: theme.textTheme.titleLarge),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_unreadCount',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onError,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'Marcar leídas',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          if (_notifications.isNotEmpty)
            IconButton(
              tooltip: 'Limpiar todo',
              icon: Icon(Icons.delete_sweep_outlined, color: theme.colorScheme.error),
              onPressed: _clearAll,
            ),
        ],
      ),
      body: _loading
          ? Center(
          child: CircularProgressIndicator(
              color: theme.colorScheme.primary))
          : _notifications.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none_outlined,
                size: 72,
                color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text(
              'Sin notificaciones',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aquí aparecerán tus alertas\nde citas y propiedades',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          itemCount: _notifications.length,
          separatorBuilder: (_, __) => Divider(
            color: theme.colorScheme.outlineVariant,
            height: 1,
          ),
          itemBuilder: (_, i) {
            final n = _notifications[i];
            final isRead = n['is_read'] ?? false;
            final type = n['type'] ?? 'general';
            final color = _getColor(type, theme);

            DateTime? createdAt;
            try {
              createdAt = DateTime.parse(n['created_at']);
            } catch (_) {}

            return Dismissible(
              key: ValueKey(n['id']),
              direction: DismissDirection.endToStart,
              background: Container(
                color: theme.colorScheme.error,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Icon(Icons.delete_outline, color: theme.colorScheme.onError),
              ),
              onDismissed: (_) => _deleteOne(n['id']),
              child: InkWell(
                onTap: () {
                  if (!isRead) _markRead(n['id']);
                },
                child: Container(
                  color: isRead
                      ? null
                      : theme.colorScheme.primaryContainer
                      .withOpacity(0.3),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ícono
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getIcon(type),
                          color: color,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Contenido
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    n['title'] ?? '',
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(
                                      fontWeight: isRead
                                          ? FontWeight.normal
                                          : FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (!isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color:
                                      theme.colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              n['body'] ?? '',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(
                                color: theme
                                    .colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                            if (createdAt != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                _timeAgo(createdAt),
                                style: theme.textTheme.labelSmall
                                    ?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Ahora mismo';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    if (diff.inDays < 7) return 'hace ${diff.inDays} días';
    return DateFormat('dd/MM/yyyy').format(date);
  }
}