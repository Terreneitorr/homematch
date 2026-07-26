import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';

class ChatView extends StatefulWidget {
  final String conversationId;
  final String otherUserLabel;
  final String? propertyTitle;

  const ChatView({
    super.key,
    required this.conversationId,
    required this.otherUserLabel,
    this.propertyTitle,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<dynamic> _messages = [];
  bool _loading = true;
  bool _sending = false;
  Timer? _pollTimer;
  String _currentUserId = '';

  // Mensaje al que se está respondiendo (null = ninguno)
  Map<String, dynamic>? _replyingTo;

  @override
  void initState() {
    super.initState();
    _currentUserId =
        context.read<AuthViewModel>().user?.id ?? '';
    _load();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 3),
          (_) => _load(silent: true),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final res = await DioClient().dio.get(
        '/chat/conversations/${widget.conversationId}/messages',
      );
      setState(() {
        _messages = res.data;
        _loading = false;
      });
      _scrollToBottom();
    } catch (_) {
      if (!silent) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _msgCtrl.clear();
    final replyId = _replyingTo?['id'];
    setState(() => _replyingTo = null);

    try {
      await DioClient().dio.post(
        '/chat/conversations/${widget.conversationId}/messages',
        data: {
          'content': text,
          if (replyId != null) 'reply_to_id': replyId,
        },
      );
      await _load(silent: true);
    } catch (e) {
      if (mounted) {
        final msg = (e is Exception && e.toString().contains('inapropiado'))
            ? 'Tu mensaje contiene lenguaje inapropiado'
            : 'No se pudo enviar el mensaje';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
    if (mounted) setState(() => _sending = false);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _copyMessage(String content) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mensaje copiado')),
    );
  }

  void _startReply(Map<String, dynamic> msg) {
    setState(() => _replyingTo = msg);
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      await DioClient().dio.delete(
        '/chat/conversations/${widget.conversationId}/messages/$messageId',
      );
      await _load(silent: true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No se pudo eliminar el mensaje'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showMessageOptions(Map<String, dynamic> msg, bool isMe) {
    final theme = Theme.of(context);
    final deleted = msg['deleted'] == true;
    if (deleted) return; // no hay nada que hacer con un mensaje ya borrado

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.copy_outlined, color: theme.colorScheme.primary),
              title: const Text('Copiar'),
              onTap: () {
                Navigator.pop(context);
                _copyMessage(msg['content'] ?? '');
              },
            ),
            ListTile(
              leading: Icon(Icons.reply_outlined, color: theme.colorScheme.primary),
              title: const Text('Responder'),
              onTap: () {
                Navigator.pop(context);
                _startReply(msg);
              },
            ),
            if (isMe)
              ListTile(
                leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                title: Text('Eliminar para todos',
                    style: TextStyle(color: theme.colorScheme.error)),
                onTap: () async {
                  Navigator.pop(context);
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Eliminar mensaje'),
                      content: const Text(
                          '¿Eliminar este mensaje para todos? Esta acción no se puede deshacer.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                              backgroundColor: theme.colorScheme.error),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Eliminar'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    _deleteMessage(msg['id']);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteConversation() async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar conversación'),
        content: const Text(
            '¿Eliminar toda la conversación? Se borrará para ambos y no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await DioClient().dio.delete('/chat/conversations/${widget.conversationId}');
        if (mounted) Navigator.pop(context);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No se pudo eliminar la conversación'),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUserLabel,
                style: theme.textTheme.titleMedium),
            if (widget.propertyTitle != null)
              Text(
                'Propiedad: ${widget.propertyTitle}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            else
              Text('En línea',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  )),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _load(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete_conversation') _deleteConversation();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'delete_conversation',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: theme.colorScheme.error, size: 20),
                    const SizedBox(width: 10),
                    Text('Eliminar conversación',
                        style: TextStyle(color: theme.colorScheme.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? Center(
                child: CircularProgressIndicator(
                    color: theme.colorScheme.primary))
                : _messages.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 48,
                      color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: 12),
                  Text(
                    'Inicia la conversación',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final msg = _messages[i];
                final isMe =
                    msg['sender_id'] == _currentUserId;
                return GestureDetector(
                  onLongPress: () => _showMessageOptions(msg, isMe),
                  child: _MessageBubble(
                    theme: theme,
                    content: msg['content'] ?? '',
                    isMe: isMe,
                    createdAt: msg['created_at'],
                    deleted: msg['deleted'] == true,
                    replyToContent: msg['reply_to_content'],
                    replyToIsMe: msg['reply_to_sender_id'] == _currentUserId,
                  ),
                );
              },
            ),
          ),

          // Vista previa de "respondiendo a..."
          if (_replyingTo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              child: Row(
                children: [
                  Container(width: 3, height: 32, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Respondiendo a',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            )),
                        Text(
                          _replyingTo!['content'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _replyingTo = null),
                  ),
                ],
              ),
            ),

          // Input
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              border: Border(
                top: BorderSide(
                    color: theme.colorScheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    maxLines: 4,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor:
                      theme.colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: _sending
                        ? Padding(
                      padding: const EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                        : Icon(Icons.send_rounded,
                        color: theme.colorScheme.onPrimary,
                        size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ThemeData theme;
  final String content;
  final bool isMe;
  final String? createdAt;
  final bool deleted;
  final String? replyToContent;
  final bool replyToIsMe;

  const _MessageBubble({
    required this.theme,
    required this.content,
    required this.isMe,
    this.createdAt,
    this.deleted = false,
    this.replyToContent,
    this.replyToIsMe = false,
  });

  @override
  Widget build(BuildContext context) {
    DateTime? time;
    try {
      if (createdAt != null) time = DateTime.parse(createdAt!);
    } catch (_) {}

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment:
        isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMe
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (replyToContent != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: (isMe ? Colors.white : theme.colorScheme.primary)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border(
                        left: BorderSide(
                          color: isMe ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Text(
                      replyToContent!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isMe
                            ? theme.colorScheme.onPrimary.withValues(alpha: 0.85)
                            : theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
                Text(
                  deleted ? 'Mensaje eliminado' : content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isMe
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                    fontStyle: deleted ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
          if (time != null)
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
              child: Text(
                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }
}