// lib/project_detail_page.dart (Premium Glassmorphic Dashboard Console)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:age_calculator/age_calculator.dart';
import 'package:google_fonts/google_fonts.dart';

import 'update_page.dart';
import 'finance_page.dart';
import 'reminder_page.dart';
import 'main.dart'; // Mengakses Design Tokens dan GlassContainer global
import 'widgets/app_background.dart';

class ProjectDetailPage extends StatefulWidget {
  final String projectId;
  final Map<String, dynamic> projectData;

  const ProjectDetailPage({
    super.key,
    required this.projectId,
    required this.projectData,
  });

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

// --- DATA MODEL VENDOR ---
class Vendor {
  String companyName;
  String namePic;
  int phone;
  String location;

  Vendor({
    required this.companyName,
    required this.namePic,
    required this.phone,
    required this.location,
  });

  Map<String, dynamic> toMap() => {
        'companyName': companyName,
        'namePic': namePic,
        'phone': phone,
        'location': location,
      };

  static Vendor fromMap(Map<String, dynamic> map) => Vendor(
        companyName: map['companyName'] ?? '',
        namePic: map['namePic'] ?? '',
        phone: map['phone'] is int
            ? map['phone']
            : int.tryParse(map['phone']?.toString() ?? '') ?? 0,
        location: map['location'] ?? '',
      );
}

class _ProjectDetailPageState extends State<ProjectDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Vendor> vendors = [];
  late Map<String, dynamic> editableData;

  Map<String, dynamic> orgChart = {
    'manager': null,
    'leader': null,
    'operation': <String>[]
  };

  List<Map<String, dynamic>> userList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Memicu binaan semula untuk mengemas kini animasi ikon tab
    });
    editableData = Map.from(widget.projectData);

    if (widget.projectData['vendors'] != null &&
        widget.projectData['vendors'] is List) {
      vendors = (widget.projectData['vendors'] as List)
          .where((v) => v != null)
          .map((v) => Vendor.fromMap(Map<String, dynamic>.from(v)))
          .toList();
    }

    if (widget.projectData['orgChart'] != null) {
      final temp = Map<String, dynamic>.from(widget.projectData['orgChart']);
      temp['operation'] = temp['operation'] is List
          ? List<String>.from(temp['operation'])
          : <String>[];
      orgChart = temp;
    }
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    final userSnapshot =
        await FirebaseFirestore.instance.collection('users').get();
    setState(() {
      userList = userSnapshot.docs
          .map((doc) => {
                "uid": doc.id,
                "username": doc.data()['username'] ?? '',
                "displayName":
                    doc.data()['displayName'] ?? doc.data()['email'] ?? doc.id,
              })
          .toList();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    if (date is Timestamp) {
      DateTime d = date.toDate();
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    }
    if (date is DateTime) {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
    try {
      DateTime d = DateTime.parse(date.toString());
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return date.toString();
    }
  }

  String _calcPeriod(dynamic start, dynamic end) {
    try {
      DateTime startDate;
      DateTime endDate;
      if (start is Timestamp) {
        startDate = start.toDate();
      } else if (start is DateTime) {
        startDate = start;
      } else {
        startDate = DateTime.parse(start.toString());
      }
      
      if (end is Timestamp) {
        endDate = end.toDate();
      } else if (end is DateTime) {
        endDate = end;
      } else {
        endDate = DateTime.parse(end.toString());
      }
      final duration = AgeCalculator.age(startDate, today: endDate);
      return "${duration.years} yr, ${duration.months} mo, ${duration.days} day(s)";
    } catch (_) {
      return "N/A";
    }
  }

  Future<void> _launchDriveUrl() async {
    String url = widget.projectData['driveUrl'] ?? '';
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Drive URL manifest untracked.', style: GoogleFonts.plusJakartaSans())),
      );
      return;
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error launching communication path: $e', style: GoogleFonts.plusJakartaSans())),
      );
    }
  }

  // --- MODAL DIALOG AMANAH CARTA ORGANISASI ---
  Future<void> _showEditOrgChartDialog() async {
    Map<String, dynamic> tempChart = Map.from(orgChart);
    tempChart['operation'] = List<String>.from(tempChart['operation'] ?? []);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 550),
            margin: const EdgeInsets.only(bottom: 16),
            child: GlassContainer(
              borderRadius: 28,
              padding: const EdgeInsets.all(24),
              child: StatefulBuilder(
                builder: (context, setStateDialog) {
                  List<String> tempOps = List<String>.from(tempChart['operation']);

                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Structure Org Chart', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18, color: kTextPrimary)),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 12.0), child: Divider(thickness: 0.5)),
                        
                        _buildDropdownLabel('Project Manager Cluster'),
                        Theme(
                          data: Theme.of(context).copyWith(canvasColor: const Color(0xFF151D30)),
                          child: DropdownButtonFormField<String>(
                            value: tempChart['manager'],
                            isExpanded: true,
                            dropdownColor: const Color(0xFF151D30),
                            style: GoogleFonts.plusJakartaSans(color: kTextPrimary, fontSize: 14),
                            items: userList
                                .where((u) => ((u['username'] ?? '').isNotEmpty || (u['displayName'] ?? '').isNotEmpty))
                                .map((u) => DropdownMenuItem<String>(
                                      value: u['uid'],
                                      child: Text((u['username'] ?? '').isNotEmpty ? u['username'] : (u['displayName'] ?? '')),
                                    ))
                                .toList(),
                            onChanged: (val) => setStateDialog(() => tempChart['manager'] = val),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        _buildDropdownLabel('Operational Leader'),
                        Theme(
                          data: Theme.of(context).copyWith(canvasColor: const Color(0xFF151D30)),
                          child: DropdownButtonFormField<String>(
                            value: tempChart['leader'],
                            isExpanded: true,
                            dropdownColor: const Color(0xFF151D30),
                            style: GoogleFonts.plusJakartaSans(color: kTextPrimary, fontSize: 14),
                            items: userList
                                .where((u) => ((u['username'] ?? '').isNotEmpty || (u['displayName'] ?? '').isNotEmpty))
                                .map((u) => DropdownMenuItem<String>(
                                      value: u['uid'],
                                      child: Text((u['username'] ?? '').isNotEmpty ? u['username'] : (u['displayName'] ?? '')),
                                    ))
                                .toList(),
                            onChanged: (val) => setStateDialog(() => tempChart['leader'] = val),
                          ),
                        ),
                        const SizedBox(height: 18),
                        
                        Text('OPERATION NODES ALLOCATION', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 10, color: kTextSecondary, letterSpacing: 0.5)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8, runSpacing: 8,
                          children: userList.map((u) {
                            final selected = tempOps.contains(u['uid']);
                            final label = (u['username'] ?? '').isNotEmpty ? u['username'] : (u['displayName'] ?? '');
                            return FilterChip(
                              label: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
                              selected: selected,
                              selectedColor: kAccentColor.withValues(alpha: 0.15),
                              checkmarkColor: kAccentColor,
                              side: BorderSide(color: selected ? kAccentColor : kCardGlassBorder),
                              backgroundColor: Colors.transparent,
                              onSelected: (sel) {
                                setStateDialog(() {
                                  if (sel) {
                                    tempOps.add(u['uid']);
                                  } else {
                                    tempOps.remove(u['uid']);
                                  }
                                  tempChart['operation'] = tempOps;
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Dismiss', style: TextStyle(color: kTextSecondary))),
                            const SizedBox(width: 14),
                            ElevatedButton(
                              onPressed: () async {
                                orgChart = tempChart;
                                editableData['orgChart'] = orgChart;
                                await FirebaseFirestore.instance.collection('projects').doc(widget.projectId).update({'orgChart': orgChart});
                                setState(() {});
                                if (context.mounted) Navigator.pop(context);
                              },
                              child: const Text('Save Structure'),
                            ),
                          ],
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // --- MODAL DIALOG FORM VENDOR GLOW ---
  Future<void> _showVendorDialog({Vendor? vendor, int? idx}) async {
    final formKey = GlobalKey<FormState>();
    final companyCtrl = TextEditingController(text: vendor?.companyName ?? '');
    final nameCtrl = TextEditingController(text: vendor?.namePic ?? '');
    final phoneCtrl = TextEditingController(text: vendor?.phone.toString() ?? '');
    final locationCtrl = TextEditingController(text: vendor?.location ?? '');
    bool editing = vendor != null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 550),
          child: GlassContainer(
            borderRadius: 28,
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      editing ? 'Modify Vendor Spec' : 'Register New Vendor',
                      style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: kTextPrimary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: kTextSecondary, size: 20),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 10.0), child: Divider(thickness: 0.5)),
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDropdownLabel('Company Profile Name'),
                          TextFormField(
                            controller: companyCtrl,
                            style: const TextStyle(color: kTextPrimary, fontSize: 14),
                            decoration: const InputDecoration(hintText: 'Enter vendor enterprise identity', prefixIcon: Icon(Icons.business_rounded, size: 18)),
                            validator: (v) => v == null || v.isEmpty ? 'Manifest required' : null,
                          ),
                          const SizedBox(height: 14),
                          _buildDropdownLabel('Person In-Charge Handshake'),
                          TextFormField(
                            controller: nameCtrl,
                            style: const TextStyle(color: kTextPrimary, fontSize: 14),
                            decoration: const InputDecoration(hintText: 'Enter representative full name', prefixIcon: Icon(Icons.person_pin_rounded, size: 18)),
                            validator: (v) => v == null || v.isEmpty ? 'Identity parameter required' : null,
                          ),
                          const SizedBox(height: 14),
                          _buildDropdownLabel('Secure Direct Phone Node'),
                          TextFormField(
                            controller: phoneCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: kTextPrimary, fontSize: 14),
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(hintText: 'Enter contact phone line', prefixIcon: Icon(Icons.phone_rounded, size: 18)),
                            validator: (v) => v == null || v.isEmpty ? 'Phone connection value required' : null,
                          ),
                          const SizedBox(height: 14),
                          _buildDropdownLabel('Physical Grid Hub (Location)'),
                          TextFormField(
                            controller: locationCtrl,
                            style: const TextStyle(color: kTextPrimary, fontSize: 14),
                            decoration: const InputDecoration(hintText: 'Enter geo-location center Address', prefixIcon: Icon(Icons.location_on_rounded, size: 18)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    if (editing)
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            setState(() => vendors.removeAt(idx!));
                            _saveVendors();
                            Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                          child: Text('Purge Log', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            final newVendor = Vendor(
                              companyName: companyCtrl.text.trim(),
                              namePic: nameCtrl.text.trim(),
                              phone: int.tryParse(phoneCtrl.text.trim()) ?? 0,
                              location: locationCtrl.text.trim(),
                            );
                            setState(() {
                              if (editing) {
                                vendors[idx!] = newVendor;
                              } else {
                                vendors.add(newVendor);
                              }
                            });
                            _saveVendors();
                            Navigator.pop(context);
                          }
                        },
                        child: Text('Save Manifest', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveVendors() async {
    await FirebaseFirestore.instance.collection('projects').doc(widget.projectId).update({
      'vendors': vendors.map((v) => v.toMap()).toList(),
    });
  }

  // --- SUB COMPONENT WIDGETS LAYOUT ---
  Widget _buildOrgChartSection() {
    final chart = orgChart;

    String getUsername(String? uid) {
      if (uid != null && userList.isNotEmpty) {
        final user = userList.firstWhere((u) => u['uid'] == uid, orElse: () => {});
        return user['username']?.isNotEmpty == true ? user['username'] : (user['displayName'] ?? '');
      }
      return 'Unassigned Pool';
    }

    List<String> operationNames = [];
    if (chart['operation'] != null && (chart['operation'] as List).isNotEmpty) {
      operationNames = (chart['operation'] as List).map((uid) => getUsername(uid)).toList();
    }

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: kAccentColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.account_tree_outlined, color: kAccentColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text('Organization Core Chart', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, color: kTextPrimary)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.mode_edit_outline_rounded, color: kAccentColor, size: 18),
                onPressed: _showEditOrgChartDialog,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _orgRow(Icons.manage_accounts_rounded, 'Cluster Project Manager', getUsername(chart['manager'])),
          const SizedBox(height: 10),
          _orgRow(Icons.offline_bolt_rounded, 'Operational Leader', getUsername(chart['leader'])),
          const SizedBox(height: 10),
          _orgRow(Icons.hub_rounded, 'Assigned Execution Nodes', operationNames.isEmpty ? 'No nodes linked' : operationNames.join(', ')),
        ],
      ),
    );
  }

  Widget _orgRow(IconData icon, String role, String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kCardGlassBorder.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: kAccentColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(role.toUpperCase(), style: GoogleFonts.plusJakartaSans(fontSize: 9, color: kTextSecondary, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(name, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: kTextPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    final data = editableData;
    final startDate = data['startDate'];
    final endDate = data['endDate'];
    final periodStr = (startDate != null && endDate != null) ? _calcPeriod(startDate, endDate) : 'N/A';
    final projectName = data['projectName'] ?? 'Project Overview';
    final client = data['client'] ?? 'N/A';
    final budget = data['budget']?.toString() ?? 'N/A';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project core wrapper information card
          GlassContainer(
            borderRadius: 24,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                Container(
                  height: 4,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF3B82F6), kAccentColor, Color(0xFF7C3AED)]),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(projectName, style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w900, color: kTextPrimary, letterSpacing: -0.5)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.business_center_rounded, size: 14, color: kAccentColor),
                          const SizedBox(width: 8),
                          Text('Client Stream: $client', style: GoogleFonts.plusJakartaSans(color: kTextSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(child: _infoChip(Icons.play_arrow_rounded, 'Deployment', _formatDate(startDate))),
                          const SizedBox(width: 12),
                          Expanded(child: _infoChip(Icons.stop_rounded, 'Target Close', _formatDate(endDate))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _infoChip(Icons.timelapse_rounded, 'Lifecycle Period', periodStr),
                      if (budget != 'N/A') ...[
                        const SizedBox(height: 12),
                        _infoChip(Icons.account_balance_wallet_rounded, 'Allocated Budget', 'RM $budget'),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildOrgChartSection(),
          const SizedBox(height: 24),
          
          // Vendors Title Grid Pack Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Monitored Vendors', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, color: kTextPrimary)),
              TextButton.icon(
                onPressed: () => _showVendorDialog(),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 16, color: kAccentColor),
                label: Text('Link Vendor', style: GoogleFonts.plusJakartaSans(color: kAccentColor, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (vendors.isEmpty)
            GlassContainer(
              borderRadius: 20,
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text('No external vendors linked to token.', style: GoogleFonts.plusJakartaSans(color: kTextSecondary, fontSize: 13, fontStyle: FontStyle.italic)),
              ),
            ),
          ...vendors.asMap().entries.map((entry) {
            final idx = entry.key;
            final v = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: GlassContainer(
                borderRadius: 20,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: ListTile(
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: kAccentColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.business_rounded, color: kAccentColor, size: 20),
                  ),
                  title: Text(v.companyName.isNotEmpty ? v.companyName : 'Unnamed Enterprise', style: GoogleFonts.plusJakartaSans(color: kTextPrimary, fontWeight: FontWeight.w800, fontSize: 15)),
                  subtitle: Text('${v.namePic} • ${v.phone != 0 ? v.phone : "Unregistered Lines"}', style: GoogleFonts.plusJakartaSans(color: kTextSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                  trailing: IconButton(
                    icon: const Icon(Icons.tune_rounded, color: kAccentColor, size: 18),
                    onPressed: () => _showVendorDialog(vendor: v, idx: idx),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          
          // Google Drive Transmissions link button card
          if ((widget.projectData['driveUrl'] ?? '').toString().isNotEmpty)
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _launchDriveUrl,
                child: GlassContainer(
                  borderRadius: 18,
                  fillColor: kAccentColor.withValues(alpha: 0.06),
                  borderColor: kAccentColor.withValues(alpha: 0.2),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_done_rounded, color: kAccentColor, size: 24),
                      const SizedBox(width: 14),
                      Text('Access Shared Cloud Folder', style: GoogleFonts.plusJakartaSans(color: kAccentColor, fontWeight: FontWeight.w700, fontSize: 14)),
                      const Spacer(),
                      const Icon(Icons.open_in_new_rounded, color: kAccentColor, size: 16),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.01),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kCardGlassBorder.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: kAccentColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: GoogleFonts.plusJakartaSans(fontSize: 9, color: kTextSecondary, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: kTextPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectName = widget.projectData['projectName'] ?? 'Cluster Specification';

    final navIcons = [
      Icons.analytics_outlined,
      Icons.history_toggle_off_rounded,
      Icons.monetization_on_outlined,
      Icons.notifications_active_outlined,
    ];
    final navLabels = ['Overview', 'Logs', 'Finance', 'Triggers'];

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent, // Penting bagi memelihara fluid background shell utama
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          automaticallyImplyLeading: true,
          title: Text(projectName, style: GoogleFonts.plusJakartaSans(color: kTextPrimary, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5)),
          
          // CUSTOM PILL FLOATING NAVIGATION BOTTOM BAR TAB CONTROLLER
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(64),
            child: GlassContainer(
              height: 56,
              borderRadius: 28,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              fillColor: Colors.black.withValues(alpha: 0.3),
              borderColor: Colors.white.withValues(alpha: 0.12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(navIcons.length, (index) {
                  final isSelected = _tabController.index == index;
                  return GestureDetector(
                    onTap: () => setState(() => _tabController.index = index),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOutCubic,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? kAccentColor.withValues(alpha: 0.12) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? kAccentColor.withValues(alpha: 0.25) : Colors.transparent),
                      ),
                      child: Row(
                        children: [
                          Icon(navIcons[index], size: 18, color: isSelected ? kAccentColor : kTextSecondary),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            Text(
                              navLabels[index],
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: kAccentColor),
                            ),
                          ]
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(), // Mematikan tatalan leret (swipe navigation) demi integritas web
          children: [
            _buildDetailsTab(),
            UpdatePage(projectId: widget.projectId, projectData: widget.projectData),
            FinanceTab(projectId: widget.projectId, projectData: widget.projectData),
            ReminderListPage(projectId: widget.projectId),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 2),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: kTextSecondary, letterSpacing: 0.5),
      ),
    );
  }
}