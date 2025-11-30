import 'package:equatable/equatable.dart';

class Device extends Equatable {
  final int id;
  final int ownerId;
  final String name;
  final String publicKey;
  final DateTime createdAt;
  final DateTime lastUsedAt;

  const Device({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.publicKey,
    required this.createdAt,
    required this.lastUsedAt,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as int,
      ownerId: json['owner_id'] as int,
      name: json['name'] as String,
      publicKey: json['public_key'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastUsedAt: DateTime.parse(json['last_used_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'public_key': publicKey,
      'created_at': createdAt.toIso8601String(),
      'last_used_at': lastUsedAt.toIso8601String(),
    };
  }

  @override
  List<Object> get props => [
    id,
    ownerId,
    name,
    publicKey,
    createdAt,
    lastUsedAt,
  ];
}
