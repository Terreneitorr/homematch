import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/upload_service.dart';
import '../../../../core/constants/locations_data.dart';
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

  String? _selectedEstado;
  String? _selectedMunicipio;
  String? _selectedZona;

  final List<File> _selectedImages = [];
  final List<String> _uploadedUrls = [];
  final _picker = ImagePicker();
  final _uploadService = UploadService();

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

  Future<void> _pickImage() async {
    final remaining = 8 - _selectedImages.length;
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Máximo 8 fotos permitidas')),
      );
      return;
    }

    final picked = await _picker.pickMultiImage(
      imageQuality: 80,
      maxWidth: 1200,
    );

    if (picked.isNotEmpty) {
      final toAdd = picked.take(remaining).map((e) => File(e.path)).toList();
      setState(() => _selectedImages.addAll(toAdd));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // Subir fotos
      final List<String> uploadedUrls = [];
      for (final img in _selectedImages) {
        final url = await _uploadService.uploadImage(img);
        if (url != null) uploadedUrls.add(url);
      }

      final vm = context.read<PropertyViewModel>();

      final property = PropertyEntity(
        id: '',
        ownerId: '',
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        price: double.parse(_priceCtrl.text.trim()),
        operationType: _operationType,
        status: PropertyStatus.available,
        city: _cityCtrl.text.trim(),
        zone: _zoneCtrl.text.trim(),
        bedrooms: int.tryParse(_bedroomsCtrl.text) ?? 1,
        bathrooms: int.tryParse(_bathroomsCtrl.text) ?? 1,
        hasGarage: _hasGarage,
        hasGarden: _hasGarden,
        area: double.parse(_areaCtrl.text.trim()),
        photos: uploadedUrls,
        createdAt: DateTime.now(),
      );

      await vm.createProperty(property);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Propiedad publicada exitosamente'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Nueva propiedad', style: theme.textTheme.titleLarge),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _isLoading ? null : _submit,
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
            // Fotos
            _SectionLabel(theme: theme, label: 'Fotos'),
            const SizedBox(height: 8),
            SizedBox(
              height: 110,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Botón agregar
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: theme.colorScheme.primary,
                          style: BorderStyle.solid,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              color: theme.colorScheme.primary, size: 28),
                          const SizedBox(height: 4),
                          Text('Agregar',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                              )),
                          Text('${_selectedImages.length}/8',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.outline,
                                fontSize: 10,
                              )),
                        ],
                      ),
                    ),
                  ),
                  // Fotos seleccionadas
                  ..._selectedImages.asMap().entries.map((e) {
                    final i = e.key;
                    final file = e.value;
                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            image: DecorationImage(
                              image: FileImage(file),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        if (i == 0)
                          Positioned(
                            bottom: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('Portada',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                    fontSize: 9,
                                  )),
                            ),
                          ),
                        Positioned(
                          top: 4,
                          right: 12,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedImages.removeAt(i)),
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.error,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.close,
                                  size: 14,
                                  color: theme.colorScheme.onError),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Información básica
            _SectionLabel(theme: theme, label: 'Información básica'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Título de la propiedad'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Descripción'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),

            // Tipo operación
            Text('Tipo de operación',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _ToggleBtn(
                    theme: theme,
                    label: 'Venta',
                    selected: _operationType == OperationType.sale,
                    onTap: () => setState(() => _operationType = OperationType.sale),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ToggleBtn(
                    theme: theme,
                    label: 'Renta',
                    selected: _operationType == OperationType.rent,
                    onTap: () => setState(() => _operationType = OperationType.rent),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Precio (MXN)',
                prefixText: '\$ ',
                suffixText: _operationType == OperationType.rent ? '/mes' : '',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Requerido';
                if (double.tryParse(v.trim()) == null) return 'Número inválido';
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Ubicación
            _SectionLabel(theme: theme, label: 'Ubicación'),
            const SizedBox(height: 8),

            // Estado
            _LocationDropdown(
              theme: theme,
              label: 'Estado',
              value: _selectedEstado,
              items: LocationsData.getEstados(),
              onChanged: (val) => setState(() {
                _selectedEstado = val;
                _selectedMunicipio = null;
                _selectedZona = null;
                _cityCtrl.text = '';
                _zoneCtrl.text = '';
              }),
            ),
            const SizedBox(height: 12),

            // Municipio
            if (_selectedEstado != null) ...[
              _LocationDropdown(
                theme: theme,
                label: 'Municipio / Ciudad',
                value: _selectedMunicipio,
                items: LocationsData.getMunicipios(_selectedEstado!),
                onChanged: (val) => setState(() {
                  _selectedMunicipio = val;
                  _selectedZona = null;
                  _cityCtrl.text = val ?? '';
                  _zoneCtrl.text = '';
                }),
              ),
              const SizedBox(height: 12),
            ],

            // Zona
            if (_selectedMunicipio != null) ...[
              _LocationDropdown(
                theme: theme,
                label: 'Zona / Colonia',
                value: _selectedZona,
                items: LocationsData.getZonas(_selectedMunicipio!),
                onChanged: (val) => setState(() {
                  _selectedZona = val;
                  _zoneCtrl.text = val ?? '';
                }),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 12),

            // Características
            _SectionLabel(theme: theme, label: 'Características'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _StepField(
                    theme: theme,
                    label: 'Habitaciones',
                    controller: _bedroomsCtrl,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StepField(
                    theme: theme,
                    label: 'Baños',
                    controller: _bathroomsCtrl,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _areaCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Superficie',
                suffixText: 'm²',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Requerido';
                if (double.tryParse(v.trim()) == null) return 'Número inválido';
                return null;
              },
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: Text('Cochera', style: theme.textTheme.bodyMedium),
              value: _hasGarage,
              onChanged: (v) => setState(() => _hasGarage = v),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: Text('Jardín', style: theme.textTheme.bodyMedium),
              value: _hasGarden,
              onChanged: (v) => setState(() => _hasGarden = v),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 32),

            FilledButton(
              onPressed: _isLoading ? null : _submit,
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

class _ToggleBtn extends StatelessWidget {
  final ThemeData theme;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ToggleBtn({required this.theme, required this.label,
    required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Center(
          child: Text(label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: selected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              )),
        ),
      ),
    );
  }
}

class _StepField extends StatelessWidget {
  final ThemeData theme;
  final String label;
  final TextEditingController controller;
  const _StepField({required this.theme, required this.label,
    required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            )),
        const SizedBox(height: 6),
        StatefulBuilder(
          builder: (context, setLocalState) => Container(
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.remove,
                      size: 18, color: theme.colorScheme.primary),
                  onPressed: () {
                    final v = int.tryParse(controller.text) ?? 1;
                    if (v > 1) {
                      setLocalState(() {
                        controller.text = '${v - 1}';
                      });
                    }
                  },
                ),
                Expanded(
                  child: Text(
                    controller.text,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add,
                      size: 18, color: theme.colorScheme.primary),
                  onPressed: () {
                    final v = int.tryParse(controller.text) ?? 1;
                    setLocalState(() {
                      controller.text = '${v + 1}';
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LocationDropdown extends StatelessWidget {
  final ThemeData theme;
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _LocationDropdown({
    required this.theme,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label),
      isExpanded: true,
      items: items
          .map((item) => DropdownMenuItem(
        value: item,
        child: Text(item, overflow: TextOverflow.ellipsis),
      ))
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Selecciona $label' : null,
    );
  }
}
