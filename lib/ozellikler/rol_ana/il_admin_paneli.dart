import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'onaylarim_butonu.dart';

class IlAdminPaneli extends StatelessWidget {
  const IlAdminPaneli({super.key});

  Future<String> _rolGetir() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final u = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return (u.data() ?? const {})['role']?.toString() ?? 'İl Admin';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('İl Admin Paneli')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: FutureBuilder<String>(
                future: _rolGetir(),
                builder: (ctx, snap) {
                  final rol = snap.data ?? 'İl Admin';
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_city, size: 64),
                      const SizedBox(height: 12),
                      Text('Hoş geldin 👋', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text('Rolün: $rol', style: const TextStyle(color: Colors.black54)),
                      const SizedBox(height: 16),
                      OnaylarimButonu(role: rol),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}


