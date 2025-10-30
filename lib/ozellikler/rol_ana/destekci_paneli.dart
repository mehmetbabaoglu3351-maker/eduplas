import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DestekciPaneli extends StatelessWidget {
  const DestekciPaneli({super.key});

  Future<String> _rolGetir() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final u = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return (u.data() ?? const {})['role']?.toString() ?? 'Destekçi';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Destekçi Paneli')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: FutureBuilder<String>(
                future: _rolGetir(),
                builder: (ctx, snap) {
                  final rol = snap.data ?? 'Destekçi';
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite_outline, size: 64),
                      const SizedBox(height: 12),
                      Text('Hoş geldin 👋', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text('Rolün: $rol', style: const TextStyle(color: Colors.black54)),
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


