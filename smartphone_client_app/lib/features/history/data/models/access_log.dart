class AccessLog {
  final int id;
  final String action;
  final bool success;
  final String? failureReason;
  final String? deviceInfo;
  final String? ipAddress;
  final DateTime timestamp;
  final AccessLogUser? user;
  final AccessLogDoor? door;
  final AccessLogDevice? device;

  AccessLog({
    required this.id,
    required this.action,
    required this.success,
    this.failureReason,
    this.deviceInfo,
    this.ipAddress,
    required this.timestamp,
    this.user,
    this.door,
    this.device,
  });

  factory AccessLog.fromJson(Map<String, dynamic> json) {
    return AccessLog(
      id: json['id'],
      action: json['action'],
      success: json['success'],
      failureReason: json['failure_reason'],
      deviceInfo: json['device_info'],
      ipAddress: json['ip_address'],
      timestamp: DateTime.parse(json['timestamp']),
      user: json['user'] != null
          ? AccessLogUser.fromJson(json['user'])
          : null,
      door: json['door'] != null
          ? AccessLogDoor.fromJson(json['door'])
          : null,
      device: json['device'] != null
          ? AccessLogDevice.fromJson(json['device'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action,
      'success': success,
      'failure_reason': failureReason,
      'device_info': deviceInfo,
      'ip_address': ipAddress,
      'timestamp': timestamp.toIso8601String(),
      'user': user?.toJson(),
      'door': door?.toJson(),
      'device': device?.toJson(),
    };
  }
}

class AccessLogUser {
  final int id;
  final String email;
  final String fullName;

  AccessLogUser({
    required this.id,
    required this.email,
    required this.fullName,
  });

  factory AccessLogUser.fromJson(Map<String, dynamic> json) {
    return AccessLogUser(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
    };
  }
}

class AccessLogDoor {
  final int id;
  final String name;
  final String? location;

  AccessLogDoor({
    required this.id,
    required this.name,
    this.location,
  });

  factory AccessLogDoor.fromJson(Map<String, dynamic> json) {
    return AccessLogDoor(
      id: json['id'],
      name: json['name'],
      location: json['location'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
    };
  }
}

class AccessLogDevice {
  final int id;
  final String name;
  final int ownerId;

  AccessLogDevice({
    required this.id,
    required this.name,
    required this.ownerId,
  });

  factory AccessLogDevice.fromJson(Map<String, dynamic> json) {
    return AccessLogDevice(
      id: json['id'],
      name: json['name'],
      ownerId: json['owner_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'owner_id': ownerId,
    };
  }
}
