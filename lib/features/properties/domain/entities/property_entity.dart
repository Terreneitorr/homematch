enum OperationType { sale, rent }

enum PropertyStatus { available, reserved, sold, rented, inactive }

class PropertyEntity {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final double price;
  final OperationType operationType;
  final PropertyStatus status;
  final String city;
  final String zone;
  final String? colony;
  final int bedrooms;
  final int bathrooms;
  final bool hasGarage;
  final bool hasGarden;
  final double area;
  final List<String> photos;
  final DateTime createdAt;

  const PropertyEntity({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.price,
    required this.operationType,
    required this.status,
    required this.city,
    required this.zone,
    this.colony,
    required this.bedrooms,
    required this.bathrooms,
    required this.hasGarage,
    required this.hasGarden,
    required this.area,
    required this.photos,
    required this.createdAt,
  });
}