// lib/update_page.dart (Premium Glassmorphic Update Pipeline)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart'; // Mengakses Design Tokens dan GlassContainer global

class UpdatePage extends StatefulWidget {
  final String projectId;
  final Map<String, dynamic> projectData;

  const UpdatePage({
    super.key,
    required this.projectId,
    required this.projectData,
  });

  @override
  State<UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends State<UpdatePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController updateCtrl = TextEditingController();
  DateTime? selectedDate;
  String _currentUserName = '';

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserName();
  }

  Future<void> _fetchCurrentUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && doc.data() != null && mounted) {
          setState(() {
            _currentUserName = doc.data()!['username'] ??
                user.displayName ??
                user.email?.split('@')[0] ??
                '';
          });
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    updateCtrl.dispose();
    super.dispose();
  }

  String _formatDT(DateTime dt) {
    final d = dt.toLocal();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dd = d.day.toString().padLeft(2, '0');
    final mm = months[d.month - 1];
    final yyyy = d.year.toString();
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$dd $mm $yyyy • $hh:$min';
  }

  Widget _buildGlassInput({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kCardGlassBorder.withValues(alpha: 0.5)),
      ),
      child: child,
    );
  }

  InputDecoration _inputDecoration(String hint, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(color: kTextSecondary, fontWeight: FontWeight.w500, fontSize: 14),
      suffixIcon: suffix,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  void _showFormModal() {
    nameCtrl.text = _currentUserName;
    updateCtrl.clear();
    selectedDate = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 550),
          margin: const EdgeInsets.only(bottom: 16),
          child: GlassContainer(
            borderRadius: 28,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: StatefulBuilder(
              builder: (context, setModalState) => Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Modal Pipeline
                      Row(
                        children: [
                          Container(
                            width: 42, height: 42,
                            decoration: BoxDecoration(
                              color: kAccentColor.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                              border: Border.all(color: kAccentColor.withValues(alpha: 0.25)),
                            ),
                            child: const Icon(Icons.rocket_launch_rounded, color: kAccentColor, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'DISPATCH UPDATE',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: kAccentColor, letterSpacing: 1.0),
                                ),
                                Text(
                                  widget.projectData['projectName']?.toString() ?? 'Project Target',
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, color: kTextPrimary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Divider(thickness: 0.5),
                      ),

                      const _LabeledFieldLabel('Operator Identity'),
                      _buildGlassInput(
                        child: TextFormField(
                          controller: nameCtrl,
                          style: GoogleFonts.plusJakartaSans(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                          decoration: _inputDecoration('Enter identity or handle'),
                          validator: (val) => val == null || val.isEmpty ? 'Operator parameter required' : null,
                        ),
                      ),
                      const SizedBox(height: 16),

                      const _LabeledFieldLabel('Manifest Logs / Description'),
                      _buildGlassInput(
                        child: TextFormField(
                          controller: updateCtrl,
                          style: GoogleFonts.plusJakartaSans(color: kTextPrimary, fontSize: 14),
                          decoration: _inputDecoration('Describe system updates or modifications...'),
                          validator: (val) => val == null || val.isEmpty ? 'Update payload description required' : null,
                          minLines: 2,
                          maxLines: 4,
                        ),
                      ),
                      const SizedBox(height: 16),

                      const _LabeledFieldLabel('Timestamp scheduling'),
                      GestureDetector(
                        onTap: () async {
                          final initialDate = selectedDate ?? DateTime.now();
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: initialDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            if (!context.mounted) return;
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime: selectedDate != null
                                  ? TimeOfDay.fromDateTime(selectedDate!)
                                  : TimeOfDay.now(),
                            );
                            if (pickedTime != null) {
                              final combinedDateTime = DateTime(
                                pickedDate.year, pickedDate.month, pickedDate.day,
                                pickedTime.hour, pickedTime.minute,
                              );
                              setModalState(() {
                                selectedDate = combinedDateTime;
                              });
                            }
                          }
                        },
                        child: AbsorbPointer(
                          child: _buildGlassInput(
                            child: TextFormField(
                              style: GoogleFonts.plusJakartaSans(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                              decoration: _inputDecoration(
                                selectedDate == null ? 'Select transmission timestamp' : _formatDT(selectedDate!),
                                suffix: Icon(Icons.date_range_rounded, color: kAccentColor.withValues(alpha: 0.8), size: 18),
                              ),
                              validator: (val) => selectedDate == null ? 'Timestamp execution marker required' : null,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),
                      
                      // Submit Action Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate() && selectedDate != null) {
                              await FirebaseFirestore.instance
                                  .collection('projects')
                                  .doc(widget.projectId)
                                  .collection('updates')
                                  .add({
                                'name': nameCtrl.text.trim(),
                                'update': updateCtrl.text.trim(),
                                'date': Timestamp.fromDate(selectedDate!),
                                'fileUrl': '',
                                'fileName': '',
                                'projectName': widget.projectData['projectName'] ?? '',
                              });
                              if (context.mounted) Navigator.of(context).pop();
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.send_and_archive_rounded, size: 18),
                              const SizedBox(width: 8),
                              Text('Broadcast Update', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showUpdateDetailsWithComments(
      BuildContext context, String updateId, Map<String, dynamic> update) {
    final TextEditingController commentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 24, left: 16, right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 580),
            child: GlassContainer(
              borderRadius: 28,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Row Identity
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: kAccentColor.withValues(alpha: 0.15),
                          child: const Icon(Icons.engineering_rounded, color: kAccentColor, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(update['name'] ?? 'System Core',
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15, color: kTextPrimary)),
                              Text(
                                update['date'] is Timestamp
                                    ? _formatDT((update['date'] as Timestamp).toDate())
                                    : '',
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: kTextSecondary, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Divider(thickness: 0.5),
                    ),

                    // Log Update Body Text Container
                    Text('TRANSMISSION DATA', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: kAccentColor, letterSpacing: 1.0)),
                    const SizedBox(height: 6),
                    Text(
                      update['update'] ?? '', 
                      style: GoogleFonts.plusJakartaSans(color: kTextPrimary, fontSize: 14, height: 1.4)
                    ),
                    
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18.0),
                      child: Divider(thickness: 0.5),
                    ),

                    // Title Stream Threads
                    Text('TRANSMISSION STREAM THREADS', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: kTextSecondary, letterSpacing: 1.0)),
                    const SizedBox(height: 12),

                    // Nested Chat Comments System Realtime Pipeline
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('projects')
                          .doc(widget.projectId)
                          .collection('updates')
                          .doc(updateId)
                          .collection('comments')
                          .orderBy('createdAt')
                          .snapshots(),
                      builder: (context, snap) {
                        if (snap.hasError) return const Text('Error streaming logs');
                        if (snap.connectionState == ConnectionState.waiting) return const SizedBox();
                        if (!snap.hasData || snap.data!.docs.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Text('No verification notes stamped yet.', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kTextSecondary, fontStyle: FontStyle.italic)),
                          );
                        }
                        
                        return ListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: snap.data!.docs.map((commentDoc) {
                            final cmt = commentDoc.data()! as Map<String, dynamic>;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.02),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: kCardGlassBorder.withValues(alpha: 0.4)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(cmt['by'] ?? 'Anonymous',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: kAccentColor)),
                                  const SizedBox(height: 4),
                                  Text(cmt['comment'] ?? '',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kTextPrimary)),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Secure Input Chat Note Form
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kCardGlassBorder),
                      ),
                      child: TextFormField(
                        controller: commentCtrl,
                        style: GoogleFonts.plusJakartaSans(color: kTextPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Write an industrial verification note...',
                          labelStyle: GoogleFonts.plusJakartaSans(color: kTextSecondary, fontSize: 13),
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.arrow_circle_up_rounded, color: kAccentColor, size: 28),
                            onPressed: () async {
                              if (commentCtrl.text.trim().isEmpty) return;

                              final user = FirebaseAuth.instance.currentUser;
                              String userName = 'Anonymous';

                              if (user != null) {
                                final userDoc = await FirebaseFirestore.instance
                                    .collection('users').doc(user.uid).get();
                                if (userDoc.exists && userDoc.data() != null) {
                                  userName = userDoc.data()!['username'] ?? user.displayName ?? user.email?.split('@')[0] ?? 'Anonymous';
                                } else {
                                  userName = user.displayName ?? user.email?.split('@')[0] ?? 'Anonymous';
                                }
                              }

                              await FirebaseFirestore.instance
                                  .collection('projects')
                                  .doc(widget.projectId)
                                  .collection('updates')
                                  .doc(updateId)
                                  .collection('comments')
                                  .add({
                                'comment': commentCtrl.text.trim(),
                                'by': userName,
                                'createdAt': FieldValue.serverTimestamp(),
                              });
                              commentCtrl.clear();
                            },
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                        minLines: 1, maxLines: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('projects')
            .doc(widget.projectId)
            .collection('updates')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text("Pipeline Failure:\n${snapshot.error}", textAlign: TextAlign.center, style: const TextStyle(color: kTextSecondary)),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kAccentColor));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text('No operational updates tracked.', style: GoogleFonts.plusJakartaSans(color: kTextSecondary, fontWeight: FontWeight.w600)),
            );
          }

          final updates = snapshot.data!.docs;
          
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
            physics: const BouncingScrollPhysics(),
            itemCount: updates.length,
            itemBuilder: (context, i) {
              final doc = updates[i];
              final data = doc.data()! as Map<String, dynamic>;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => _showUpdateDetailsWithComments(context, doc.id, data),
                    child: GlassContainer(
                      padding: const EdgeInsets.all(18),
                      borderRadius: 20,
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: kAccentColor.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                              border: Border.all(color: kAccentColor.withValues(alpha: 0.2)),
                            ),
                            child: const Icon(Icons.analytics_outlined, color: kAccentColor, size: 18),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['name']?.toString().isNotEmpty == true ? data['name'] : 'System Core',
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15, color: kTextPrimary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  data['update'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kTextSecondary, height: 1.3),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (data['date'] != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  data['date'] is Timestamp ? _formatDT((data['date'] as Timestamp).toDate()) : data['date'].toString(),
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: kTextSecondary, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 4),
                                Icon(Icons.arrow_right_alt_rounded, color: kTextSecondary.withValues(alpha: 0.6), size: 16),
                              ],
                            )
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: _GradientFab(onTap: _showFormModal),
    );
  }
}

class _GradientFab extends StatelessWidget {
  final VoidCallback onTap;
  const _GradientFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60, height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: kAccentColor.withValues(alpha: 0.25), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: Material(
        elevation: 0,
        color: kAccentColor,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const Center(
            child: Icon(Icons.add_rounded, color: kBackgroundColor, size: 28),
          ),
        ),
      ),
    );
  }
}

class _LabeledFieldLabel extends StatelessWidget {
  final String text;
  const _LabeledFieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12.5, color: kTextPrimary.withValues(alpha: 0.9)),
      ),
    );
  }
}