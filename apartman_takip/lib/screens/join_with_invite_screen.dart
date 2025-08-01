import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class JoinWithInviteScreen extends StatefulWidget {
  const JoinWithInviteScreen({Key? key}) : super(key: key);

  @override
  State<JoinWithInviteScreen> createState() => _JoinWithInviteScreenState();
}

class _JoinWithInviteScreenState extends State<JoinWithInviteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _inviteCodeController = TextEditingController();
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _joinGroup() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final currentUser = _authService.currentUser;
        if (currentUser == null) {
          throw Exception('Kullanıcı girişi gerekli');
        }

        final apartmentGroup = await _firestoreService.joinGroupByInviteCode(
          inviteCode: _inviteCodeController.text.trim(),
          userId: currentUser.uid,
        );

        setState(() {
          _isLoading = false;
        });

        if (apartmentGroup != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${apartmentGroup.name} grubuna katıldınız!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, apartmentGroup); // Başarı ile geri dön
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
        title: const Text('Davet Kodu ile Katıl'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.qr_code_scanner,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              const Text(
                'Grup Davet Kodu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Grup yöneticisinden aldığınız 6 haneli davet kodunu girin',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _inviteCodeController,
                decoration: const InputDecoration(
                  labelText: 'Davet Kodu',
                  hintText: 'ABC123',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.vpn_key),
                ),
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Davet kodu gerekli';
                  }
                  if (value.trim().length != 6) {
                    return 'Davet kodu 6 karakter olmalı';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Card(
                color: Colors.amber.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.amber,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Davet kodunu grup yöneticisinden alabilirsiniz',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.amber),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _joinGroup,
                      icon: const Icon(Icons.group_add),
                      label: const Text('Gruba Katıl'),
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
