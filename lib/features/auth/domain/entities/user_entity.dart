class UserEntity {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? avatar;
  final bool isActive;
  final bool acceptedTerms;
  final String? subscriptionPlan;
  final String? subscriptionStatus;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatar,
    required this.isActive,
    this.acceptedTerms = false,
    this.subscriptionPlan,
    this.subscriptionStatus,
  });

  /// true si tiene cualquier plan de pago activo (premium_user o agency)
  bool get isPremium => subscriptionPlan != null && subscriptionStatus == 'active';
}