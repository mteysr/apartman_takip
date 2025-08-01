import 'package:flutter/material.dart';
import 'dart:math';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class CreateApartmentScreen extends StatefulWidget {
  const CreateApartmentScreen({Key? key}) : super(key: key);

  @override
  State<CreateApartmentScreen> createState() => _CreateApartmentScreenState();
}

class _CreateApartmentScreenState extends State<CreateApartmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  Future<void> _createApartment() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final currentUser = _authService.currentUser;
        if (currentUser == null) {
          throw Exception('Kullanıcı girişi gerekli');
        }

        final apartmentGroup = await _firestoreService.createApartmentGroup(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          creatorId: currentUser.uid,
        );

        setState(() {
          _isLoading = false;
        });

        if (apartmentGroup != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${apartmentGroup.name} grubu oluşturuldu!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(
            context,
            apartmentGroup,
          ); // Oluşturulan grubu geri döndür
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Grup Oluştur')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.group_add, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Grup Adı',
                  hintText: 'Örn: Güneş Apartmanı, Öğrenci Evi',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Grup adı gerekli';
                  }
                  if (value.trim().length < 3) {
                    return 'Grup adı en az 3 karakter olmalı';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  hintText: 'Örn: A Blok, Bahçelievler No: 45',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Açıklama gerekli';
                  }
                  return null;
                },
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
                      const Text(
                        'Grup oluşturduktan sonra diğer üyeleri davet edebilirsiniz',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.blue),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _createApartment,
                      icon: const Icon(Icons.add),
                      label: const Text('Grup Oluştur'),
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
}
