import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Admin screen to view homeowner signature status for all reports.
class SignatureStatusScreen extends StatefulWidget {
  const SignatureStatusScreen({super.key});

  @override
  State<SignatureStatusScreen> createState() => _SignatureStatusScreenState();
}

class _SignatureStatusScreenState extends State<SignatureStatusScreen> {
  String _filter = 'all';
  late Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    Query<Map<String, dynamic>> q =
        FirebaseFirestore.instance.collection('reports');
    if (_filter == 'pending') {
      q = q.where('signatureStatus', isEqualTo: 'pending');
    } else if (_filter == 'signed') {
      q = q.where('signatureStatus', isEqualTo: 'signed');
    } else if (_filter == 'declined') {
      q = q.where('signatureStatus', isEqualTo: 'declined');
    }
    _future = q.get().then((s) => s.docs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Signature Status')),
      body: Column(
        children: [
          DropdownButton<String>(
            value: _filter,
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All')),
              DropdownMenuItem(value: 'pending', child: Text('Pending')),
              DropdownMenuItem(value: 'signed', child: Text('Signed')),
              DropdownMenuItem(value: 'declined', child: Text('Declined')),
            ],
            onChanged: (val) {
              if (val == null) return;
              setState(() {
                _filter = val;
                _load();
              });
            },
          ),
          Expanded(
            child: FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
              future: _future,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data!.isEmpty) {
                  return const Center(child: Text('No reports'));
                }
                return ListView(
                  children: snapshot.data!
                      .map((d) => ListTile(
                            title: Text(d.id),
                            subtitle: Text(d['signatureStatus'] ?? 'none'),
                          ))
                      .toList(),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
