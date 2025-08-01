enum RotationStatus {
  active,    // Aktif sıra
  completed, // Tamamlandı
  skipped,   // Atlandı
  overdue,   // Süresi geçti
}

class TaskRotation {
  final String id;
  final String taskId;
  final String apartmentId;
  final String currentUserId;  // Şu anki sıradaki kişi
  final List<String> memberOrder; // Sıra listesi
  final DateTime rotationStartDate; // Sıra başlangıç tarihi
  final DateTime? nextRotationDate; // Sonraki sıra tarihi
  final int intervalDays; // Kaç günde bir döner (7=haftalık)
  final RotationStatus status;
  final DateTime? completedAt;
  final String? completedByUserId;
  final int currentPosition; // Sırada hangi pozisyonda
  final String? notes;

  TaskRotation({
    required this.id,
    required this.taskId,
    required this.apartmentId,
    required this.currentUserId,
    required this.memberOrder,
    required this.rotationStartDate,
    this.nextRotationDate,
    this.intervalDays = 7, // Varsayılan haftalık
    this.status = RotationStatus.active,
    this.completedAt,
    this.completedByUserId,
    this.currentPosition = 0,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'apartmentId': apartmentId,
      'currentUserId': currentUserId,
      'memberOrder': memberOrder,
      'rotationStartDate': rotationStartDate.millisecondsSinceEpoch,
      'nextRotationDate': nextRotationDate?.millisecondsSinceEpoch,
      'intervalDays': intervalDays,
      'status': status.toString().split('.').last,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'completedByUserId': completedByUserId,
      'currentPosition': currentPosition,
      'notes': notes,
    };
  }

  factory TaskRotation.fromMap(Map<String, dynamic> map) {
    return TaskRotation(
      id: map['id'] ?? '',
      taskId: map['taskId'] ?? '',
      apartmentId: map['apartmentId'] ?? '',
      currentUserId: map['currentUserId'] ?? '',
      memberOrder: List<String>.from(map['memberOrder'] ?? []),
      rotationStartDate: DateTime.fromMillisecondsSinceEpoch(
        map['rotationStartDate'] ?? 0,
      ),
      nextRotationDate: map['nextRotationDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['nextRotationDate'])
          : null,
      intervalDays: map['intervalDays'] ?? 7,
      status: RotationStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => RotationStatus.active,
      ),
      completedAt: map['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'])
          : null,
      completedByUserId: map['completedByUserId'],
      currentPosition: map['currentPosition'] ?? 0,
      notes: map['notes'],
    );
  }

  // Sonraki sıradaki kişiyi hesapla
  String getNextUserId() {
    if (memberOrder.isEmpty) return currentUserId;
    int nextIndex = (currentPosition + 1) % memberOrder.length;
    return memberOrder[nextIndex];
  }

  // Sırada kaç gün kaldığını hesapla
  int getDaysUntilNextRotation() {
    if (nextRotationDate == null) return 0;
    final now = DateTime.now();
    final difference = nextRotationDate!.difference(now).inDays;
    return difference > 0 ? difference : 0;
  }

  // Sıranın süresi geçti mi?
  bool get isOverdue {
    if (nextRotationDate == null) return false;
    return DateTime.now().isAfter(nextRotationDate!) && status == RotationStatus.active;
  }
}
