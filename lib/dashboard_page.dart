// lib/dashboard_page.dart (High-Fidelity Glassmorphism Refactor)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'project_detail_page.dart';
import 'global_finance_stats_page.dart';
import 'main.dart'; // Mengimport tokens & GlassContainer dari main.dart
import 'services/database_service.dart';
import 'services/report_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  late DatabaseService _dbService;
  late final Stream<QuerySnapshot> _projectsStream;
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    _dbService = DatabaseService();
    _projectsStream = _dbService.getAllProjects();
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text;
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showEditProjectDialog(String projectId, Map<String, dynamic> data) {
    final nameCtrl = TextEditingController(text: data['projectName']);
    final clientCtrl = TextEditingController(text: data['client']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF131B2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: kCardGlassBorder)),
        title: Text('Modify Node Spec', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: kTextPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: kTextPrimary),
              decoration: const InputDecoration(labelText: 'Project Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: clientCtrl,
              style: const TextStyle(color: kTextPrimary),
              decoration: const InputDecoration(labelText: 'Client Reference'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dismiss', style: TextStyle(color: kTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('projects').doc(projectId).update({
                'projectName': nameCtrl.text.trim(),
                'client': clientCtrl.text.trim(),
              });
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Update Node'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Menggunakan background dari MainNavigationWrapper
      body: StreamBuilder<QuerySnapshot>(
        stream: _projectsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kAccentColor));
          }

          final docs = snapshot.data?.docs ?? [];
          final projects = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            final name = (data['projectName'] ?? '').toString().toLowerCase();
            final client = (data['client'] ?? '').toString().toLowerCase();
            final query = _searchQuery.toLowerCase();
            return name.contains(query) || client.contains(query);
          }).toList();

          int totalProjects = projects.length;
          int activeProjects = projects.where((p) {
            final d = p.data() as Map<String, dynamic>? ?? {};
            return d['status'] != 'Completed';
          }).length;

          return LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 950;
              
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. TOP BAR COMPONENT
                    _buildTopBar(isDesktop),
                    const SizedBox(height: 32),
                    
                    // 2. DYNAMIC SPLIT SYSTEM LAYOUT
                    isDesktop 
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 6,
                              child: Column(
                                children: [
                                  _buildHeroSection(isDesktop, projects),
                                  const SizedBox(height: 32),
                                  _buildRecentActivityList(projects),
                                ],
                              ),
                            ),
                            const SizedBox(width: 32),
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: [
                                  _buildActiveAssetsCard(activeProjects, totalProjects),
                                  const SizedBox(height: 24),
                                  _buildQuickActionsGrid(),
                                ],
                              ),
                            )
                          ],
                        )
                      : Column(
                          children: [
                            _buildHeroSection(isDesktop, projects),
                            const SizedBox(height: 24),
                            _buildActiveAssetsCard(activeProjects, totalProjects),
                            const SizedBox(height: 24),
                            _buildRecentActivityList(projects),
                            const SizedBox(height: 24),
                            _buildQuickActionsGrid(),
                          ],
                        ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- COMPONENT WIDGETS ---

  Widget _buildTopBar(bool isDesktop) {
    final tabs = ['Executive Overview'];
    if (!isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overview',
                style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: kTextPrimary),
              ),
              Row(
                children: [
                  _buildNotificationIcon(),
                  const SizedBox(width: 12),
                  _buildThemeToggleIcon(),
                  const SizedBox(width: 12),
                  _buildProfileAvatar(),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSearchBar(isDesktop),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: List.generate(tabs.length, (index) {
            final bool isSelected = _activeTab == index;
            return GestureDetector(
              onTap: () => setState(() => _activeTab = index),
              child: Padding(
                padding: const EdgeInsets.only(right: 28.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tabs[index],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? kTextPrimary : kTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isSelected ? 24 : 0,
                      height: 2,
                      color: kAccentColor,
                    ),
                  ],
                ),
              ),
            );
          }),
        ),

        Row(
          children: [
            _buildSearchBar(isDesktop),
            const SizedBox(width: 16),
            _buildNotificationIcon(),
            const SizedBox(width: 16),
            _buildThemeToggleIcon(),
            const SizedBox(width: 16),
            _buildProfileAvatar(),
          ],
        )
      ],
    );
  }

  Widget _buildSearchBar(bool isDesktop) {
    return Container(
      width: isDesktop ? 260 : double.infinity,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kCardGlassBorder),
      ),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: kTextPrimary, fontSize: 13),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search, color: kTextSecondary, size: 18),
          hintText: 'Search...',
          hintStyle: GoogleFonts.plusJakartaSans(color: kTextSecondary, fontSize: 13),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon() {
    return InkWell(
      onTap: _showNotificationsSheet,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Icon(Icons.notifications_none_rounded, color: kTextPrimary.withValues(alpha: 0.8), size: 22),
      ),
    );
  }

  Widget _buildThemeToggleIcon() {
    return InkWell(
      onTap: () {
        themeNotifier.value = themeNotifier.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              themeNotifier.value == ThemeMode.dark ? 'Activated Dark Cyber Mode' : 'Activated Vibrant Light Mode',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
            duration: const Duration(seconds: 1),
            backgroundColor: const Color(0xFF0C2B23),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (context, currentMode, _) {
            final isDark = currentMode == ThemeMode.dark;
            return Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: kTextPrimary.withValues(alpha: 0.8),
              size: 22,
            );
          }
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return InkWell(
      onTap: () {
        mainTabNotifier.value = 4; // Switch to profile tab
      },
      borderRadius: BorderRadius.circular(16),
      child: const CircleAvatar(
        radius: 16,
        backgroundColor: kAccentColor,
        child: Icon(Icons.person, color: kBackgroundColor, size: 18),
      ),
    );
  }

  Widget _buildHeroSection(bool isDesktop, List<DocumentSnapshot> projects) {
    final totalCount = projects.length;
    final activeCount = projects.where((p) => (p.data() as Map<String, dynamic>?)?['status'] != 'Completed').length;

    return GlassContainer(
      height: null,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          // Bentuk Lengkungan Geometrik Estetik di bahagian kanan kad (Asymmetric Shape Overlay)
          Positioned(
            right: -20,
            top: -20,
            bottom: -20,
            child: AspectRatio(
              aspectRatio: 1.2,
              child: ClipPath(
                clipper: AsymmetricCurveClipper(),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white.withValues(alpha: 0.08), Colors.white.withValues(alpha: 0.01)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Icon(Icons.blur_circular_rounded, size: 140, color: kAccentColor.withValues(alpha: 0.15)),
                  ),
                ),
              ),
            ),
          ),
          
          // Teks Kandungan Dalam Banner
          Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'ACTIVE MARKET',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: kAccentColor, letterSpacing: 1.5),
                ),
                const SizedBox(height: 12),
                Text(
                  'Global Asset\nPerformance',
                  style: GoogleFonts.plusJakartaSans(fontSize: 30, fontWeight: FontWeight.w800, color: kTextPrimary, height: 1.2, letterSpacing: -0.5),
                ),
                const SizedBox(height: 12),
                Container(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: Text(
                    'Portfolio overview of $activeCount active nodes out of $totalCount assets. Review consolidated ROI, timeline deviations, and health logs.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kTextSecondary, height: 1.4),
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        ReportService.generateAndDownloadReport(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E384E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        textStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      child: const Text('Download Report'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GlobalFinanceStatsPage(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: kTextPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        textStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      child: const Text('View Details'),
                    )
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRecentActivityList(List<DocumentSnapshot> projects) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: kTextPrimary),
            ),
            TextButton(
              onPressed: () {},
              child: Text('View All', style: GoogleFonts.plusJakartaSans(color: kTextSecondary, fontSize: 13)),
            )
          ],
        ),
        const SizedBox(height: 12),
        if (projects.isEmpty)
          const GlassContainer(
            height: 140,
            child: Center(child: Text('No active pipelines found.', style: TextStyle(color: kTextSecondary))),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: projects.length > 5 ? 5 : projects.length,
            itemBuilder: (context, index) {
              final doc = projects[index];
              final data = doc.data() as Map<String, dynamic>? ?? {};
              final bool isActive = data['status'] != 'Completed';
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProjectDetailPage(
                          projectId: doc.id,
                          projectData: data,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(16),
                    borderRadius: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: (isActive ? kAccentColor : Colors.blue).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isActive ? Icons.swap_horizontal_circle_outlined : Icons.check_circle_outline_rounded,
                                  color: isActive ? kAccentColor : Colors.blue,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['projectName'] ?? 'Unnamed Stream',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: kTextPrimary),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Client: ${data['client'] ?? 'N/A'}",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kTextSecondary),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "${data['progress'] ?? 0}% Done",
                                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: kTextPrimary),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (isActive ? Colors.orange : kAccentColor).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isActive ? 'PROCESSED' : 'COMPLETED',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10, 
                                      fontWeight: FontWeight.w800, 
                                      color: isActive ? Colors.orange : kAccentColor,
                                      letterSpacing: 0.5
                                    ),
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit_note_rounded, color: kTextSecondary, size: 22),
                              onPressed: () => _showEditProjectDialog(doc.id, data),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }


  Widget _buildActiveAssetsCard(int active, int total) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ACTIVE ASSETS', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: kTextSecondary, letterSpacing: 1.0)),
              const SizedBox(height: 6),
              Text('$active / $total', style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: kTextPrimary)),
              const SizedBox(height: 6),
              Text('Stable currently monitoring', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: kTextSecondary)),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.layers_outlined, color: kTextPrimary, size: 22),
          )
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    final actions = [
      {'label': 'Add Project', 'icon': Icons.add_circle_outline_rounded},
      {'label': 'Transfer', 'icon': Icons.near_me_rounded},
      {'label': 'Allocation', 'icon': Icons.pie_chart_outline_rounded},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 64,
      ),
      itemBuilder: (context, index) {
        return InkWell(
          onTap: () {
            if (index == 0) {
              // Tukar tab terus ke halaman Add Project (Tab 2) tanpa membuka page bertindih
              mainTabNotifier.value = 2;
            } else if (index == 1) {
              _showTransferSheet();
            } else if (index == 2) {
              _showAllocationSheet();
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: GlassContainer(
            padding: EdgeInsets.zero,
            fillColor: Colors.white.withValues(alpha: 0.03),
            borderColor: kCardGlassBorder,
            borderRadius: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(actions[index]['icon'] as IconData, color: kTextPrimary, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    actions[index]['label'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11, 
                      fontWeight: FontWeight.w700, 
                      color: kTextPrimary
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) {
        return GlassContainer(
          borderRadius: 28,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'System Alerts & Logs',
                    style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: kTextPrimary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: kTextSecondary, size: 20),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const Divider(color: kCardGlassBorder, height: 24),
              _notificationItem(Icons.sync_rounded, 'Database Synchronized', 'Firestore connection healthy & fully synchronized with cloud node.', 'Just now'),
              const SizedBox(height: 12),
              _notificationItem(Icons.info_outline_rounded, 'System Update Configured', 'Premium glassmorphism layouts optimized for high-fidelity rendering.', '2h ago'),
              const SizedBox(height: 12),
              _notificationItem(Icons.people_alt_outlined, 'Node Activity Logged', 'Manager cluster updated org chart configuration for infrastructure.', '1d ago'),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _notificationItem(IconData icon, String title, String body, String time) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kCardGlassBorder.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kAccentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: kAccentColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: kTextPrimary)),
                const SizedBox(height: 4),
                Text(body, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kTextSecondary, height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(time, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: kTextSecondary)),
        ],
      ),
    );
  }

  void _showTransferSheet() {
    final amountCtrl = TextEditingController();
    String? selectedProjectFrom;
    String? selectedProjectTo;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: StreamBuilder<QuerySnapshot>(
            stream: _dbService.getAllProjects(),
            builder: (context, snapshot) {
              final projects = snapshot.data?.docs ?? [];
              return GlassContainer(
                borderRadius: 28,
                padding: const EdgeInsets.all(24),
                child: StatefulBuilder(
                  builder: (context, setStateDialog) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Transfer Asset Budget', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: kTextPrimary)),
                        const Divider(color: kCardGlassBorder, height: 24),
                        Text('TRANSFER FROM', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: kTextSecondary)),
                        Theme(
                          data: Theme.of(context).copyWith(canvasColor: const Color(0xFF151D30)),
                          child: DropdownButtonFormField<String>(
                            dropdownColor: const Color(0xFF151D30),
                            value: selectedProjectFrom,
                            hint: Text('Select Source Project', style: GoogleFonts.plusJakartaSans(color: kTextSecondary, fontSize: 13)),
                            style: GoogleFonts.plusJakartaSans(color: kTextPrimary, fontSize: 14),
                            items: projects.map((doc) {
                              final name = doc['projectName'] ?? 'Unnamed';
                              return DropdownMenuItem<String>(
                                value: doc.id,
                                child: Text(name),
                              );
                            }).toList(),
                            onChanged: (val) => setStateDialog(() => selectedProjectFrom = val),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('TRANSFER TO', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: kTextSecondary)),
                        Theme(
                          data: Theme.of(context).copyWith(canvasColor: const Color(0xFF151D30)),
                          child: DropdownButtonFormField<String>(
                            dropdownColor: const Color(0xFF151D30),
                            value: selectedProjectTo,
                            hint: Text('Select Destination Project', style: GoogleFonts.plusJakartaSans(color: kTextSecondary, fontSize: 13)),
                            style: GoogleFonts.plusJakartaSans(color: kTextPrimary, fontSize: 14),
                            items: projects.map((doc) {
                              final name = doc['projectName'] ?? 'Unnamed';
                              return DropdownMenuItem<String>(
                                value: doc.id,
                                child: Text(name),
                              );
                            }).toList(),
                            onChanged: (val) => setStateDialog(() => selectedProjectTo = val),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('AMOUNT (RM)', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: kTextSecondary)),
                        TextField(
                          controller: amountCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: kTextPrimary),
                          decoration: InputDecoration(
                            hintText: 'Enter amount to transfer',
                            hintStyle: GoogleFonts.plusJakartaSans(color: kTextSecondary, fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (selectedProjectFrom == null || selectedProjectTo == null || amountCtrl.text.isEmpty) ? null : () async {
                              final double? amt = double.tryParse(amountCtrl.text);
                              if (amt == null || amt <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid transfer amount')));
                                return;
                              }
                              if (selectedProjectFrom == selectedProjectTo) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot transfer to the same project')));
                                return;
                              }

                              Navigator.pop(context);
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => const Center(child: CircularProgressIndicator(color: kAccentColor)),
                              );

                              try {
                                final db = FirebaseFirestore.instance;
                                final docFrom = await db.collection('projects').doc(selectedProjectFrom!).get();
                                final docTo = await db.collection('projects').doc(selectedProjectTo!).get();
                                final budgetFrom = (docFrom['budget'] ?? 0.0) as double;
                                final budgetTo = (docTo['budget'] ?? 0.0) as double;

                                if (budgetFrom < amt) {
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient budget in source project')));
                                  return;
                                }

                                await db.collection('projects').doc(selectedProjectFrom!).update({'budget': budgetFrom - amt});
                                await db.collection('projects').doc(selectedProjectTo!).update({'budget': budgetTo + amt});

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('✅ Transfer of RM $amt executed successfully.', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                                      backgroundColor: const Color(0xFF0C2B23),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                }
                              }
                            },
                            child: const Text('Execute Transfer'),
                          ),
                        ),
                      ],
                    );
                  }
                ),
              );
            }
          ),
        );
      }
    );
  }

  void _showAllocationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StreamBuilder<QuerySnapshot>(
          stream: _dbService.getAllProjects(),
          builder: (context, snapshot) {
            final projects = snapshot.data?.docs ?? [];
            double totalBudget = 0;
            for (var doc in projects) {
              totalBudget += (doc['budget'] ?? 0.0) as double;
            }

            return GlassContainer(
              borderRadius: 28,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Budget Allocations', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: kTextPrimary)),
                  const Divider(color: kCardGlassBorder, height: 24),
                  if (projects.isEmpty)
                    Center(child: Text('No projects found', style: GoogleFonts.plusJakartaSans(color: kTextSecondary)))
                  else ...[
                    Text('Total Portfolio Value: RM ${totalBudget.toStringAsFixed(2)}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: kAccentColor)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        itemCount: projects.length,
                        itemBuilder: (context, index) {
                          final doc = projects[index];
                          final double budget = (doc['budget'] ?? 0.0) as double;
                          final double percentage = totalBudget > 0 ? (budget / totalBudget) * 100 : 0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(doc['projectName'] ?? 'Unnamed', style: GoogleFonts.plusJakartaSans(color: kTextPrimary, fontWeight: FontWeight.w600)),
                                    Text('RM ${budget.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)', style: GoogleFonts.plusJakartaSans(color: kTextSecondary)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                LinearProgressIndicator(
                                  value: percentage / 100,
                                  color: kAccentColor,
                                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Dismiss'),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }
}

// --- CUSTOM CLIPPER UNTUK ASYMMETRIC OVERLAY SHAPE ---
class AsymmetricCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.moveTo(size.width * 0.3, 0);
    path.quadraticBezierTo(size.width * 0.1, size.height * 0.4, size.width * 0.2, size.height * 0.7);
    path.quadraticBezierTo(size.width * 0.28, size.height * 0.95, size.width * 0.6, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}