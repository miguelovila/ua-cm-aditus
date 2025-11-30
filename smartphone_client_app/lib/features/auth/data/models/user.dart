import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int id;
  final String email;
  final String fullName;
  final String role;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      role: json['role'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'email': email, 'full_name': fullName, 'role': role};
  }

  @override
  List<Object> get props => [id, email, fullName, role];
}
