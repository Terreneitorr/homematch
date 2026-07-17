import 'dart:convert';
import 'package:homematch_ai/features/properties/domain/entities/property_entity.dart';

class PropertyModel extends PropertyEntity {
  const PropertyModel({
    required super.id,
    required super.ownerId,
    required super.title,
    required super.description,
    required super.price,
    required super.operationType,
    required super.status,
    required super.city,
    required super.zone,
    super.colony,
    required super.bedrooms,
    required super.bathrooms,
    required super.hasGarage,
    required super.hasGarden,
    required super.area,
    required super.photos,
    required super.createdAt,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    List<String> parsePhotos(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      if (raw is String) {
        if (raw.isEmpty || raw == '[]') return [];
        try {
          final decoded = jsonDecode(raw);
          if (decoded is List) return decoded.map((e) => e.toString()).toList();
        } catch (_) {}
      }
      return [];
    }

    return PropertyModel(
      id: json['id']?.toString() ?? '',
      ownerId: json['owner_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      operationType: json['operation_type'] == 'sale'
          ? OperationType.sale
          : OperationType.rent,
      status: _parseStatus(json['status']?.toString() ?? 'available'),
      city: json['city']?.toString() ?? '',
      zone: json['zone']?.toString() ?? '',
      colony: json['colony']?.toString(),
      bedrooms: (json['bedrooms'] as num?)?.toInt() ?? 1,
      bathrooms: (json['bathrooms'] as num?)?.toInt() ?? 1,
      hasGarage: json['has_garage'] == true,
      hasGarden: json['has_garden'] == true,
      area: (json['area'] as num?)?.toDouble() ?? 0,
      photos: parsePhotos(json['photos']),
      createdAt: DateTime.parse(
          json['created_at']?.toString() ?? DateTime.now().toIso8601String()),
    );
  }

  static PropertyStatus _parseStatus(String status) {
    switch (status) {
      case 'reserved':
        return PropertyStatus.reserved;
      case 'sold':
        return PropertyStatus.sold;
      case 'rented':
        return PropertyStatus.rented;
      case 'inactive':
        return PropertyStatus.inactive;
      default:
        return PropertyStatus.available;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'owner_id': ownerId,
      'title': title,
      'description': description,
      'price': price,
      'operation_type': operationType == OperationType.sale ? 'sale' : 'rent',
      'status': status.name,
      'city': city,
      'zone': zone,
      'colony': colony,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'has_garage': hasGarage,
      'has_garden': hasGarden,
      'area': area,
      'photos': photos.isEmpty ? '[]' : '[${photos.map((p) => '"$p"').join(',')}]',
    };
  }
}