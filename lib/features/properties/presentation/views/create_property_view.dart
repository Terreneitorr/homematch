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

  @override
  Widget build(BuildContext context) {
    final vm = context.read<PropertyViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Nueva Propiedad', style: theme.textTheme.titleLarge),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(context, _titleCtrl, 'Título', required: true),
            _field(context, _descCtrl, 'Descripción', maxLines: 3, required: true),
            _field(context, _priceCtrl, 'Precio',
                keyboardType: TextInputType.number, required: true),
            _field(context, _cityCtrl, 'Ciudad', required: true),
            _field(context, _zoneCtrl, 'Zona', required: true),
            _field(context, _bedroomsCtrl, 'Habitaciones',
                keyboardType: TextInputType.number),
            _field(context, _bathroomsCtrl, 'Baños',
                keyboardType: TextInputType.number),
            _field(context, _areaCtrl, 'Superficie (m²)',
                keyboardType: TextInputType.number, required: true),
            const SizedBox(height: 16),
            Text('Tipo de operación',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
            Row(
              children: [
                Radio<OperationType>(
                  value: OperationType.sale,
                  groupValue: _operationType,
                  onChanged: (v) => setState(() => _operationType = v!),
                ),
                Text('Venta', style: theme.textTheme.bodyMedium),
                const SizedBox(width: 16),
                Radio<OperationType>(
                  value: OperationType.rent,
                  groupValue: _operationType,
                  onChanged: (v) => setState(() => _operationType = v!),
                ),
                Text('Renta', style: theme.textTheme.bodyMedium),
              ],
            ),
            SwitchListTile(
              title: Text('Cochera', style: theme.textTheme.bodyMedium),
              value: _hasGarage,
              onChanged: (v) => setState(() => _hasGarage = v),
            ),
            SwitchListTile(
              title: Text('Jardín', style: theme.textTheme.bodyMedium),
              value: _hasGarden,
              onChanged: (v) => setState(() => _hasGarden = v),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                final property = PropertyEntity(
                  id: '',
                  ownerId: 'current_user',
                  title: _titleCtrl.text,
                  description: _descCtrl.text,
                  price: double.parse(_priceCtrl.text),
                  operationType: _operationType,
                  status: PropertyStatus.available,
                  city: _cityCtrl.text,
                  zone: _zoneCtrl.text,
                  bedrooms: int.parse(_bedroomsCtrl.text),
                  bathrooms: int.parse(_bathroomsCtrl.text),
                  hasGarage: _hasGarage,
                  hasGarden: _hasGarden,
                  area: double.parse(_areaCtrl.text),
                  photos: [],
                  createdAt: DateTime.now(),
                );
                await vm.createProperty(property);
                if (context.mounted) Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Publicar Propiedad', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(BuildContext context, TextEditingController ctrl, String label,
      {int maxLines = 1,
        TextInputType keyboardType = TextInputType.text,
        bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        validator: required
            ? (v) => v == null || v.isEmpty ? 'Campo requerido' : null
            : null,
      ),
    );
  }
}