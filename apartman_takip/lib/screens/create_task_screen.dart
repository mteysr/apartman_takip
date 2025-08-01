import 'package:flutter/material.dart';
import '../models/apartment_group.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class CreateTaskScreen extends StatefulWidget {
  final ApartmentGroup apartmentGroup;

  const CreateTaskScreen({
    Key? key,
    required this.apartmentGroup,
  }) : super(key: key);

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;
  int _selectedPriority = 3;
  bool _assignImmediately = false;
  String _assignmentType = 'automatic'; // 'automatic' or 'manual'
  String? _selectedUserId;
  Map<String, String> _userNames = {}; // userEmails yerine userNames
  bool _isLoadingUsers = false;

  // Önceden tanımlı görev şablonları
  final List<Map<String, dynamic>> _taskTemplates = [
    {
      'name': 'Çöp Çıkarma',
      'description': 'Binadan çöpleri topla ve dışarı çıkar',
      'icon': Icons.delete_outline,
      'color': Colors.red,
    },
    {
      'name': 'Merdiven Temizliği',
      'description': 'Ortak kullanım alanlarındaki merdivenleri temizle',
      'icon': Icons.cleaning_services,
      'color': Colors.blue,
    },
    {
      'name': 'Bahçe Sulama',
      'description': 'Ortak bahçe alanlarını sula',
      'icon': Icons.water_drop,
      'color': Colors.green,
    },
    {
      'name': 'Kapıcı Görevleri',
      'description': 'Kapı kontrolü ve güvenlik görevleri',
      'icon': Icons.security,
      'color': Colors.orange,
    },
    {
      'name': 'Ortak Alan Temizliği',
      'description': 'Lobi, asansör ve ortak alanların temizliği',
      'icon': Icons.home_work,
      'color': Colors.purple,
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadUserNames(); // _loadUserEmails yerine
  }

  void _selectTemplate(Map<String, dynamic> template) {
    setState(() {
      _nameController.text = template['name'];
      _descriptionController.text = template['description'];
    });
  }

  Future<void> _createTask() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final currentUser = _authService.currentUser;
        if (currentUser == null) {
          throw Exception('Kullanıcı girişi gerekli');
        }

        // Sadece grup sahibi görev oluşturabilir
        if (currentUser.uid != widget.apartmentGroup.creatorId) {
          throw Exception('Sadece grup yöneticisi görev oluşturabilir');
        }

        // Atama kişisini belirle
        String? finalAssignedUserId;
        if (_assignImmediately) {
          if (_assignmentType == 'manual') {
            finalAssignedUserId = _selectedUserId;
          } else if (_assignmentType == 'automatic') {
            // Otomatik atama algoritması - şimdilik ilk üyeyi seç
            // Gelecekte daha gelişmiş sıra sistemi eklenecek
            finalAssignedUserId = widget.apartmentGroup.memberIds.first;
          }
        }

        final task = await _firestoreService.createTask(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          apartmentId: widget.apartmentGroup.id,
          priority: _selectedPriority,
          assignedUserId: finalAssignedUserId, // Atama bilgisi eklendi
        );

        setState(() {
          _isLoading = false;
        });

        if (task != null && mounted) {
          String message = '${task.name} görevi oluşturuldu!';
          if (task.assignedUserId != null) {
            final assignedUserName = _userNames[task.assignedUserId] ?? 'Kullanıcı';
            message += ' ($assignedUserName kişisine atandı)';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, task);
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

  Future<void> _loadUserNames() async {
    setState(() {
      _isLoadingUsers = true;
    });

    final names = await _firestoreService
        .getUserDisplayNames(widget.apartmentGroup.memberIds);

    setState(() {
      _userNames = names;
      _isLoadingUsers = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Görev Oluştur'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.task_alt,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              const Text(
                'Görev Şablonları',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _taskTemplates.length,
                  itemBuilder: (context, index) {
                    final template = _taskTemplates[index];
                    return Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 12),
                      child: Card(
                        child: InkWell(
                          onTap: () => _selectTemplate(template),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  template['icon'],
                                  size: 32,
                                  color: template['color'],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  template['name'],
                                  style: const TextStyle(fontSize: 12),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Görev Adı',
                  hintText: 'Örn: Çöp Çıkarma',
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
                  hintText: 'Görevin detaylarını açıklayın',
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
              // Atama seçenekleri
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.assignment_ind,
                              color: Colors.orange),
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
                      CheckboxListTile(
                        title: const Text('Bu görevi hemen ata'),
                        subtitle: const Text(
                            'Görev oluşturulduktan sonra birine atansın'),
                        value: _assignImmediately,
                        onChanged: (value) {
                          setState(() {
                            _assignImmediately = value!;
                          });
                        },
                      ),
                      if (_assignImmediately) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Atama Türü:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        RadioListTile<String>(
                          title: const Text('Otomatik Sıra Sistemi'),
                          subtitle: const Text('Adil sıra ile otomatik atar'),
                          value: 'automatic',
                          groupValue: _assignmentType,
                          onChanged: (value) {
                            setState(() {
                              _assignmentType = value!;
                              _selectedUserId = null;
                            });
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('Manuel Atama'),
                          subtitle: const Text('Kendiniz kişi seçin'),
                          value: 'manual',
                          groupValue: _assignmentType,
                          onChanged: (value) {
                            setState(() {
                              _assignmentType = value!;
                            });
                          },
                        ),
                        if (_assignmentType == 'manual') ...[
                          const SizedBox(height: 8),
                          _buildUserSelectionDropdown(),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.apartmentGroup.name} grubuna yeni görev eklenecek',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _createTask,
                      icon: const Icon(Icons.add_task),
                      label: const Text('Görev Oluştur'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserSelectionDropdown() {
    if (_isLoadingUsers) {
      return const CircularProgressIndicator();
    }

    return DropdownButtonFormField<String>(
      value: _selectedUserId,
      decoration: const InputDecoration(
        labelText: 'Görevi atanacak kişi',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.person),
      ),
      items: widget.apartmentGroup.memberIds.map((userId) {
        final isCreator = userId == widget.apartmentGroup.creatorId;
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
      onChanged: (value) {
        setState(() {
          _selectedUserId = value;
        });
      },
      validator: _assignImmediately && _assignmentType == 'manual'
          ? (value) {
              if (value == null) {
                return 'Lütfen bir kişi seçin';
              }
              return null;
            }
          : null,
    );
  }
}
