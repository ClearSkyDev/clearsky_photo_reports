import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/saved_report.dart';
import '../models/invoice.dart';
import '../services/client_activity_service.dart';
import '../utils/export_utils.dart';
import '../screens/message_thread_screen.dart';
import '../services/invoice_service.dart';
import 'client_report_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class ClientDashboardScreen extends StatefulWidget {
  const ClientDashboardScreen({super.key});

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  String get _email => FirebaseAuth.instance.currentUser?.email ?? '';

  Future<List<SavedReport>> _loadReports() async {
    final snap = await FirebaseFirestore.instance
        .collection('reports')
        .where('clientEmail', isEqualTo: _email)
        .where('isFinalized', isEqualTo: true)
        .get();
    return snap.docs.map((d) => SavedReport.fromMap(d.data(), d.id)).toList();
  }

  Future<List<Invoice>> _loadInvoices() async {
    final snap = await FirebaseFirestore.instance
        .collection('invoices')
        .where('clientEmail', isEqualTo: _email)
        .get();
    return snap.docs.map((d) => Invoice.fromMap(d.data(), d.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Client Portal'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Reports'),
              Tab(text: 'Messages'),
              Tab(text: 'Invoices'),
              Tab(text: 'Settings'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildReports(),
            _buildMessages(),
            _buildInvoices(),
            _buildSettings(),
          ],
        ),
      ),
    );
  }

  Widget _buildReports() {
    return FutureBuilder<List<SavedReport>>(
      future: _loadReports(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final reports = snapshot.data!;
        if (reports.isEmpty) {
          return const Center(child: Text('No reports'));
        }
        return ListView.builder(
          itemCount: reports.length,
          itemBuilder: (c, i) {
            final r = reports[i];
            return Card(
              child: ListTile(
                title: Text(r.inspectionMetadata['propertyAddress'] ?? ''),
                subtitle: Text(r.inspectionMetadata['clientName'] ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () async {
                    await ClientActivityService().log('download_zip', reportId: r.id);
                    await exportFinalZip(r);
                  },
                ),
                onTap: () async {
                  await ClientActivityService().log('view_report', reportId: r.id);
                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClientReportScreen(reportId: r.id),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMessages() {
    return FutureBuilder<List<SavedReport>>(
      future: _loadReports(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final reports = snapshot.data!;
        if (reports.isEmpty) {
          return const Center(child: Text('No messages'));
        }
        return ListView(
          children: [
            for (final r in reports)
              Card(
                child: ListTile(
                  title: Text(r.inspectionMetadata['propertyAddress'] ?? ''),
                  onTap: () async {
                    await ClientActivityService().log('open_thread', reportId: r.id);
                    if (!mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MessageThreadScreen(reportId: r.id),
                      ),
                    );
                  },
                ),
              )
          ],
        );
      },
    );
  }

  Widget _buildInvoices() {
    return FutureBuilder<List<Invoice>>(
      future: _loadInvoices(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final invoices = snapshot.data!;
        if (invoices.isEmpty) {
          return const Center(child: Text('No invoices'));
        }
        return ListView.builder(
          itemCount: invoices.length,
          itemBuilder: (c, i) {
            final inv = invoices[i];
            return Card(
              child: ListTile(
                title: Text(inv.clientName),
                subtitle: Text(inv.dueDate.toLocal().toString().split(' ')[0]),
                trailing: inv.paymentUrl != null
                    ? TextButton(
                        onPressed: () async {
                          await ClientActivityService().log('pay_invoice', reportId: inv.reportId);
                          launchUrl(Uri.parse(inv.paymentUrl!));
                        },
                        child: const Text('Pay'),
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSettings() {
    final user = FirebaseAuth.instance.currentUser;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (user != null) Text(user.email ?? ''),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () async {
              await ClientActivityService().log('sign_out');
              await FirebaseAuth.instance.signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
