import '../../domain/entities/property_entity.dart';

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
    return PropertyModel(
      id: json['id'],
      ownerId: json['owner_id'],
      title: json['title'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      operationType: json['operation_type'] == 'sale'
          ? OperationType.sale
          : OperationType.rent,
      status: _parseStatus(json['status']),
      city: json['city'],
      zone: json['zone'],
      colony: json['colony'],
      bedrooms: json['bedrooms'],
      bathrooms: json['bathrooms'],
      hasGarage: json['has_garage'] ?? false,
      hasGarden: json['has_garden'] ?? false,
      area: (json['area'] as num).toDouble(),
      photos: json['photos'] != null
          ? (json['photos'] is String ? [] : List<String>.from(json['photos']))
          : [],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  static PropertyStatus _parseStatus(String status) {
    switch (status) {
      case 'reserved': return PropertyStatus.reserved;
      case 'sold': return PropertyStatus.sold;
      case 'rented': return PropertyStatus.rented;
      case 'inactive': return PropertyStatus.inactive;
      default: return PropertyStatus.available;
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
      'photos': photos,
    };
  }
}