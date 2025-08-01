enum TaskStatus {
  pending, // Bekleyen
  completed, // Tamamlandı
  skipped, // Atlandı
  overdue, // Süresi geçti
}

class TaskAssignment {
  final String id;
  final String taskId;
  final String apartmentId;
  final String assignedUserId;
  final DateTime assignedDate;
  final DateTime dueDate;
  final TaskStatus status;
  final DateTime? completedAt;
  final String? completedByUserId;
  final String? notes;

  TaskAssignment({
    required this.id,
    required this.taskId,
    required this.apartmentId,
    required this.assignedUserId,
    required this.assignedDate,
    required this.dueDate,
    this.status = TaskStatus.pending,
    this.completedAt,
    this.completedByUserId,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'apartmentId': apartmentId,
      'assignedUserId': assignedUserId,
      'assignedDate': assignedDate.millisecondsSinceEpoch,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'status': status.toString().split('.').last,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'completedByUserId': completedByUserId,
      'notes': notes,
    };
  }

  factory TaskAssignment.fromMap(Map<String, dynamic> map) {
    return TaskAssignment(
      id: map['id'] ?? '',
      taskId: map['taskId'] ?? '',
      apartmentId: map['apartmentId'] ?? '',
      assignedUserId: map['assignedUserId'] ?? '',
      assignedDate: DateTime.fromMillisecondsSinceEpoch(
        map['assignedDate'] ?? 0,
      ),
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['dueDate'] ?? 0),
      status: TaskStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => TaskStatus.pending,
      ),
      completedAt: map['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'])
          : null,
      completedByUserId: map['completedByUserId'],
      notes: map['notes'],
    );
  }
}
