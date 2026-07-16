import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import 'chat_view.dart';

class ConversationsView extends StatefulWidget {
  const ConversationsView({super.key});

  @override
  State<ConversationsView> createState() => _ConversationsViewState();
}

class _ConversationsViewState extends State<ConversationsView> {
  List<dynamic> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await DioClient().dio.get('/chat/conversations');
      setState(() {
        _conversations = res.data;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId =
        context.read<AuthViewModel>().user?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Mensajes', style: theme.textTheme.titleLarge),
      ),
      body: _loading
          ? Center(
          child: CircularProgressIndicator(
              color: theme.colorScheme.primary))
          : _conversations.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 72,
                color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text('Sin conversaciones',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
            const SizedBox(height: 8),
            Text(
              'Toca "Contactar" en una propiedad\npara iniciar una conversación',
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
          itemCount: _conversations.length,
          separatorBuilder: (_, __) => Divider(
            color: theme.colorScheme.outlineVariant,
            height: 1,
            indent: 80,
          ),
          itemBuilder: (_, i) {
            final conv = _conversations[i];
            final unread = conv['unread_count'] ?? 0;
            final isFromMe =
                conv['user_id'] == currentUserId;
            final otherLabel =
            isFromMe ? 'Vendedor' : 'Comprador';
            final propTitle = conv['property_title'];
            final propPhoto = conv['property_photo'];

            DateTime? lastMsgTime;
            try {
              lastMsgTime =
                  DateTime.parse(conv['last_message_at']);
            } catch (_) {}

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              leading: Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor:
                    theme.colorScheme.primaryContainer,
                    child: const Icon(
                      Icons.person,
                      size: 32,
                    ),
                  ),
                  if (propPhoto != null)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.colorScheme.surface, width: 2),
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: NetworkImage(propPhoto),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          otherLabel,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: unread > 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        if (propTitle != null)
                          Text(
                            propTitle,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (lastMsgTime != null)
                    Text(
                      _formatTime(lastMsgTime),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: unread > 0
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                        fontWeight: unread > 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                ],
              ),
              subtitle: Row(
                children: [
                  Expanded(
                    child: Text(
                      conv['last_message'] ??
                          'Inicia la conversación',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: unread > 0
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.outline,
                        fontWeight: unread > 0
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (unread > 0)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$unread',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatView(
                      conversationId: conv['id'],
                      otherUserLabel: otherLabel,
                      propertyTitle: propTitle,
                    ),
                  ),
                );
                _load();
              },
            );
          },
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('dd/MM').format(time);
  }
}