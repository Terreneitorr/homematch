import 'package:flutter/material.dart';
import '../../../properties/domain/entities/property_entity.dart';
import '../../domain/repositories/favorites_repository.dart';

class FavoritesViewModel extends ChangeNotifier {
  final FavoritesRepository repository;

  FavoritesViewModel(this.repository);

  Set<String> _favoriteIds = {};
  List<PropertyEntity> _favoriteProperties = [];
  bool _loading = false;
  String? _lastLoadedUserId;

  Set<String> get favoriteIds => _favoriteIds;
  List<PropertyEntity> get favoriteProperties => _favoriteProperties;
  bool get loading => _loading;

  Future<void> loadFavorites(String userId, List<PropertyEntity> allProperties) async {
    // Si el usuario cambió, limpiar inmediatamente para no mostrar datos del anterior
    if (_lastLoadedUserId != userId) {
      _favoriteIds = {};
      _favoriteProperties = [];
      notifyListeners();
    } else if (_favoriteIds.isNotEmpty && _favoriteProperties.isNotEmpty) {
      // Si es el mismo usuario y ya hay datos, solo sincronizar
      syncWithProperties(allProperties);
      return;
    }

    _loading = true;
    _lastLoadedUserId = userId;
    notifyListeners();
    try {
      final ids = await repository.getFavoriteIds(userId);
      _favoriteIds = ids.toSet();
      _favoriteProperties = allProperties
          .where((p) => _favoriteIds.contains(p.id))
          .toList();
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<void> toggleFavorite(String userId, PropertyEntity property) async {
    if (_favoriteIds.contains(property.id)) {
      await repository.removeFavorite(userId, property.id);
      _favoriteIds.remove(property.id);
      _favoriteProperties.removeWhere((p) => p.id == property.id);
    } else {
      await repository.addFavorite(userId, property.id);
      _favoriteIds.add(property.id);
      _favoriteProperties.add(property);
    }
    notifyListeners();
  }

  bool isFavorite(String propertyId) => _favoriteIds.contains(propertyId);

  void syncWithProperties(List<PropertyEntity> allProperties) {
    _favoriteProperties = allProperties
        .where((p) => _favoriteIds.contains(p.id))
        .toList();
    notifyListeners();
  }

  void clear() {
    _favoriteIds = {};
    _favoriteProperties = [];
    _lastLoadedUserId = null;
    notifyListeners();
  }
}
