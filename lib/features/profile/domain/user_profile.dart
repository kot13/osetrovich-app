class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.emailVerified,
    required this.pushEnabled,
    this.email,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      emailVerified: json['emailVerified'] as bool,
      pushEnabled: json['pushEnabled'] as bool,
    );
  }

  final String id;
  final String name;
  final String phone;
  final String? email;
  final bool emailVerified;
  final bool pushEnabled;

  UserProfile copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    bool? emailVerified,
    bool? pushEnabled,
    bool clearEmail = false,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: clearEmail ? null : (email ?? this.email),
      emailVerified: emailVerified ?? this.emailVerified,
      pushEnabled: pushEnabled ?? this.pushEnabled,
    );
  }
}

class ProfilePreferences {
  const ProfilePreferences({required this.pushEnabled});

  factory ProfilePreferences.fromJson(Map<String, dynamic> json) {
    return ProfilePreferences(pushEnabled: json['pushEnabled'] as bool);
  }

  final bool pushEnabled;
}
