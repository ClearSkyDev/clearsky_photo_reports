import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PhotoIntakeScreen extends StatelessWidget {
  const PhotoIntakeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Photo Intake')),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection('photos').get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No photos yet.'));
          }

          final photos = snapshot.data!.docs;
          return GridView.builder(
            itemCount: photos.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
            ),
            itemBuilder: (context, index) {
              final photo = photos[index];
              return Image.network(photo['url']);
            },
          );
        },
      ),
    );
  }
}
