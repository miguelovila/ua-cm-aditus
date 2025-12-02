class UserUpdateRequest {
  final String? email;
  final String? fullName;
  final String? role;

  const UserUpdateRequest({
    this.email,
    this.fullName,
    this.role,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (email != null && email!.isNotEmpty) {
      json['email'] = email;
    }

    if (fullName != null && fullName!.isNotEmpty) {
      json['full_name'] = fullName;
    }

    if (role != null && role!.isNotEmpty) {
      json['role'] = role;
    }

    return json;
  }
}
