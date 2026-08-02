// lib/reminder_list_page.dart (Premium Glassmorphic Reminder Manifest)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'new_reminder_page.dart';
import 'services/notification_service.dart';
import 'main.dart'; // Mengakses Design Tokens dan GlassContainer global

class ReminderListPage extends StatefulWidget {
  final String projectId;

  const ReminderListPage({super.key, required this.projectId});

  @override
  State<ReminderListPage> createState() => _ReminderListPageState();
}

class _ReminderListPageState extends State<ReminderListPage> {
  late CollectionReference remindersRef;

  @override
  void initState() {
    super.initState();
    remindersRef = FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.projectId)
        .collection('reminders');
  }

  Future<void> _toggleCompleted(DocumentSnapshot doc, bool current) async {
    await remindersRef.doc(doc.id).update({'completed': !current});
  }

  Future<void> _deleteReminder(DocumentSnapshot doc) async {
    final notificationService = NotificationService();
    // Mengekalkan logik pembatalan notifikasi asal sedia ada anda
    await notificationService.cancelNotification(doc.id.hashCode);
    
    for (int i = 0; i < 10; i++) {
      await notificationService.cancelNotification(doc.id.hashCode + i);
    }
    
    await remindersRef.doc(doc.id).delete();
  }

  Future<void> _editReminder(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewReminderPage.edit(
          projectId: widget.projectId,
          reminderId: doc.id,
          existingData: data,
        ),
      ),
    );
    if (result != null && result is bool && result) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reminder log entry updated.', style: GoogleFonts.plusJakartaSans()),
            backgroundColor: const Color(0xFF1E293B),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Diwajibkan lutsinar untuk melihat ambient fluid dari wrapper parent
      body: StreamBuilder<QuerySnapshot>(
        stream: remindersRef.orderBy('dateTime', descending: false).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kAccentColor));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 350),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(offset: Offset(0, 10 * (1.0 - value)), child: child),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.02),
                        shape: BoxShape.circle,
                        border: Border.all(color: kCardGlassBorder),
                      ),
                      child: Icon(Icons.notifications_off_outlined, size: 48, color: kTextSecondary.withValues(alpha: 0.4)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No operational triggers monitored.',
                      style: GoogleFonts.plusJakartaSans(color: kTextSecondary, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            );
          }

          final reminders = snapshot.data!.docs;

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final doc = reminders[index];
              final data = doc.data() as Map<String, dynamic>;
              return _buildGlassReminderCard(doc, data);
            },
          );
        },
      ),
      floatingActionButton: _buildGlowingFab(),
    );
  }

  // --- CUSTOM MODULE COMPONENT FOR LOG CARD ---
  Widget _buildGlassReminderCard(DocumentSnapshot doc, Map<String, dynamic> data) {
    final DateTime dateTime = (data['dateTime'] as Timestamp).toDate();
    final bool allDay = data['allDay'] ?? false;
    final String title = data['title'] ?? 'Unspecified Broadcast';
    final bool completed = data['completed'] ?? false;
    
    // Pemformatan bulan korporat berteks
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final String timeString = allDay
        ? '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year} • All Day Schedule'
        : '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year} • ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        borderRadius: 20,
        // Dimalamkan kelegapan jika completed untuk menghasilkan hierarki status operasi
        fillColor: completed ? Colors.black.withValues(alpha: 0.25) : kCardGlass,
        borderColor: completed ? kCardGlassBorder.withValues(alpha: 0.3) : kCardGlassBorder,
        child: Row(
          children: [
            // Checkbox Pengesan Status (Neomorphic Glowing Checkbox Grid)
            Transform.scale(
              scale: 1.1,
              child: Checkbox(
                value: completed,
                activeColor: kAccentColor.withValues(alpha: 0.2),
                checkColor: kAccentColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                side: borderWithValues(completed),
                onChanged: (_) => _toggleCompleted(doc, completed),
              ),
            ),
            const SizedBox(width: 12),

            // Teks Inti Peringatan
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      decoration: completed ? TextDecoration.lineThrough : null,
                      decorationColor: kTextSecondary.withValues(alpha: 0.6),
                      color: completed ? kTextSecondary.withValues(alpha: 0.7) : kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.alarm_rounded, 
                        size: 13, 
                        color: completed ? kTextSecondary.withValues(alpha: 0.5) : kAccentColor.withValues(alpha: 0.8)
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          timeString,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            color: kTextSecondary, 
                            fontSize: 12,
                            fontWeight: completed ? FontWeight.w400 : FontWeight.w500
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Menu Operasi Segitiga (Actions Engine Popup Button)
            Theme(
              data: Theme.of(context).copyWith(
                popupMenuTheme: PopupMenuThemeData(
                  color: const Color(0xFF111827),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: kCardGlassBorder, width: 1),
                  ),
                ),
              ),
              child: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') _editReminder(doc);
                  if (value == 'delete') _deleteReminder(doc);
                },
                icon: Icon(Icons.more_horiz_rounded, color: kTextSecondary.withValues(alpha: 0.8), size: 20),
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'edit',
                    height: 42,
                    child: Row(
                      children: [
                        const Icon(Icons.edit_note_rounded, color: kAccentColor, size: 20),
                        const SizedBox(width: 12),
                        Text('Modify Node', style: GoogleFonts.plusJakartaSans(color: kTextPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(height: 1),
                  PopupMenuItem<String>(
                    value: 'delete',
                    height: 42,
                    child: Row(
                      children: [
                        const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 19),
                        const SizedBox(width: 12),
                        Text('Purge Log', style: GoogleFonts.plusJakartaSans(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- FLOATING ACTION BUTTON REFACTOR PATTERN ---
  Widget _buildGlowingFab() {
    return Container(
      width: 58, height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: kAccentColor.withValues(alpha: 0.25), 
            blurRadius: 14, 
            offset: const Offset(0, 6)
          ),
        ],
      ),
      child: Material(
        elevation: 0,
        color: kAccentColor,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NewReminderPage(projectId: widget.projectId),
              ),
            );
          },
          child: const Center(
            child: Icon(Icons.add_alert_rounded, color: kBackgroundColor, size: 24),
          ),
        ),
      ),
    );
  }
}

// --- HELPER UNTUK RETRIEVE SISI SEMPADAN CHECKBOX ---
BorderSide borderWithValues(bool completed) {
  return BorderSide(
    color: completed ? kAccentColor : kTextSecondary.withValues(alpha: 0.6), 
    width: 1.5
  );
}