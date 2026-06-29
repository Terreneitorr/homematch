import '../../domain/entities/property_entity.dart';
import '../../domain/repositories/property_repository.dart';
import '../datasources/property_remote_datasource.dart';

class PropertyRepositoryImpl implements PropertyRepository {
  final PropertyRemoteDataSource remoteDataSource;
  PropertyRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<PropertyEntity>> getProperties() async {
    return await remoteDataSource.getProperties();
  }

  @override
  Future<PropertyEntity> getPropertyById(String id) async {
    return await remoteDataSource.getPropertyById(id);
  }

  @override
  Future<PropertyEntity> createProperty(PropertyEntity property) async {
    return await remoteDataSource.createProperty({
      'owner_id': property.ownerId,
      'title': property.title,
      'description': property.description,
      'price': property.price,
      'operation_type': property.operationType == OperationType.sale ? 'sale' : 'rent',
      'city': property.city,
      'zone': property.zone,
      'colony': property.colony,
      'bedrooms': property.bedrooms,
      'bathrooms': property.bathrooms,
      'has_garage': property.hasGarage,
      'has_garden': property.hasGarden,
      'area': property.area,
    });
  }

  @override
  Future<PropertyEntity> updateProperty(PropertyEntity property) async {
    return property;
  }

  @override
  Future<void> deleteProperty(String id) async {
    await remoteDataSource.deleteProperty(id);
  }
}