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
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient _client = DioClient();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '578896202911-4fhr5j0fffmkgeh9kcqng1b6gug125jl.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  @override
  Future<String?> getStoredToken() async => await _client.getToken();

  @override
  Future<void> clearToken() async => await _client.deleteToken();

  @override
  Future<UserModel> loginWithGoogle({String role = 'USER'}) async {
    try { await _googleSignIn.signOut(); } catch (_) {}

    GoogleSignInAccount? account;
    try {
      account = await _googleSignIn.signIn();
    } catch (e) {
      throw Exception('Error Google Sign In: $e');
    }
    if (account == null) throw Exception('Login cancelado por el usuario');

    try {
      final response = await _client.dio.post('/auth/google', data: {
        'google_id': account.id,
        'name': account.displayName ?? account.email.split('@').first,
        'email': account.email,
        'avatar': account.photoUrl,
        'role': role,
      });
      final data = response.data;
      await _client.saveToken(data['access_token']);
      return UserModel(
        id: data['user_id']?.toString() ?? '',
        name: data['name']?.toString() ?? '',
        email: data['email']?.toString() ?? '',
        role: data['role']?.toString() ?? 'USER',
        avatar: data['avatar']?.toString() ?? account.photoUrl,
        isActive: true,
        acceptedTerms: data['accepted_terms'] == true,
        subscriptionPlan: data['subscription_plan']?.toString(),
        subscriptionStatus: data['subscription_status']?.toString(),
      );
    } on DioException catch (e) {
      throw Exception('Error: ${e.response?.data ?? e.message}');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try { await _googleSignIn.signOut(); } catch (_) {}
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
        id: data['id']?.toString() ?? '',
        name: data['name']?.toString() ?? '',
        email: data['email']?.toString() ?? '',
        role: data['role']?.toString() ?? 'USER',
        avatar: data['avatar']?.toString(),
        isActive: data['is_active'] ?? true,
        acceptedTerms: data['accepted_terms'] == true,
        subscriptionPlan: data['subscription_plan']?.toString(),
        subscriptionStatus: data['subscription_status']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<UserModel> loginDirect({required String email, required String role}) async {
    try {
      final response = await _client.dio.post('/auth/google', data: {
        'google_id': email.replaceAll('@', '_').replaceAll('.', '_'),
        'name': email.split('@').first,
        'email': email,
        'avatar': null,
        'role': role,
      });
      final data = response.data;
      await _client.saveToken(data['access_token']);
      return UserModel(
        id: data['user_id']?.toString() ?? '',
        name: data['name']?.toString() ?? '',
        email: data['email']?.toString() ?? '',
        role: data['role']?.toString() ?? 'USER',
        avatar: data['avatar']?.toString(),
        isActive: true,
        acceptedTerms: data['accepted_terms'] == true,
        subscriptionPlan: data['subscription_plan']?.toString(),
        subscriptionStatus: data['subscription_status']?.toString(),
      );
    } on DioException catch (e) {
      throw Exception('${e.response?.data ?? e.message}');
    }
  }
}