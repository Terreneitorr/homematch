import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> loginWithGoogle();
  Future<void> logout();
  Future<UserEntity?> getCurrentUser();
}