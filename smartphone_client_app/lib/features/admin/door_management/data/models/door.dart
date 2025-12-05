import 'package:equatable/equatable.dart';

class Door extends Equatable {
  final int id;
  final String name;
  final String? location;
  final String? description;
  final String? deviceId; // BLE MAC address
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Admin-specific counts (optional, populated in admin endpoints)
  final int? allowedUserCount;
  final int? allowedGroupCount;
  final int? exceptionUserCount;
  final int? exceptionGroupCount;

  const Door({
    required this.id,
    required this.name,
    this.location,
    this.description,
    this.deviceId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.allowedUserCount,
    this.allowedGroupCount,
    this.exceptionUserCount,
    this.exceptionGroupCount,
  });

  factory Door.fromJson(Map<String, dynamic> json) {
    return Door(
      id: json['id'] as int,
      name: json['name'] as String,
      location: json['location'] as String?,
      description: json['description'] as String?,
      deviceId: json['device_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      allowedUserCount: json['allowed_user_count'] as int?,
      allowedGroupCount: json['allowed_group_count'] as int?,
      exceptionUserCount: json['exception_user_count'] as int?,
      exceptionGroupCount: json['exception_group_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'description': description,
      'device_id': deviceId,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (allowedUserCount != null) 'allowed_user_count': allowedUserCount,
      if (allowedGroupCount != null) 'allowed_group_count': allowedGroupCount,
      if (exceptionUserCount != null)
        'exception_user_count': exceptionUserCount,
      if (exceptionGroupCount != null)
        'exception_group_count': exceptionGroupCount,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        location,
        description,
        deviceId,
        isActive,
        createdAt,
        updatedAt,
        allowedUserCount,
        allowedGroupCount,
        exceptionUserCount,
        exceptionGroupCount,
      ];
}
