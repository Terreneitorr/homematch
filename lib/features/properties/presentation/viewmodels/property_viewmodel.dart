import 'package:flutter/material.dart';
import '../../domain/entities/property_entity.dart';
import '../../domain/usecases/get_properties_usecase.dart';
import '../../domain/usecases/create_property_usecase.dart';
import '../../domain/usecases/delete_property_usecase.dart';
import '../../data/datasources/ml_datasource.dart';

enum PropertyStatus2 { initial, loading, loaded, error }

class PropertyViewModel extends ChangeNotifier {
  final GetPropertiesUseCase getPropertiesUseCase;
  final CreatePropertyUseCase createPropertyUseCase;
  final DeletePropertyUseCase deletePropertyUseCase;
  final MLDataSource _mlDataSource = MLDataSource();

  PropertyViewModel({
    required this.getPropertiesUseCase,
    required this.createPropertyUseCase,
    required this.deletePropertyUseCase,
  });

  PropertyStatus2 _status = PropertyStatus2.initial;
  List<PropertyEntity> _properties = [];
  String? _errorMessage;
  Map<String, Map<String, dynamic>> _mlResults = {};

  PropertyStatus2 get status => _status;
  List<PropertyEntity> get properties => _properties;
  String? get errorMessage => _errorMessage;
  Map<String, Map<String, dynamic>> get mlResults => _mlResults;

  String? getSegmento(String propertyId) {
    return _mlResults[propertyId]?['segmento'];
  }

  Future<void> loadProperties() async {
    _status = PropertyStatus2.loading;
    notifyListeners();
    try {
      _properties = await getPropertiesUseCase();
      _status = PropertyStatus2.loaded;
      // Clasificar todas las propiedades en background
      _classifyAllProperties();
    } catch (e) {
      _errorMessage = e.toString();
      _status = PropertyStatus2.error;
    }
    notifyListeners();
  }

  Future<void> _classifyAllProperties() async {
    for (final property in _properties) {
      if (!_mlResults.containsKey(property.id)) {
        final result = await _mlDataSource.classifyProperty(
          precio: property.price,
          habitaciones: property.bedrooms,
          banos: property.bathrooms,
          metros: property.area,
          tipo: _getTipo(property),
        );
        _mlResults[property.id] = result;
      }
    }
    notifyListeners();
  }

  String _getTipo(PropertyEntity property) {
    if (property.title.toLowerCase().contains('departamento')) {
      return 'Departamento';
    } else if (property.title.toLowerCase().contains('local')) {
      return 'Local';
    } else if (property.title.toLowerCase().contains('terreno')) {
      return 'Terreno';
    } else if (property.title.toLowerCase().contains('oficina')) {
      return 'Oficina';
    }
    return 'Casa';
  }

  Future<void> createProperty(PropertyEntity property) async {
    try {
      final newProperty = await createPropertyUseCase(property);
      _properties.insert(0, newProperty);

      // Clasificar la nueva propiedad
      final result = await _mlDataSource.classifyProperty(
        precio: newProperty.price,
        habitaciones: newProperty.bedrooms,
        banos: newProperty.bathrooms,
        metros: newProperty.area,
        tipo: _getTipo(newProperty),
      );
      _mlResults[newProperty.id] = result;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteProperty(String id) async {
    try {
      await deletePropertyUseCase(id);
      _properties.removeWhere((p) => p.id == id);
      _mlResults.remove(id);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}