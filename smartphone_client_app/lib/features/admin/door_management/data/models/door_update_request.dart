class DoorUpdateRequest {
  final String? name;
  final double? latitude;
  final double? longitude;
  final String? location;
  final String? description;
  final String? deviceId;
  final bool? isActive;

  const DoorUpdateRequest({
    this.name,
    this.latitude,
    this.longitude,
    this.location,
    this.description,
    this.deviceId,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (name != null && name!.isNotEmpty) {
      json['name'] = name;
    }
    if (latitude != null) {
      json['latitude'] = latitude;
    }
    if (longitude != null) {
      json['longitude'] = longitude;
    }
    if (location != null) {
      json['location'] = location;
    }
    if (description != null) {
      json['description'] = description;
    }
    if (deviceId != null) {
      json['device_id'] = deviceId;
    }
    if (isActive != null) {
      json['is_active'] = isActive;
    }

    return json;
  }
}
