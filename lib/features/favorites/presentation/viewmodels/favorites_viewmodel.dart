import 'package:flutter/material.dart';
import '../../../properties/domain/entities/property_entity.dart';
import '../../domain/repositories/favorites_repository.dart';

class FavoritesViewModel extends ChangeNotifier {
  final FavoritesRepository repository;

  FavoritesViewModel(this.repository);

  Set<String> _favoriteIds = {};
  List<PropertyEntity> _favoriteProperties = [];

  Set<String> get favoriteIds => _favoriteIds;
  List<PropertyEntity> get favoriteProperties => _favoriteProperties;

  Future<void> loadFavorites(String userId, List<PropertyEntity> allProperties) async {
    final ids = await repository.getFavoriteIds(userId);
    _favoriteIds = ids.toSet();
    _favoriteProperties = allProperties.where((p) => _favoriteIds.contains(p.id)).toList();
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
}