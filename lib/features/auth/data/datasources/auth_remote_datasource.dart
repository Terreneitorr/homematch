import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> loginWithGoogle();
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient _client = DioClient();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '578896202911-4fhr5j0fffmkgeh9kcqng1b6gug125jl.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  @override
  Future<UserModel> loginWithGoogle() async {
    await _googleSignIn.signOut();
    final account = await _googleSignIn.signIn();
    if (account == null) throw Exception('Login cancelado');

    // Enviar al backend
    final response = await _client.dio.post('/auth/google', data: {
      'google_id': account.id,
      'name': account.displayName ?? '',
      'email': account.email,
      'avatar': account.photoUrl,
    });

    final data = response.data;
    await _client.saveToken(data['access_token']);

    return UserModel(
      id: data['user_id'],
      name: data['name'],
      email: data['email'],
      role: data['role'],
      isActive: true,
    );
  }

  @override
  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _client.deleteToken();
  }
}