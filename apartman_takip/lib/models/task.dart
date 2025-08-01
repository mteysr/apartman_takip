class Task {
  final String id;
  final String name;
  final String description;
  final String apartmentId;
  final int priority; // 1-5 arası, 1 en yüksek
  final bool isActive;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.name,
    required this.description,
    required this.apartmentId,
    this.priority = 3,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'apartmentId': apartmentId,
      'priority': priority,
      'isActive': isActive,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      apartmentId: map['apartmentId'] ?? '',
      priority: map['priority'] ?? 3,
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }
}
