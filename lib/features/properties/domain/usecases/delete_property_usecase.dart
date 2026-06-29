import '../repositories/property_repository.dart';

class DeletePropertyUseCase {
  final PropertyRepository repository;
  DeletePropertyUseCase(this.repository);

  Future<void> call(String id) async {
    await repository.deleteProperty(id);
  }
}