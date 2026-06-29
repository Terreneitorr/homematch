import 'package:flutter/material.dart';
import '../../../properties/domain/entities/property_entity.dart';

class SearchViewModel extends ChangeNotifier {
  List<PropertyEntity> _allProperties = [];
  List<PropertyEntity> _results = [];
  String _query = '';
  OperationType? _filterType;
  double? _maxPrice;

  List<PropertyEntity> get results => _results;
  String get query => _query;
  OperationType? get filterType => _filterType;

  void setProperties(List<PropertyEntity> properties) {
    _allProperties = properties;
    _results = properties;
  }

  void search(String query) {
    _query = query;
    _applyFilters();
  }

  void setFilterType(OperationType? type) {
    _filterType = type;
    _applyFilters();
  }

  void setMaxPrice(double? price) {
    _maxPrice = price;
    _applyFilters();
  }

  void clearFilters() {
    _query = '';
    _filterType = null;
    _maxPrice = null;
    _results = _allProperties;
    notifyListeners();
  }

  void _applyFilters() {
    _results = _allProperties.where((p) {
      final matchesQuery = _query.isEmpty ||
          p.title.toLowerCase().contains(_query.toLowerCase()) ||
          p.city.toLowerCase().contains(_query.toLowerCase()) ||
          p.zone.toLowerCase().contains(_query.toLowerCase()) ||
          p.description.toLowerCase().contains(_query.toLowerCase());

      final matchesType = _filterType == null || p.operationType == _filterType;
      final matchesPrice = _maxPrice == null || p.price <= _maxPrice!;

      return matchesQuery && matchesType && matchesPrice;
    }).toList();
    notifyListeners();
  }
}