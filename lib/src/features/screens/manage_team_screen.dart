import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/models/inspector_user.dart';

class ManageTeamScreen extends StatelessWidget {
  const ManageTeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final users = FirebaseFirestore.instance.collection('users');
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Team')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: users.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          return ListView(
            children: docs.map((d) {
              final user = InspectorUser.fromMap(d.id, d.data());
              return ListTile(
                title: Text(d.id),
                subtitle: DropdownButton<UserRole>(
                  value: user.role,
                  onChanged: (val) {
                    if (val != null) {
                      users.doc(user.uid).update({'role': val.name});
                    }
                  },
                  items: UserRole.values
                      .map((r) => DropdownMenuItem(
                            value: r,
                            child: Text(r.name),
                          ))
                      .toList(),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
