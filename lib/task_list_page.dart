// lib/task_list_page.dart (Premium Glassmorphic Task Console)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'task_detail_page.dart';
import 'main.dart'; // Mengakses Design Tokens dan GlassContainer global

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  int _selectedFilterIndex = 0;
  final List<String> _filterTabs = ['All Nodes', 'In Progress', 'Completed'];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: GlassContainer(
            width: 280,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline_rounded, color: kAccentColor, size: 32),
                const SizedBox(height: 16),
                Text(
                  "Authentication Required",
                  style: GoogleFonts.plusJakartaSans(color: kTextPrimary, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  "Please sign in to view assigned tasks.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(color: kTextSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent, // Diwajibkan lutsinar untuk mengekalkan ambient glow dari shell wrapper
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. CONSOLE APP BAR & HEADER SYSTEM
              _buildHeader(),
              const SizedBox(height: 24),

              // 2. PREMIUM FILTER CHIPS ROW
              _buildFilterTabs(),
              const SizedBox(height: 24),

              // 3. MAIN DATA PIPELINE STREAM
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('tasks')
                      .where('to', isEqualTo: user.uid)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    // Penanganan Ralat Firestore
                    if (snapshot.hasError) {
                      return Center(
                        child: GlassContainer(
                          padding: const EdgeInsets.all(20),
                          child: SelectableText(
                            "Pipeline Error: ${snapshot.error}\n\nVerify composite indices configuration.",
                            style: const TextStyle(color: kTextSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    // Keadaan Menunggu Data (Loading State)
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: kAccentColor),
                      );
                    }

                    final allTasks = snapshot.data?.docs ?? [];
                    
                    // Melakukan penapisan data local (Local Filtering Strategy) untuk kepantasan UI
                    final filteredTasks = allTasks.where((doc) {
                      final data = doc.data() as Map<String, dynamic>? ?? {};
                      final status = data['status'] ?? 'Pending';
                      
                      if (_selectedFilterIndex == 1) {
                        return status != 'Completed';
                      } else if (_selectedFilterIndex == 2) {
                        return status == 'Completed';
                      }
                      return true;
                    }).toList();

                    // Keadaan Data Kosong (Empty State Placements)
                    if (filteredTasks.isEmpty) {
                      return Center(
                        child: FadeInWorkspace(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.02),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: kCardGlassBorder),
                                ),
                                child: Icon(
                                  Icons.layers_clear_outlined, 
                                  size: 48, 
                                  color: kTextSecondary.withValues(alpha: 0.4)
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No active instances found", 
                                style: GoogleFonts.plusJakartaSans(color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.w700)
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Tasks under this segment will appear here.", 
                                style: GoogleFonts.plusJakartaSans(color: kTextSecondary, fontSize: 13)
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Komponen Senarai Utama (Task Grid View list)
                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: filteredTasks.length,
                      itemBuilder: (context, index) {
                        final doc = filteredTasks[index];
                        final data = doc.data() as Map<String, dynamic>;
                        data['id'] = doc.id; // Menyimpan ID dokumen task
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          child: _buildGlassTaskCard(data),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- SUB-WIDGET COMPONENTS ---

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "OPERATIONAL LOGS",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: kAccentColor,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Task Workspace",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: kTextPrimary,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(_filterTabs.length, (index) {
          final bool isSelected = _selectedFilterIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: InkWell(
              onTap: () => setState(() => _selectedFilterIndex = index),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.08) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? kCardGlassBorder : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Text(
                  _filterTabs[index],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? kTextPrimary : kTextSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGlassTaskCard(Map<String, dynamic> data) {
    // Pengurusan tarikh yang selamat
    String dateStr = "No Timestamp";
    if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
      final dt = (data['createdAt'] as Timestamp).toDate();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      dateStr = "${dt.day} ${months[dt.month - 1]} • ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    }

    final status = data['status'] ?? 'Pending';
    final bool isCompleted = status == 'Completed';
    final Color statusColor = isCompleted ? kAccentColor : Colors.amber;

    return GlassContainer(
      padding: EdgeInsets.zero, // Padding kosong supaya corak hiasan dalaman rapat ke tepi
      borderRadius: 20,
      child: Stack(
        children: [
          // Garisan Sisi Status Terbenam (Left Status Highlight Strip)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 5,
            child: Container(
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
              ),
            ),
          ),
          
          // Kandungan Inti Kad
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Ruang Sisi Kiri: Ikon Status Bergradien
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                  ),
                  child: Icon(
                    isCompleted ? Icons.task_alt_rounded : Icons.radar_rounded, 
                    color: statusColor, 
                    size: 22
                  ),
                ),
                const SizedBox(width: 18),

                // Ruang Tengah: Deskripsi Tugasan & Pemilik Asal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['task'] ?? 'Unspecified Operations',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700, 
                          color: kTextPrimary,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.person_outline_rounded, size: 12, color: kTextSecondary.withValues(alpha: 0.8)),
                          const SizedBox(width: 4),
                          Text(
                            "Origin: ${data['fromName'] ?? 'System Core'}", 
                            style: GoogleFonts.plusJakartaSans(color: kTextSecondary, fontSize: 12)
                          ),
                        ],
                      ),
                      
                      // Blok fail lampiran jika wujud (Attachment File Verification)
                      if (data['fileName'] != null && data['fileName'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: InlineAttachmentBadge(fileName: data['fileName'].toString()),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Ruang Kanan: Tarikh, Status Badge & Triggers Navigasi
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      dateStr, 
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: kTextSecondary, fontWeight: FontWeight.w500)
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => TaskDetailPage(taskData: data)
                        ));
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: kCardGlassBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isCompleted ? 'Verified' : 'Inspect',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11, 
                                fontWeight: FontWeight.w700, 
                                color: isCompleted ? kAccentColor : kTextPrimary
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.chevron_right_rounded, size: 14, color: isCompleted ? kAccentColor : kTextPrimary),
                          ],
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- SUB WIDGET UTILITI UNTUK BADGE LAMPIRAN ---
class InlineAttachmentBadge extends StatelessWidget {
  final String fileName;
  const InlineAttachmentBadge({super.key, required this.fileName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: kAccentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kAccentColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.file_present_rounded, size: 12, color: kAccentColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(color: kAccentColor, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// --- REUSABLE SIMPLE FADE IN WORKSPACE ANIMATION ANIMATION ---
class FadeInWorkspace extends StatelessWidget {
  final Widget child;
  const FadeInWorkspace({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(offset: Offset(0, 15 * (1.0 - value)), child: child),
        );
      },
      child: child,
    );
  }
}