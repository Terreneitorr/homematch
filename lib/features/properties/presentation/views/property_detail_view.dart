import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:homematch_ai/core/network/dio_client.dart';
import 'package:homematch_ai/core/network/upload_service.dart' as upload;
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:homematch_ai/features/properties/domain/entities/property_entity.dart';
import 'package:homematch_ai/features/chat/presentation/views/chat_view.dart';

class PropertyDetailView extends StatefulWidget {
  final PropertyEntity property;
  final String? segmento;

  const PropertyDetailView({
    super.key,
    required this.property,
    this.segmento,
  });

  @override
  State<PropertyDetailView> createState() => _PropertyDetailViewState();
}

class _PropertyDetailViewState extends State<PropertyDetailView> {
  int _currentPage = 0;

  String _formatPrice(double price) {
    if (price >= 1000000) return '\$${(price / 1000000).toStringAsFixed(2)}M';
    if (price >= 1000) return '\$${(price / 1000).toStringAsFixed(0)}K';
    return '\$${price.toStringAsFixed(0)}';
  }

  void _showScheduleSheet(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ScheduleSheet(
        theme: theme,
        propertyId: widget.property.id,
        sellerId: widget.property.ownerId,
      ),
    );
  }

  Future<void> _startChat(BuildContext context) async {
    try {
      final res = await DioClient().dio.post(
        '/chat/conversations/${widget.property.ownerId}',
        queryParameters: {'property_id': widget.property.id},
      );
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatView(
              conversationId: res.data['id'],
              otherUserLabel: 'Vendedor',
              propertyTitle: widget.property.title,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al iniciar conversación'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRent = widget.property.operationType == OperationType.rent;
    final price = isRent
        ? '${_formatPrice(widget.property.price)}/mes'
        : _formatPrice(widget.property.price);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar con imagen
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: theme.colorScheme.surface,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleButton(
                theme: theme,
                icon: Icons.arrow_back,
                onTap: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: CircleButton(
                  theme: theme,
                  icon: Icons.share_outlined,
                  onTap: () {},
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.property.photos.isNotEmpty)
                    PageView.builder(
                      itemCount: widget.property.photos.length,
                      onPageChanged: (index) =>
                          setState(() => _currentPage = index),
                      itemBuilder: (context, index) {
                        return CachedNetworkImage(
                          imageUrl: upload.UploadService.getFullUrl(widget.property.photos[index]),
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: theme.colorScheme.surfaceContainerHigh,
                            child: Icon(Icons.home_work_rounded,
                                size: 80,
                                color: theme.colorScheme.outlineVariant),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: theme.colorScheme.surfaceContainerHigh,
                            child: Icon(Icons.home_work_rounded,
                                size: 80,
                                color: theme.colorScheme.outlineVariant),
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      color: theme.colorScheme.surfaceContainerHigh,
                      child: Icon(Icons.home_work_rounded,
                          size: 80, color: theme.colorScheme.outlineVariant),
                    ),
                  // Indicador de fotos
                  if (widget.property.photos.length > 1)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_currentPage + 1} / ${widget.property.photos.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  // Badge
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isRent
                            ? theme.colorScheme.tertiaryContainer
                            : theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isRent ? 'RENTA' : 'VENTA',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: isRent
                              ? theme.colorScheme.onTertiaryContainer
                              : theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Contenido
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Precio y título
                  Text(
                    price,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.property.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 16, color: theme.colorScheme.outline),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.property.zone}, ${widget.property.city}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),

                  // Tag IA
                  if (widget.segmento != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome,
                              size: 14,
                              color: theme.colorScheme.onSecondaryContainer),
                          const SizedBox(width: 6),
                          Text(
                            'IA: ${widget.segmento}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  Divider(color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: 20),

                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        theme: theme,
                        icon: Icons.bed_outlined,
                        value: '${widget.property.bedrooms}',
                        label: 'Habitaciones',
                      ),
                      _Divider(theme: theme),
                      _StatItem(
                        theme: theme,
                        icon: Icons.bathtub_outlined,
                        value: '${widget.property.bathrooms}',
                        label: 'Baños',
                      ),
                      _Divider(theme: theme),
                      _StatItem(
                        theme: theme,
                        icon: Icons.square_foot,
                        value: '${widget.property.area.toInt()}',
                        label: 'm²',
                      ),
                      if (widget.property.hasGarage) ...[
                        _Divider(theme: theme),
                        _StatItem(
                          theme: theme,
                          icon: Icons.garage_outlined,
                          value: '1',
                          label: 'Cochera',
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 24),
                  Divider(color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: 20),

                  // Descripción
                  Text('Descripción',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: 8),
                  Text(
                    widget.property.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 24),
                  Divider(color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: 20),

                  // Características
                  Text('Características',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FeatureChip(
                          theme: theme,
                          icon: Icons.bed_outlined,
                          label: '${widget.property.bedrooms} habitaciones'),
                      _FeatureChip(
                          theme: theme,
                          icon: Icons.bathtub_outlined,
                          label: '${widget.property.bathrooms} baños'),
                      _FeatureChip(
                          theme: theme,
                          icon: Icons.square_foot,
                          label: '${widget.property.area.toInt()} m²'),
                      if (widget.property.hasGarage)
                        _FeatureChip(
                            theme: theme,
                            icon: Icons.garage_outlined,
                            label: 'Cochera'),
                      if (widget.property.hasGarden)
                        _FeatureChip(
                            theme: theme,
                            icon: Icons.yard_outlined,
                            label: 'Jardín'),
                    ],
                  ),

                  // Espacio para el bottom bar
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom bar
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.of(context).padding.bottom + 12,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showScheduleSheet(context, theme),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  side: BorderSide(color: theme.colorScheme.primary),
                ),
                child: Text(
                  'Agendar visita',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => _startChat(context),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                child: const Text('Contactar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CircleButton extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final VoidCallback onTap;

  const CircleButton({
    super.key,
    required this.theme,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: theme.colorScheme.onSurface),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.theme,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: theme.colorScheme.primary),
        const SizedBox(height: 6),
        Text(value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            )),
        Text(label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            )),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  final ThemeData theme;
  const _Divider({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: theme.colorScheme.outlineVariant,
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final String label;

  const _FeatureChip({
    required this.theme,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              )),
        ],
      ),
    );
  }
}

class _ScheduleSheet extends StatefulWidget {
  final ThemeData theme;
  final String propertyId;
  final String sellerId;
  const _ScheduleSheet({
    required this.theme,
    required this.propertyId,
    required this.sellerId,
  });

  @override
  State<_ScheduleSheet> createState() => _ScheduleSheetState();
}

class _ScheduleSheetState extends State<_ScheduleSheet> {
  DateTime? _selectedDate;
  String? _selectedSlot;
  String? _selectedSlotDatetime;
  String _type = 'presencial';
  bool _loading = false;
  List<dynamic> _slots = [];
  bool _loadingSlots = false;
  String? _slotsMessage;

  final List<DateTime> _availableDates = List.generate(
    14,
    (i) => DateTime.now().add(Duration(days: i + 1)),
  );

  Future<void> _loadSlots(DateTime date) async {
    setState(() { _loadingSlots = true; _slots = []; _selectedSlot = null; });
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final res = await DioClient().dio.get(
        '/schedules/${widget.sellerId}/slots',
        queryParameters: {'date_str': dateStr},
      );
      setState(() {
        _slots = res.data['slots'] ?? [];
        _slotsMessage = res.data['message'];
        _loadingSlots = false;
      });
    } catch (_) {
      setState(() { _loadingSlots = false; _slotsMessage = 'Error al cargar horarios'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20, right: 20, top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Agendar visita', style: theme.textTheme.titleLarge),
            const SizedBox(height: 20),

            // Tipo
            Text('Tipo de visita',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
            const SizedBox(height: 8),
            Row(
              children: ['presencial', 'virtual', 'telefonica'].map((t) {
                final sel = _type == t;
                final label = t == 'presencial'
                    ? 'Presencial'
                    : t == 'virtual'
                        ? 'Virtual'
                        : 'Telefónica';
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        right: t != 'telefonica' ? 6 : 0),
                    child: GestureDetector(
                      onTap: () => setState(() => _type = t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: sel
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: sel
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: Text(label,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: sel
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                          )),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Selector de fecha
            Text('Selecciona una fecha',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
            const SizedBox(height: 8),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _availableDates.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final date = _availableDates[i];
                  final selected = _selectedDate?.day == date.day &&
                      _selectedDate?.month == date.month;
                  final days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedDate = date);
                      _loadSlots(date);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 52,
                      decoration: BoxDecoration(
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            days[date.weekday - 1],
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: selected
                                  ? theme.colorScheme.onPrimary.withValues(alpha: 0.8)
                                  : theme.colorScheme.outline,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${date.day}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: selected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _monthShort(date.month),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: selected
                                  ? theme.colorScheme.onPrimary.withValues(alpha: 0.8)
                                  : theme.colorScheme.outline,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Slots de hora
            if (_selectedDate != null) ...[
              const SizedBox(height: 20),
              Text('Horarios disponibles',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  )),
              const SizedBox(height: 8),
              if (_loadingSlots)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                        color: theme.colorScheme.primary, strokeWidth: 2),
                  ),
                )
              else if (_slots.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.event_busy,
                          color: theme.colorScheme.outline, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _slotsMessage ??
                              'No hay horarios disponibles para este día',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _slots.map((slot) {
                    final sel = _selectedSlot == slot['time'];
                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedSlot = slot['time'];
                        _selectedSlotDatetime = slot['datetime'];
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: sel
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: sel
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: Text(
                          slot['time'],
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: sel
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                            fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],

            const SizedBox(height: 24),
            FilledButton(
              onPressed: (_selectedDate == null ||
                      _selectedSlot == null ||
                      _loading)
                  ? null
                  : () => _submit(context),
              child: _loading
                  ? SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : const Text('Confirmar cita'),
            ),
          ],
        ),
      ),
    );
  }

  String _monthShort(int month) {
    const months = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    return months[month - 1];
  }

  Future<void> _submit(BuildContext context) async {
    setState(() => _loading = true);
    try {
      await DioClient().dio.post('/appointments/', data: {
        'property_id': widget.propertyId,
        'seller_id': widget.sellerId,
        'appointment_type': _type,
        'scheduled_at': _selectedSlotDatetime,
      });
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('¡Cita agendada exitosamente!'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
      }
    } catch (_) {
      setState(() => _loading = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al agendar la cita'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
