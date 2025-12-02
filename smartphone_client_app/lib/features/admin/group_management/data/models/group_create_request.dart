class GroupCreateRequest {
  final String name;
  final String? description;

  const GroupCreateRequest({required this.name, this.description});

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'name': name};

    if (description != null) {
      json['description'] = description;
    }

    return json;
  }
}
