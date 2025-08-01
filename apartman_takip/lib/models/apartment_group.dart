class ApartmentGroup {
  final String id;
  final String name;
  final String description;
  final String creatorId;
  final List<String> memberIds;
  final String inviteCode;
  final DateTime createdAt;

  ApartmentGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.creatorId,
    required this.memberIds,
    required this.inviteCode,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'creatorId': creatorId,
      'memberIds': memberIds,
      'inviteCode': inviteCode,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory ApartmentGroup.fromMap(Map<String, dynamic> map) {
    return ApartmentGroup(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      creatorId: map['creatorId'] ?? '',
      memberIds: List<String>.from(map['memberIds'] ?? []),
      inviteCode: map['inviteCode'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }
}
