import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.role,
    super.avatar,
    required super.isActive,
    super.acceptedTerms,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['user_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'USER',
      avatar: json['avatar']?.toString(),
      isActive: json['is_active'] == true || json['is_active'] == null,
      acceptedTerms: json['accepted_terms'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'avatar': avatar,
      'is_active': isActive,
      'accepted_terms': acceptedTerms,
    };
  }
}