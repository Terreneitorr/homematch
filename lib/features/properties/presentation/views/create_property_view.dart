import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/property_viewmodel.dart';
import '../../domain/entities/property_entity.dart';

class CreatePropertyView extends StatefulWidget {
  const CreatePropertyView({super.key});

  @override
  State<CreatePropertyView> createState() => _CreatePropertyViewState();
}

class _CreatePropertyViewState extends State<CreatePropertyView> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _zoneCtrl = TextEditingController();
  final _bedroomsCtrl = TextEditingController(text: '2');
  final _bathroomsCtrl = TextEditingController(text: '1');
  final _areaCtrl = TextEditingController();

  OperationType _operationType = OperationType.sale;
  bool _hasGarage = false;
  bool _hasGarden = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _cityCtrl.dispose();
    _zoneCtrl.dispose();
    _bedroomsCtrl.dispose();
    _bathroomsCtrl.dispose();
    _areaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = context.read<PropertyViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Nueva propiedad', style: theme.textTheme.titleLarge),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _isLoading ? null : () => _submit(vm, context),
              child: Text(
                'Publicar',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: _isLoading
                      ? theme.colorScheme.outline
                      : theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Fotos placeholder
            _SectionLabel(theme: theme, label: 'Fotos'),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: Row(
                children: [
                  _PhotoPlaceholder(theme: theme, isAdd: true),
                  const SizedBox(width: 8),
                  _PhotoPlaceholder(theme: theme),
                  const SizedBox(width: 8),
                  _PhotoPlaceholder(theme: theme),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Información básica
            _SectionLabel(theme: theme, label: 'Información básica'),
            const SizedBox(height: 8),
            _FormField(
              controller: _titleCtrl,
              label: 'Título de la propiedad',
              required: true,
            ),
            const SizedBox(height: 12),
            _FormField(
              controller: _descCtrl,
              label: 'Descripción',
              maxLines: 4,
              required: true,
            ),
            const SizedBox(height: 12),

            // Tipo de operación
            Text('Tipo de operación',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _ToggleButton(
                    theme: theme,
                    label: 'Venta',
                    selected: _operationType == OperationType.sale,
                    onTap: () => setState(() => _operationType = OperationType.sale),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ToggleButton(
                    theme: theme,
                    label: 'Renta',
                    selected: _operationType == OperationType.rent,
                    onTap: () => setState(() => _operationType = OperationType.rent),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _FormField(
              controller: _priceCtrl,
              label: 'Precio (MXN)',
              keyboardType: TextInputType.number,
              required: true,
            ),
            const SizedBox(height: 24),

            // Ubicación
            _SectionLabel(theme: theme, label: 'Ubicación'),
            const SizedBox(height: 8),
            _FormField(controller: _cityCtrl, label: 'Ciudad', required: true),
            const SizedBox(height: 12),
            _FormField(controller: _zoneCtrl, label: 'Zona / Colonia', required: true),
            const SizedBox(height: 24),

            // Características
            _SectionLabel(theme: theme, label: 'Características'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _StepperField(
                    theme: theme,
                    label: 'Habitaciones',
                    controller: _bedroomsCtrl,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StepperField(
                    theme: theme,
                    label: 'Baños',
                    controller: _bathroomsCtrl,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _FormField(
              controller: _areaCtrl,
              label: 'Superficie (m²)',
              keyboardType: TextInputType.number,
              required: true,
            ),
            const SizedBox(height: 12),
            _SwitchRow(
              theme: theme,
              label: 'Cochera',
              value: _hasGarage,
              onChanged: (v) => setState(() => _hasGarage = v),
            ),
            _SwitchRow(
              theme: theme,
              label: 'Jardín',
              value: _hasGarden,
              onChanged: (v) => setState(() => _hasGarden = v),
            ),
            const SizedBox(height: 32),

            // Botón publicar
            FilledButton(
              onPressed: _isLoading ? null : () => _submit(vm, context),
              child: _isLoading
                  ? SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.onPrimary,
                ),
              )
                  : const Text('Publicar propiedad'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(PropertyViewModel vm, BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final property = PropertyEntity(
        id: '',
        ownerId: 'current_user',
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        price: double.parse(_priceCtrl.text.trim()),
        operationType: _operationType,
        status: PropertyStatus.available,
        city: _cityCtrl.text.trim(),
        zone: _zoneCtrl.text.trim(),
        bedrooms: int.parse(_bedroomsCtrl.text),
        bathrooms: int.parse(_bathroomsCtrl.text),
        hasGarage: _hasGarage,
        hasGarden: _hasGarden,
        area: double.parse(_areaCtrl.text.trim()),
        photos: [],
        createdAt: DateTime.now(),
      );
      await vm.createProperty(property);
      if (context.mounted) Navigator.pop(context);
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }
}

// ─── WIDGETS INTERNOS ─────────────────────────────────────────────

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

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final TextInputType keyboardType;
  final bool required;

  const _FormField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
      validator: required
          ? (v) => v == null || v.trim().isEmpty ? 'Campo requerido' : null
          : null,
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final ThemeData theme;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ToggleButton({required this.theme, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Center(
          child: Text(label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: selected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              )),
        ),
      ),
    );
  }
}

class _StepperField extends StatelessWidget {
  final ThemeData theme;
  final String label;
  final TextEditingController controller;
  const _StepperField({required this.theme, required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 6),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.remove, size: 18, color: theme.colorScheme.primary),
                onPressed: () {
                  final v = int.tryParse(controller.text) ?? 1;
                  if (v > 1) controller.text = '${v - 1}';
                },
              ),
              Expanded(
                child: Text(controller.text,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: Icon(Icons.add, size: 18, color: theme.colorScheme.primary),
                onPressed: () {
                  final v = int.tryParse(controller.text) ?? 1;
                  controller.text = '${v + 1}';
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final ThemeData theme;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchRow({required this.theme, required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(label, style: theme.textTheme.bodyMedium),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  final ThemeData theme;
  final bool isAdd;
  const _PhotoPlaceholder({required this.theme, this.isAdd = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isAdd ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
          style: isAdd ? BorderStyle.solid : BorderStyle.solid,
          width: isAdd ? 1.5 : 1,
        ),
      ),
      child: Icon(
        isAdd ? Icons.add_photo_alternate_outlined : Icons.image_outlined,
        color: isAdd ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
        size: 28,
      ),
    );
  }
}