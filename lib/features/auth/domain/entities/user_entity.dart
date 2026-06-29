class UserEntity {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? avatar;
  final bool isActive;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatar,
    required this.isActive,
  });
}