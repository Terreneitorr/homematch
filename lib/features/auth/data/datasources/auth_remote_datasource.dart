import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> loginWithGoogle({String role});
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
  Future<String?> getStoredToken();
  Future<void> clearToken();
  Future<UserModel?> acceptTerms();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient _client = DioClient();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
    '578896202911-4fhr5j0fffmkgeh9kcqng1b6gug125jl.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  @override
  Future<String?> getStoredToken() async {
    return await _client.getToken();
  }

  @override
  Future<void> clearToken() async {
    await _client.deleteToken();
  }

  @override
  Future<UserModel> loginWithGoogle({String role = 'USER'}) async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    GoogleSignInAccount? account;
    try {
      account = await _googleSignIn.signIn();
    } catch (e) {
      throw Exception('Error Google Sign In: $e');
    }

    if (account == null) throw Exception('Login cancelado');

    try {
      final response = await _client.dio.post('/auth/google', data: {
        'google_id': account.id,
        'name': account.displayName ?? account.email.split('@').first,
        'email': account.email,
        'avatar': account.photoUrl,
        'role': role,
      });

      print('RESPONSE DATA: ${response.data}');  // <- agrega esto
      print('RESPONSE TYPE: ${response.data.runtimeType}');

      final data = response.data;
      await _client.saveToken(data['access_token']);

      return UserModel(
        id: data['user_id']?.toString() ?? '',
        name: data['name']?.toString() ?? '',
        email: data['email']?.toString() ?? '',
        role: data['role']?.toString() ?? 'USER',
        isActive: true,
        acceptedTerms: data['accepted_terms'] == true,
      );
    } catch (e, stack) {
      print('ERROR LOGIN: $e');
      print('STACK: $stack');
      rethrow;
    }
  }

  @override
  Future<UserModel?> acceptTerms() async {
    final response = await _client.dio.post('/auth/accept-terms');
    final data = response.data;
    if (data['access_token'] != null) {
      await _client.saveToken(data['access_token']);
    }
    if (data['user'] != null) {
      return UserModel.fromJson(data['user']);
    }
    return null;
  }

  @override
  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _client.deleteToken();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final token = await _client.getToken();
      if (token == null || token.isEmpty) return null;
      final response = await _client.dio.get('/users/me');
      final data = response.data;
      return UserModel(
        id: data['id'],
        name: data['name'],
        email: data['email'],
        role: data['role'],
        avatar: data['avatar'],
        isActive: data['is_active'] ?? true,
        acceptedTerms: data['accepted_terms'] ?? false,
      );
    } catch (_) {
      return null;
    }
  }
}
