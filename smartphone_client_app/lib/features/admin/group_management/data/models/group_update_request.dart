class GroupUpdateRequest {
  final String? name;
  final String? description;

  const GroupUpdateRequest({this.name, this.description});

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (name != null) {
      json['name'] = name;
    }

    if (description != null) {
      json['description'] = description;
    }

    return json;
  }
}
