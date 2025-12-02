class UserCreateRequest {
  final String email;
  final String password;
  final String? fullName;
  final String? role; // 'admin' or 'user', defaults to 'user' on backend

  const UserCreateRequest({
    required this.email,
    required this.password,
    this.fullName,
    this.role,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'email': email,
      'password': password,
    };

    if (fullName != null && fullName!.isNotEmpty) {
      json['full_name'] = fullName;
    }

    if (role != null && role!.isNotEmpty) {
      json['role'] = role;
    }

    return json;
  }
}
