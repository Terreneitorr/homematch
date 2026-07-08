import 'package:flutter/material.dart';
import '../../../properties/domain/entities/property_entity.dart';
import '../../domain/repositories/favorites_repository.dart';

class FavoritesViewModel extends ChangeNotifier {
  final FavoritesRepository repository;

  FavoritesViewModel(this.repository);

  Set<String> _favoriteIds = {};
  List<PropertyEntity> _favoriteProperties = [];
  bool _loading = false;

  Set<String> get favoriteIds => _favoriteIds;
  List<PropertyEntity> get favoriteProperties => _favoriteProperties;
  bool get loading => _loading;

  Future<void> loadFavorites(String userId, List<PropertyEntity> allProperties) async {
    _loading = true;
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
}