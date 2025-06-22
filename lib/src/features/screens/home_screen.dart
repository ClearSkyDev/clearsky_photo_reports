import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';

import '../../app/app_theme.dart';
import '../../../models/simple_inspection_metadata.dart';
import '../../core/models/local_inspection.dart';
import '../../../services/offline_sync_service.dart';

/// Landing screen with project creation and upgrade prompts.
class HomeScreen extends StatefulWidget {
  final int freeReportsRemaining;
  final bool isSubscribed;

  const HomeScreen({
    super.key,
    required this.freeReportsRemaining,
    required this.isSubscribed,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedFilterIndex = 0; // 0 = All, 1 = Upcoming, 2 = Unscheduled

  final List<String> filters = const ['All', 'Upcoming', 'Unscheduled'];
  final Set<String> _syncing = {};

  void _handleCreateProject(BuildContext context) {
    Navigator.pushNamed(context, '/projectDetails');
  }

  void _handleUpgrade(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Upgrade Required'),
        content: const Text(
          'Please upgrade your account to continue using ClearSky.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _checkSubscription(BuildContext context) {
    if (widget.freeReportsRemaining <= 0 && !widget.isSubscribed) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Upgrade Needed'),
          content: const Text(
            'You have reached your free report limit. Upgrade to continue.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _handleUpgrade(context),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Upgrade',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      _handleCreateProject(context);
    }
  }

  Future<bool> _hasUnsynced(String id) async {
    final box = await Hive.openBox<LocalInspection>('inspections');
    final local = box.get(id) as LocalInspection?;
    return local != null && !local.isSynced;
  }

  Future<void> _syncProject(InspectionMetadata project) async {
    if (_syncing.contains(project.id)) return;
    setState(() => _syncing.add(project.id));
    await OfflineSyncService.syncInspection(project.id);
    if (mounted) setState(() => _syncing.remove(project.id));
  }

  Future<List<InspectionMetadata>> _loadProjects() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('inspections')
        .get();

    final projects = snapshot.docs
        .map((doc) => InspectionMetadata.fromMap(doc.id, doc.data()))
        .toList();

    // Keep fallback sorting by appointment date if positions are equal
    projects.sort((a, b) {
      final posCmp = a.position.compareTo(b.position);
      if (posCmp != 0) return posCmp;
      if (a.appointmentDate == null && b.appointmentDate == null) return 0;
      if (a.appointmentDate == null) return 1;
      if (b.appointmentDate == null) return -1;
      return a.appointmentDate!.compareTo(b.appointmentDate!);
    });

    return projects;
  }

  List<InspectionMetadata> _filteredProjects(List<InspectionMetadata> projects) {
    final now = DateTime.now();
    if (selectedFilterIndex == 1) {
      return projects
          .where((p) =>
              p.appointmentDate != null && p.appointmentDate!.isAfter(now))
          .toList();
    } else if (selectedFilterIndex == 2) {
      return projects.where((p) => p.appointmentDate == null).toList();
    }
    return projects;
  }

  Map<String, List<InspectionMetadata>> _groupProjectsByDate(
      List<InspectionMetadata> projects) {
    final Map<String, List<InspectionMetadata>> grouped = {
      'Today': [],
      'Tomorrow': [],
      'This Week': [],
      'Later': [],
      'Unscheduled': [],
    };

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final nextWeek = today.add(const Duration(days: 7));

    for (final project in projects) {
      final appt = project.appointmentDate;
      if (appt == null) {
        grouped['Unscheduled']!.add(project);
      } else {
        final apptDate = DateTime(appt.year, appt.month, appt.day);
        if (apptDate == today) {
          grouped['Today']!.add(project);
        } else if (apptDate == tomorrow) {
          grouped['Tomorrow']!.add(project);
        } else if (apptDate.isBefore(nextWeek)) {
          grouped['This Week']!.add(project);
        } else {
          grouped['Later']!.add(project);
        }
      }
    }

    return grouped;
  }

  Widget _buildProjectTile(InspectionMetadata project) {
    final isScheduled = project.appointmentDate != null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isScheduled
            ? Colors.white
            : Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isScheduled
              ? Colors.grey.shade300
              : Theme.of(context).colorScheme.primary,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: FutureBuilder<bool>(
        future: _hasUnsynced(project.id),
        builder: (context, snapshot) {
          final unsynced = snapshot.data ?? false;
          final syncing = _syncing.contains(project.id);
          final status = syncing
              ? 'Syncing'
              : unsynced
                  ? 'Unsynced'
                  : 'Synced';
          return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            project.clientName.isNotEmpty ? project.clientName : 'Unnamed Project',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('Project #: ${project.projectNumber}'),
          Text('Claim #: ${project.claimNumber}'),
          if (project.appointmentDate != null)
            Text('Appt: ${DateFormat("MMM d, yyyy h:mm a").format(project.appointmentDate!)}'),
          if (project.appointmentDate == null)
            Text(
              'No Appointment Set',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 8),
          Text('Status: $status'),
          if (project.lastSynced != null && !unsynced)
            Text("Last synced: ${DateFormat('MMM d, h:mm a').format(project.lastSynced!)}"),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: syncing ? null : () => _syncProject(project),
              child: syncing
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Sync Now'),
            ),
          ),
        ],
          );
        },
      ),
    );
  }

  Future<void> _showEditProjectModal(
      BuildContext context, InspectionMetadata project) async {
    final clientController = TextEditingController(text: project.clientName);
    final claimController = TextEditingController(text: project.claimNumber);
    DateTime? appt = project.appointmentDate;
    final apptController = TextEditingController(
      text: appt != null ? DateFormat('yyyy-MM-dd').format(appt) : '',
    );

    Future<void> pickDate() async {
      final date = await showDatePicker(
        context: context,
        initialDate: appt ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (date != null) {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(appt ?? DateTime.now()),
        );
        if (time != null) {
          appt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
          apptController.text = DateFormat('yyyy-MM-dd').format(appt!);
        }
      }
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          return AlertDialog(
            title: const Text('Edit Inspection'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: clientController,
                    decoration: const InputDecoration(labelText: 'Client Name'),
                  ),
                  TextField(
                    controller: claimController,
                    decoration: const InputDecoration(labelText: 'Claim #'),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await pickDate();
                      setModalState(() {});
                    },
                    child: AbsorbPointer(
                      child: TextField(
                        controller: apptController,
                        decoration: const InputDecoration(labelText: 'Appointment Date'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  if (uid != null) {
                    final doc = FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .collection('inspections')
                        .doc(project.id);
                    final update = {
                      'clientName': clientController.text,
                      'claimNumber': claimController.text,
                    };
                    if (appt != null) {
                      final timestamp = Timestamp.fromDate(appt!);
                      update['appointmentDate'] = timestamp;
                    } else {
                      update['appointmentDate'] = FieldValue.delete();
                    }
                    await doc.update(update);
                  }
                  if (mounted) setState(() {});
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          );
        });
      },
    );
  }

  Widget _buildProjectGroup(
      BuildContext context, String groupName, List<InspectionMetadata> projects) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            groupName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: (oldIndex, newIndex) async {
            if (newIndex > oldIndex) newIndex -= 1;
            final item = projects.removeAt(oldIndex);
            projects.insert(newIndex, item);

            final uid = FirebaseAuth.instance.currentUser?.uid;
            if (uid != null) {
              for (int i = 0; i < projects.length; i++) {
                projects[i].position = i;
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('inspections')
                    .doc(projects[i].id)
                    .update({'position': i});
              }
            }

            setState(() {});
          },
          children: [
            for (int i = 0; i < projects.length; i++)
              Dismissible(
                key: ValueKey(projects[i].id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Project?'),
                      content: const Text(
                          'Are you sure you want to delete this inspection project?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (_) async {
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  if (uid != null) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .collection('inspections')
                        .doc(projects[i].id)
                        .delete();
                  }
                  projects.removeAt(i);
                  setState(() {});
                },
                child: GestureDetector(
                  key: ValueKey('${groupName}_$i'),
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/projectDetails',
                    arguments: projects[i],
                  ),
                  onLongPress: () =>
                      _showEditProjectModal(context, projects[i]),
                  child: _buildProjectTile(projects[i]),
                ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.clearSkyTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('ClearSky'),
        backgroundColor: AppTheme.clearSkyTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!widget.isSubscribed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.yellow.shade100,
              child: Text(
                'Free trial: ${widget.freeReportsRemaining} report${widget.freeReportsRemaining == 1 ? '' : 's'} remaining',
                style: TextStyle(
                  color: Colors.orange.shade900,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 20),
          Text(
            'ClearSky Photo Reports',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Text('Create professional inspection reports'),
          const SizedBox(height: 12),
          // Filter tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(filters.length, (index) {
                final isSelected = selectedFilterIndex == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: ChoiceChip(
                    label: Text(
                      filters[index],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => selectedFilterIndex = index);
                    },
                    selectedColor: Theme.of(context).colorScheme.primary,
                    backgroundColor: Colors.grey.shade200,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future: _loadProjects(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final projects = _filteredProjects(
                    snapshot.data as List<InspectionMetadata>);

                if (projects.isEmpty) {
                  return const Center(child: Text('No inspections found'));
                }

                final groupedProjects = _groupProjectsByDate(projects);

                return ListView(
                  padding: const EdgeInsets.only(bottom: 100),
                  children: groupedProjects.entries
                      .where((e) => e.value.isNotEmpty)
                      .map((e) =>
                          _buildProjectGroup(context, e.key, e.value))
                      .toList(),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _checkSubscription(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(Icons.add),
        label: const Text('New Inspection'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (i) {
          switch (i) {
            case 1:
              Navigator.pushNamed(context, '/capture');
              break;
            case 2:
              Navigator.pushNamed(context, '/history');
              break;
            case 3:
              Navigator.pushNamed(context, '/settings');
              break;
            default:
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: 'Camera'),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
