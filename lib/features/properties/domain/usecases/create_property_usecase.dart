import '../entities/property_entity.dart';
import '../repositories/property_repository.dart';

class CreatePropertyUseCase {
  final PropertyRepository repository;
  CreatePropertyUseCase(this.repository);

  Future<PropertyEntity> call(PropertyEntity property) async {
    return await repository.createProperty(property);
  }
}