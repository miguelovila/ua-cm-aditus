class DoorCreateRequest {
  final String name;
  final String? location;
  final String? description;
  final String? deviceId;
  final bool isActive;

  const DoorCreateRequest({
    required this.name,
    this.location,
    this.description,
    this.deviceId,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'name': name,
      'is_active': isActive,
    };

    if (location != null && location!.isNotEmpty) {
      json['location'] = location;
    }
    if (description != null && description!.isNotEmpty) {
      json['description'] = description;
    }
    if (deviceId != null && deviceId!.isNotEmpty) {
      json['device_id'] = deviceId;
    }

    return json;
  }
}
