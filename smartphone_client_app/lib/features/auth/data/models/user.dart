import 'package:equatable/equatable.dart';
import 'package:smartphone_client_app/features/device/data/models/device.dart';
import 'package:smartphone_client_app/features/group/data/models/group.dart';

class User extends Equatable {
  final int id;
  final String email;
  final String fullName;
  final String role;
  final List<Device>? devices; // Optional, populated for admin detail views
  final List<Group>? groups; // Optional, populated for admin detail views

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.devices,
    this.groups,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    List<Device>? devicesList;
    if (json['devices'] != null) {
      final devicesJson = List<Map<String, dynamic>>.from(json['devices']);
      devicesList = devicesJson.map((d) => Device.fromJson(d)).toList();
    }

    List<Group>? groupsList;
    if (json['groups'] != null) {
      final groupsJson = List<Map<String, dynamic>>.from(json['groups']);
      groupsList = groupsJson.map((g) => Group.fromJson(g)).toList();
    }

    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      role: json['role'] as String,
      devices: devicesList,
      groups: groupsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      if (devices != null) 'devices': devices!.map((d) => d.toJson()).toList(),
      if (groups != null) 'groups': groups!.map((g) => g.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [id, email, fullName, role, devices, groups];
}
