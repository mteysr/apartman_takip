import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/apartment_group.dart';
import '../models/task.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'create_task_screen.dart';

class ApartmentDetailScreen extends StatefulWidget {
  final ApartmentGroup apartmentGroup;

  const ApartmentDetailScreen({
    Key? key,
    required this.apartmentGroup,
  }) : super(key: key);

  @override
  State<ApartmentDetailScreen> createState() => _ApartmentDetailScreenState();
}

class _ApartmentDetailScreenState extends State<ApartmentDetailScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  List<Task> _tasks = [];
  bool _isLoadingTasks = true;

  bool get _isCreator =>
      _authService.currentUser?.uid == widget.apartmentGroup.creatorId;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks =
        await _firestoreService.getApartmentTasks(widget.apartmentGroup.id);
    setState(() {
      _tasks = tasks;
      _isLoadingTasks = false;
    });
  }

  void _copyInviteCode() {
    Clipboard.setData(ClipboardData(text: widget.apartmentGroup.inviteCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Davet kodu kopyalandı!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _shareInviteCode() {
    _copyInviteCode();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.apartmentGroup.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareInviteCode,
          ),
          if (_isCreator)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Grup ayarları yakında eklenecek')),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGroupInfo(),
            const SizedBox(height: 24),
            _buildInviteCodeCard(),
            const SizedBox(height: 24),
            _buildMembersSection(),
            const SizedBox(height: 24),
            _buildTasksSection(),
          ],
        ),
      ),
      floatingActionButton: _isCreator
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateTaskScreen(
                      apartmentGroup: widget.apartmentGroup,
                    ),
                  ),
                );
                if (result != null) {
                  _loadTasks();
                }
              },
              child: const Icon(Icons.add_task),
            )
          : null,
    );
  }

  Widget _buildGroupInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue,
                  child: Text(
                    widget.apartmentGroup.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.apartmentGroup.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.apartmentGroup.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInfoChip(
                  icon: Icons.people,
                  label: '${widget.apartmentGroup.memberIds.length} Üye',
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  icon: Icons.calendar_today,
                  label: _formatDate(widget.apartmentGroup.createdAt),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.blue),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteCodeCard() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.qr_code, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Davet Kodu',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(
                      widget.apartmentGroup.inviteCode,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _copyInviteCode,
                  icon: const Icon(Icons.copy),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Bu kodu paylaşarak yeni üyeleri gruba davet edebilirsiniz',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Grup Üyeleri',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.apartmentGroup.memberIds.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final memberId = widget.apartmentGroup.memberIds[index];
              final isCreator = memberId == widget.apartmentGroup.creatorId;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isCreator ? Colors.amber : Colors.blue,
                  child: Icon(
                    isCreator ? Icons.star : Icons.person,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  'Üye ${index + 1}',
                  style: TextStyle(
                    fontWeight: isCreator ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  isCreator ? 'Grup Yöneticisi' : 'Üye',
                ),
                trailing: isCreator
                    ? const Icon(Icons.star, color: Colors.amber)
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTasksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Görevler',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (_isCreator)
              TextButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateTaskScreen(
                        apartmentGroup: widget.apartmentGroup,
                      ),
                    ),
                  );
                  if (result != null) {
                    _loadTasks();
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Ekle'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _isLoadingTasks
            ? const Center(child: CircularProgressIndicator())
            : _tasks.isEmpty
                ? _buildEmptyTasksCard()
                : _buildTasksList(),
      ],
    );
  }

  Widget _buildEmptyTasksCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(
              Icons.task_alt,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Henüz görev eklenmemiş',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isCreator
                  ? 'İlk görevi eklemek için + butonuna tıklayın'
                  : 'Grup yöneticisi görev ekleyene kadar bekleyin',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksList() {
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _tasks.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final task = _tasks[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: _getPriorityColor(task.priority),
              child: Icon(
                _getTaskIcon(task.name),
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              task.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildPriorityChip(task.priority),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(task.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: _isCreator
                ? PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Görev düzenleme yakında eklenecek')),
                        );
                      } else if (value == 'delete') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Görev silme yakında eklenecek')),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 16),
                            SizedBox(width: 8),
                            Text('Düzenle'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 16),
                            SizedBox(width: 8),
                            Text('Sil'),
                          ],
                        ),
                      ),
                    ],
                  )
                : const Icon(Icons.arrow_forward_ios),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${task.name} görevi seçildi')),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPriorityChip(int priority) {
    String label;
    Color color;

    switch (priority) {
      case 1:
      case 2:
        label = 'Yüksek';
        color = Colors.red;
        break;
      case 3:
        label = 'Orta';
        color = Colors.blue;
        break;
      case 4:
      case 5:
        label = 'Düşük';
        color = Colors.green;
        break;
      default:
        label = 'Orta';
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
      case 2:
        return Colors.red;
      case 3:
        return Colors.blue;
      case 4:
      case 5:
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  IconData _getTaskIcon(String taskName) {
    if (taskName.toLowerCase().contains('çöp')) {
      return Icons.delete_outline;
    } else if (taskName.toLowerCase().contains('temizlik') ||
        taskName.toLowerCase().contains('merdiven')) {
      return Icons.cleaning_services;
    } else if (taskName.toLowerCase().contains('bahçe') ||
        taskName.toLowerCase().contains('sula')) {
      return Icons.water_drop;
    } else if (taskName.toLowerCase().contains('kapıcı') ||
        taskName.toLowerCase().contains('güvenlik')) {
      return Icons.security;
    } else if (taskName.toLowerCase().contains('ortak')) {
      return Icons.home_work;
    } else {
      return Icons.task_alt;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
