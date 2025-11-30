import 'package:equatable/equatable.dart';
import 'user.dart';
import 'token_pair.dart';

class LoginResponse extends Equatable {
  final User user;
  final TokenPair tokens;

  const LoginResponse({required this.user, required this.tokens});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      tokens: TokenPair.fromJson(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'access_token': tokens.accessToken,
      'refresh_token': tokens.refreshToken,
    };
  }

  @override
  List<Object> get props => [user, tokens];
}
