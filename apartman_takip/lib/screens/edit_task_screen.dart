import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/apartment_group.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class EditTaskScreen extends StatefulWidget {
  final Task task;

  const EditTaskScreen({
    Key? key,
    required this.task,
  }) : super(key: key);

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;
  int _selectedPriority = 3;
  String? _selectedUserId;
  Map<String, String> _userNames = {};
  bool _isLoadingUsers = false;
  ApartmentGroup? _apartmentGroup;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.task.name;
    _descriptionController.text = widget.task.description;
    _selectedPriority = widget.task.priority;
    _selectedUserId = widget.task.assignedUserId;
    _loadApartmentGroup();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadApartmentGroup() async {
    setState(() {
      _isLoadingUsers = true;
    });

    try {
      final apartmentGroup = await _firestoreService.getApartmentGroup(widget.task.apartmentId);
      
      if (apartmentGroup != null) {
        final userNames = await _firestoreService.getUserDisplayNames(apartmentGroup.memberIds);
        
        setState(() {
          _apartmentGroup = apartmentGroup;
          _userNames = userNames;
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingUsers = false;
      });
    }
  }

  Future<void> _updateTask() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final updatedTask = await _firestoreService.updateTask(
          taskId: widget.task.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          priority: _selectedPriority,
          assignedUserId: _selectedUserId, // Bu artık null olabilir
        );

        setState(() {
          _isLoading = false;
        });

        if (updatedTask != null && mounted) {
          String message = '${updatedTask.name} görevi güncellendi!';
          if (updatedTask.assignedUserId != null) {
            final assignedUserName = _userNames[updatedTask.assignedUserId] ?? 'Kullanıcı';
            message += ' ($assignedUserName kişisine atandı)';
          } else {
            message += ' (Atama kaldırıldı)';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, updatedTask);
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Görevi Düzenle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              _showDeleteConfirmDialog();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.edit_note,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Görev Adı',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.task),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Görev adı gerekli';
                    }
                    if (value.trim().length < 3) {
                      return 'Görev adı en az 3 karakter olmalı';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Görev Açıklaması',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Görev açıklaması gerekli';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Öncelik Seviyesi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<int>(
                        title: const Text('Düşük'),
                        subtitle: const Text('5'),
                        value: 5,
                        groupValue: _selectedPriority,
                        onChanged: (value) {
                          setState(() {
                            _selectedPriority = value!;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<int>(
                        title: const Text('Orta'),
                        subtitle: const Text('3'),
                        value: 3,
                        groupValue: _selectedPriority,
                        onChanged: (value) {
                          setState(() {
                            _selectedPriority = value!;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<int>(
                        title: const Text('Yüksek'),
                        subtitle: const Text('1'),
                        value: 1,
                        groupValue: _selectedPriority,
                        onChanged: (value) {
                          setState(() {
                            _selectedPriority = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Görev Atama Bölümü
                Card(
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.assignment_ind, color: Colors.orange),
                            const SizedBox(width: 8),
                            const Text(
                              'Görev Atama',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_isLoadingUsers)
                          const Center(child: CircularProgressIndicator())
                        else
                          _buildUserSelectionDropdown(),
                        if (widget.task.assignedDate != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Atama Tarihi: ${_formatDate(widget.task.assignedDate!)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        onPressed: _updateTask,
                        icon: const Icon(Icons.save),
                        label: const Text('Güncelle'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserSelectionDropdown() {
    if (_apartmentGroup == null) return const SizedBox();

    return DropdownButtonFormField<String>(
      value: _selectedUserId,
      decoration: const InputDecoration(
        labelText: 'Atanan Kişi',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.person),
        hintText: 'Atanacak kişiyi seçin (isteğe bağlı)',
      ),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('Atama yok'),
        ),
        ..._apartmentGroup!.memberIds.map((userId) {
          final isCreator = userId == _apartmentGroup!.creatorId;
          final userName = _userNames[userId] ?? 'Yükleniyor...';

          return DropdownMenuItem(
            value: userId,
            child: Text(
              userName + (isCreator ? ' (Yönetici)' : ''),
              style: TextStyle(
                fontWeight: isCreator ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ],
      onChanged: (value) {
        setState(() {
          _selectedUserId = value;
        });
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Görevi Sil'),
          content: Text('${widget.task.name} görevini silmek istediğinizden emin misiniz?'),
          actions: [
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Sil', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteTask();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteTask() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _firestoreService.deleteTask(widget.task.id);

      setState(() {
        _isLoading = false;
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Görev silindi!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, 'deleted');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Silme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
