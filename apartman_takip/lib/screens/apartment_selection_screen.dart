import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/apartment_group.dart';

class ApartmentSelectionScreen extends StatefulWidget {
  const ApartmentSelectionScreen({Key? key}) : super(key: key);

  @override
  State<ApartmentSelectionScreen> createState() =>
      _ApartmentSelectionScreenState();
}

class _ApartmentSelectionScreenState extends State<ApartmentSelectionScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  List<ApartmentGroup> _apartments = [];

  @override
  void initState() {
    super.initState();
    _loadApartments();
  }

  Future<void> _loadApartments() async {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      final apartments = await _firestoreService.getUserApartmentGroups(
        currentUser.uid,
      );
      setState(() {
        _apartments = apartments;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apartman/Ev Gruplarım'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadApartments();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _apartments.isEmpty
          ? _buildEmptyState()
          : _buildApartmentList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Davet kodu ile katılma ekranına git
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Davet kodu ile katılma yakında eklenecek'),
            ),
          );
        },
        child: const Icon(Icons.qr_code),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.apartment, size: 100, color: Colors.grey),
            const SizedBox(height: 24),
            const Text(
              'Henüz hiçbir gruba katılmamışsınız',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Yeni bir grup oluşturun veya davet kodu ile bir gruba katılın',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Yeni grup oluşturma
              },
              icon: const Icon(Icons.add),
              label: const Text('Yeni Grup Oluştur'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Davet kodu ile katılma
              },
              icon: const Icon(Icons.qr_code),
              label: const Text('Davet Kodu ile Katıl'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApartmentList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _apartments.length,
      itemBuilder: (context, index) {
        final apartment = _apartments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text(
                apartment.name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              apartment.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(apartment.description),
                const SizedBox(height: 4),
                Text(
                  '${apartment.memberIds.length} üye • Kod: ${apartment.inviteCode}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // TODO: Apartman detay ekranına git
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${apartment.name} seçildi')),
              );
            },
          ),
        );
      },
    );
  }
}
