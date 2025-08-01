import 'package:flutter/material.dart';
import '../models/apartment_group.dart';
import '../models/task.dart';
import '../models/task_rotation.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class RotationScreen extends StatefulWidget {
  final ApartmentGroup apartmentGroup;

  const RotationScreen({
    Key? key,
    required this.apartmentGroup,
  }) : super(key: key);

  @override
  State<RotationScreen> createState() => _RotationScreenState();
}

class _RotationScreenState extends State<RotationScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _rotationsWithTasks = [];
  Map<String, String> _userNames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRotations();
  }

  Future<void> _loadRotations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Kullanıcı isimlerini yükle
      final userNames = await _firestoreService
          .getUserDisplayNames(widget.apartmentGroup.memberIds);
      
      // Apartmanın sıralarını getir
      final rotations = await _firestoreService
          .getApartmentRotations(widget.apartmentGroup.id);

      List<Map<String, dynamic>> rotationsWithTasks = [];

      for (var rotation in rotations) {
        // Her sıra için görev bilgisini al
        final tasks = await _firestoreService
            .getApartmentTasks(widget.apartmentGroup.id);
        
        final task = tasks.firstWhere(
          (t) => t.id == rotation.taskId,
          orElse: () => Task(
            id: '',
            name: 'Görev bulunamadı',
            description: '',
            apartmentId: widget.apartmentGroup.id,
            createdAt: DateTime.now(),
          ),
        );

        rotationsWithTasks.add({
          'rotation': rotation,
          'task': task,
        });
      }

      setState(() {
        _userNames = userNames;
        _rotationsWithTasks = rotationsWithTasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.apartmentGroup.name} - Sıra Takip'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRotations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rotationsWithTasks.isEmpty
              ? _buildEmptyState()
              : _buildRotationsList(),
    );
  }

  Widget _buildEmptyState() {
    final bool _isCreator = _authService.currentUser?.uid == widget.apartmentGroup.creatorId;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.rotate_right, size: 100, color: Colors.grey),
            const SizedBox(height: 24),
            const Text(
              'Henüz sıra sistemi kurulmamış',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Mevcut görevler için sıra sistemi oluşturun',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            if (_isCreator) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _createRotationsForExistingTasks,
                icon: const Icon(Icons.autorenew),
                label: const Text('Sıra Sistemi Oluştur'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _createRotationsForExistingTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Mevcut görevleri al
      final tasks = await _firestoreService.getApartmentTasks(widget.apartmentGroup.id);
      
      int createdCount = 0;
      
      for (var task in tasks) {
        // Bu görev için zaten sıra sistemi var mı kontrol et
        final existingRotation = await _firestoreService.getTaskRotation(task.id);
        
        if (existingRotation == null) {
          // Sıra sistemi oluştur
          final rotation = await _firestoreService.createTaskRotation(
            taskId: task.id,
            apartmentId: widget.apartmentGroup.id,
            memberIds: widget.apartmentGroup.memberIds,
            intervalDays: 7,
          );
          
          if (rotation != null) {
            createdCount++;
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$createdCount görev için sıra sistemi oluşturuldu!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadRotations();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildRotationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _rotationsWithTasks.length,
      itemBuilder: (context, index) {
        final item = _rotationsWithTasks[index];
        final rotation = item['rotation'] as TaskRotation;
        final task = item['task'] as Task;
        
        return _buildRotationCard(rotation, task);
      },
    );
  }

  Widget _buildRotationCard(TaskRotation rotation, Task task) {
    final currentUserName = _userNames[rotation.currentUserId] ?? 'Bilinmeyen';
    final nextUserName = _userNames[rotation.getNextUserId()] ?? 'Bilinmeyen';
    final isCurrentUser = rotation.currentUserId == _authService.currentUser?.uid;
    final daysLeft = rotation.getDaysUntilNextRotation();
    final isOverdue = rotation.isOverdue;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      color: isCurrentUser 
          ? Colors.green.shade50 
          : (isOverdue ? Colors.red.shade50 : null),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getTaskIcon(task.name),
                  color: isCurrentUser ? Colors.green : Colors.blue,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        task.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Sıra bilgisi
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCurrentUser 
                    ? Colors.green.shade100 
                    : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        isCurrentUser ? Icons.person : Icons.schedule,
                        color: isCurrentUser ? Colors.green : Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isCurrentUser 
                              ? 'SİZİN SIRANIZ! 🎯'
                              : 'Şu anki sıra: $currentUserName',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isCurrentUser ? Colors.green : Colors.blue,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.timer, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        isOverdue 
                            ? 'Süre geçti! ⚠️'
                            : daysLeft > 0 
                                ? '$daysLeft gün kaldı'
                                : 'Bugün bitiyor',
                        style: TextStyle(
                          color: isOverdue ? Colors.red : Colors.grey,
                          fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Sonraki: $nextUserName',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (isCurrentUser) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _completeTask(rotation, task),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Tamamladım'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _skipTask(rotation, task),
                      icon: const Icon(Icons.skip_next),
                      label: const Text('Atla'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Sıra listesi önizlemesi
            const SizedBox(height: 12),
            _buildMemberOrderPreview(rotation),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberOrderPreview(TaskRotation rotation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sıra Listesi:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: rotation.memberOrder.asMap().entries.map((entry) {
            final index = entry.key;
            final userId = entry.value;
            final userName = _userNames[userId] ?? 'Bilinmeyen';
            final isCurrent = index == rotation.currentPosition;
            
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isCurrent ? Colors.blue : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${index + 1}. $userName',
                style: TextStyle(
                  fontSize: 12,
                  color: isCurrent ? Colors.white : Colors.black,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _getTaskIcon(String taskName) {
    if (taskName.toLowerCase().contains('çöp')) {
      return Icons.delete_outline;
    } else if (taskName.toLowerCase().contains('temizlik')) {
      return Icons.cleaning_services;
    } else if (taskName.toLowerCase().contains('bahçe')) {
      return Icons.water_drop;
    } else if (taskName.toLowerCase().contains('kapıcı')) {
      return Icons.security;
    } else {
      return Icons.task_alt;
    }
  }

  Future<void> _completeTask(TaskRotation rotation, Task task) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _buildCompletionDialog(task),
    );

    if (result != null) {
      final success = await _firestoreService.completeTaskRotation(
        rotationId: rotation.id,
        completedByUserId: _authService.currentUser!.uid,
        notes: result.isNotEmpty ? result : null,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${task.name} tamamlandı! Sıra sonraki kişiye geçti.'),
            backgroundColor: Colors.green,
          ),
        );
        _loadRotations();
      }
    }
  }

  Future<void> _skipTask(TaskRotation rotation, Task task) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _buildSkipDialog(task),
    );

    if (result != null) {
      final success = await _firestoreService.skipTaskRotation(
        rotationId: rotation.id,
        skippedByUserId: _authService.currentUser!.uid,
        reason: result.isNotEmpty ? result : null,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${task.name} atlandı. Sıra sonraki kişiye geçti.'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadRotations();
      }
    }
  }

  Widget _buildCompletionDialog(Task task) {
    final noteController = TextEditingController();
    
    return AlertDialog(
      title: Text('${task.name} Tamamlandı'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Bu görevi tamamladığınızı onaylıyor musunuz?'),
          const SizedBox(height: 16),
          TextField(
            controller: noteController,
            decoration: const InputDecoration(
              labelText: 'Not (isteğe bağlı)',
              hintText: 'Örn: Çöpler temiz bir şekilde çıkarıldı',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, noteController.text),
          child: const Text('Tamamlandı'),
        ),
      ],
    );
  }

  Widget _buildSkipDialog(Task task) {
    final reasonController = TextEditingController();
    
    return AlertDialog(
      title: Text('${task.name} Atla'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Bu sefer görevi yapamayanız mı? Sıra sonraki kişiye geçecek.'),
          const SizedBox(height: 16),
          TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              labelText: 'Sebep (isteğe bağlı)',
              hintText: 'Örn: Bu hafta şehir dışındayım',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, reasonController.text),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: const Text('Atla'),
        ),
      ],
    );
  }
}
