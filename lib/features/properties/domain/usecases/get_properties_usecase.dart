import '../entities/property_entity.dart';
import '../repositories/property_repository.dart';

class GetPropertiesUseCase {
  final PropertyRepository repository;
  GetPropertiesUseCase(this.repository);

  Future<List<PropertyEntity>> call() async {
    return await repository.getProperties();
  }
}