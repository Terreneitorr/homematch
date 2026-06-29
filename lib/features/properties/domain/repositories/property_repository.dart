import '../entities/property_entity.dart';

abstract class PropertyRepository {
  Future<List<PropertyEntity>> getProperties();
  Future<PropertyEntity> getPropertyById(String id);
  Future<PropertyEntity> createProperty(PropertyEntity property);
  Future<PropertyEntity> updateProperty(PropertyEntity property);
  Future<void> deleteProperty(String id);
}