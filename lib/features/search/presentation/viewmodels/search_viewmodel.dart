import 'dart:async';
import 'package:flutter/material.dart';
import '../../../properties/domain/entities/property_entity.dart';
import '../../../properties/domain/repositories/property_repository.dart';

class SearchViewModel extends ChangeNotifier {
  final PropertyRepository repository;
  SearchViewModel(this.repository);

  List<PropertyEntity> _allProperties = [];
  // Resultados "base": todos los properties, o los que devolvió la búsqueda
  // semántica — antes de aplicarles filterType/maxPrice encima.
  List<PropertyEntity> _baseResults = [];
  List<PropertyEntity> _results = [];

  String _query = '';
  OperationType? _filterType;
  double? _maxPrice;
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _debounce;

  List<PropertyEntity> get results => _results;
  String get query => _query;
  OperationType? get filterType => _filterType;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setProperties(List<PropertyEntity> properties) {
    _allProperties = properties;
    _baseResults = properties;
    _results = properties;
  }

  /// Se llama en cada tecleo del usuario (onChanged del TextField).
  /// Hace debounce de 400ms antes de pegarle al backend, para no
  /// disparar una búsqueda por cada letra escrita.
  void search(String query) {
    _query = query;
    _debounce?.cancel();

    if (query.trim().isEmpty) {
      _baseResults = _allProperties;
      _errorMessage = null;
      _applyLocalFilters();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchRemote(query);
    });
  }

  Future<void> _searchRemote(String query) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final remoteResults = await repository.searchProperties(query);
      _baseResults = remoteResults;
    } catch (e) {
      // Si la búsqueda semántica falla (red caída, backend redeployando,
      // IP cambiada, etc.) no dejamos al usuario sin nada: caemos a un
      // filtro local básico sobre lo que ya tenemos en memoria.
      _errorMessage = 'Búsqueda avanzada no disponible, mostrando resultados básicos';
      _baseResults = _allProperties.where((p) =>
      p.title.toLowerCase().contains(query.toLowerCase()) ||
          p.city.toLowerCase().contains(query.toLowerCase())
      ).toList();
    }

    _isLoading = false;
    _applyLocalFilters();
  }

  void setFilterType(OperationType? type) {
    _filterType = type;
    _applyLocalFilters();
  }

  void setMaxPrice(double? price) {
    _maxPrice = price;
    _applyLocalFilters();
  }

  void clearFilters() {
    _query = '';
    _filterType = null;
    _maxPrice = null;
    _baseResults = _allProperties;
    _errorMessage = null;
    _applyLocalFilters();
  }

  void _applyLocalFilters() {
    _results = _baseResults.where((p) {
      final matchesType = _filterType == null || p.operationType == _filterType;
      final matchesPrice = _maxPrice == null || p.price <= _maxPrice!;
      return matchesType && matchesPrice;
    }).toList();
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}