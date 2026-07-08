import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> loginWithGoogle({String role});
  Future<void> logout();
  Future<UserEntity?> getCurrentUser();
}