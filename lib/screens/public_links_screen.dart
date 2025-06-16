import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Simple admin screen to manage public report links.
class PublicLinksScreen extends StatefulWidget {
  const PublicLinksScreen({super.key});

  @override
  State<PublicLinksScreen> createState() => _PublicLinksScreenState();
}

class _PublicLinksScreenState extends State<PublicLinksScreen> {
  late Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _future;

  @override
  void initState() {
    super.initState();
    _future = FirebaseFirestore.instance
        .collection('reports')
        .where('isFinalized', isEqualTo: true)
        .where('publicReportId', isGreaterThan: '')
        .get()
        .then((s) => s.docs);
  }

  Future<void> _revoke(String docId) async {
    await FirebaseFirestore.instance.collection('reports').doc(docId).update(
        {'publicReportId': FieldValue.delete(), 'publicViewLink': FieldValue.delete()});
    setState(() {
      _future = FirebaseFirestore.instance
          .collection('reports')
          .where('isFinalized', isEqualTo: true)
          .where('publicReportId', isGreaterThan: '')
          .get()
          .then((s) => s.docs);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Public Links')),
      body: FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.isEmpty) {
            return const Center(child: Text('No public links'));
          }
          return ListView(
            children: [
              for (final doc in snapshot.data!)
                ListTile(
                  title: Text(doc.id),
                  subtitle: Text(doc['publicViewLink'] ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: doc['publicViewLink'] ?? ''));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _revoke(doc.id),
                      ),
                    ],
                  ),
                )
            ],
          );
        },
      ),
    );
  }
}
