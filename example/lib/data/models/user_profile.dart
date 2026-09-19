/// Model representing a user registration and profile payload.
class UserProfile {
  const UserProfile({
    required this.name,
    required this.password,
  });

  final String name;
  final String password;

  Map<String, dynamic> toJson() => {
        'name': name,
        'password': password,
      };
}
