import 'package:equatable/equatable.dart';
import 'package:smartphone_client_app/features/auth/data/models/user.dart';

class Group extends Equatable {
  final int id;
  final String name;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? memberCount;
  final int? doorCount;
  final List<User>? members; // Optional, populated for admin detail views

  const Group({
    required this.id,
    required this.name,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.memberCount,
    this.doorCount,
    this.members,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    List<User>? membersList;
    if (json['members'] != null) {
      final membersJson = List<Map<String, dynamic>>.from(json['members']);
      membersList = membersJson.map((m) => User.fromJson(m)).toList();
    }

    return Group(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      memberCount: json['member_count'] as int?,
      doorCount: json['door_count'] as int?,
      members: membersList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (memberCount != null) 'member_count': memberCount,
      if (doorCount != null) 'door_count': doorCount,
      if (members != null) 'members': members!.map((m) => m.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    createdAt,
    updatedAt,
    memberCount,
    doorCount,
    members,
  ];
}
