import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginWithGoogleUseCase {
  final AuthRepository repository;
  LoginWithGoogleUseCase(this.repository);

  Future<UserEntity> call({String role = 'USER'}) async {
    return await repository.loginWithGoogle(role: role);
  }
}