// lib/new_reminder_page.dart (Premium Glassmorphic Trigger Provisioner)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart'; // Mengakses Design Tokens dan GlassContainer global
import 'services/notification_service.dart';
import 'widgets/app_background.dart';

class NewReminderPage extends StatefulWidget {
  final String projectId;
  final String? reminderId; // null bermaksud pendaftaran peringatan baru
  final Map<String, dynamic>? existingData;

  // Constructor untuk mencipta peringatan baharu
  const NewReminderPage({
    super.key,
    required this.projectId,
  })  : reminderId = null,
        existingData = null;

  // Named constructor untuk menyunting peringatan sedia ada
  const NewReminderPage.edit({
    super.key,
    required this.projectId,
    required this.reminderId,
    required this.existingData,
  });

  @override
  State<NewReminderPage> createState() => _NewReminderPageState();
}

enum RepeatFrequency { none, daily, weekly, monthly, every6Months, custom }
enum CustomRepeatUnit { day, month, year }

class _NewReminderPageState extends State<NewReminderPage> {
  final TextEditingController titleController = TextEditingController();
  DateTime selectedDateTime = DateTime.now();
  bool allDay = false;

  RepeatFrequency repeatFrequency = RepeatFrequency.none;

  // Parameter kawalan ulangan tersuai (Custom repeat state control)
  int customRepeatCount = 1;
  CustomRepeatUnit customRepeatUnit = CustomRepeatUnit.day;

  @override
  void initState() {
    super.initState();

    // Memuatkan data asal jika berada dalam fasa penyuntingan (Edit Manifest Mode)
    if (widget.existingData != null) {
      final data = widget.existingData!;
      titleController.text = data['title'] ?? '';
      var ts = data['dateTime'];
      if (ts is Timestamp) {
        selectedDateTime = ts.toDate();
      } else if (ts is DateTime) {
        selectedDateTime = ts;
      }
      allDay = data['allDay'] ?? false;
      repeatFrequency = RepeatFrequency.values.firstWhere(
        (e) => e.name == (data['repeatFrequency'] ?? 'none'),
        orElse: () => RepeatFrequency.none,
      );
      customRepeatCount = data['repeatCount'] ?? 1;
      if (data['repeatUnit'] != null) {
        customRepeatUnit = CustomRepeatUnit.values.firstWhere(
          (e) => e.name == data['repeatUnit'],
          orElse: () => CustomRepeatUnit.day,
        );
      }
    }
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (pickedDate != null && !allDay) {
      if (!context.mounted) return;
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDateTime),
      );
      if (pickedTime != null) {
        setState(() {
          selectedDateTime = DateTime(
            pickedDate.year, pickedDate.month, pickedDate.day,
            pickedTime.hour, pickedTime.minute,
          );
        });
      }
    } else if (pickedDate != null && allDay) {
      setState(() {
        selectedDateTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day);
      });
    }
  }

  // Barisan butang penetapan masa pantas premium
  Widget _quickTimeButton(String label, DateTime time) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedDateTime = time),
        child: GlassContainer(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: EdgeInsets.zero,
          height: 40,
          borderRadius: 12,
          fillColor: Colors.white.withValues(alpha: 0.02),
          borderColor: kCardGlassBorder.withValues(alpha: 0.5),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: kTextPrimary),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  // Modul pilihan ulangan berciri kontemporari kaca frosted nipis
  Widget _repeatOptionTile(RepeatFrequency freq, String label) {
    final bool isSelected = repeatFrequency == freq;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: GlassContainer(
        borderRadius: 14,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        fillColor: isSelected ? kAccentColor.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.01),
        borderColor: isSelected ? kAccentColor.withValues(alpha: 0.4) : kCardGlassBorder.withValues(alpha: 0.4),
        child: Row(
          children: [
            Transform.scale(
              scale: 0.9,
              child: Radio<RepeatFrequency>(
                value: freq,
                groupValue: repeatFrequency,
                activeColor: kAccentColor,
                onChanged: (RepeatFrequency? val) {
                  if (val != null) {
                    setState(() {
                      repeatFrequency = val;
                      if (val != RepeatFrequency.custom) {
                        customRepeatCount = 1;
                        customRepeatUnit = CustomRepeatUnit.day;
                      }
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, 
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? kTextPrimary : kTextSecondary
                ),
              ),
            ),
            
            // Konfigurasi Parameter Khas bagi Ulangan Tersuai (Custom Params Tracker)
            if (freq == RepeatFrequency.custom && isSelected)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kCardGlassBorder),
                    ),
                    child: TextFormField(
                      initialValue: customRepeatCount.toString(),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(color: kAccentColor, fontSize: 13, fontWeight: FontWeight.w700),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      onChanged: (val) {
                        int? v = int.tryParse(val);
                        if (v != null && v > 0) {
                          setState(() => customRepeatCount = v);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Theme(
                    data: Theme.of(context).copyWith(canvasColor: const Color(0xFF111827)),
                    child: DropdownButton<CustomRepeatUnit>(
                      value: customRepeatUnit,
                      isDense: true,
                      elevation: 0,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down_rounded, color: kTextSecondary, size: 20),
                      style: GoogleFonts.plusJakartaSans(color: kTextPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                      items: const [
                        DropdownMenuItem(value: CustomRepeatUnit.day, child: Text("Days")),
                        DropdownMenuItem(value: CustomRepeatUnit.month, child: Text("Months")),
                        DropdownMenuItem(value: CustomRepeatUnit.year, child: Text("Years")),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => customRepeatUnit = val);
                      },
                    ),
                  ),
                ],
              )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent, // Mengekalkan aliran warna visual cecair latar belakang utama
        appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kTextPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.reminderId == null ? 'New Trigger' : 'Edit Trigger Spec',
          style: GoogleFonts.plusJakartaSans(color: kTextPrimary, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // MAIN CONFIGURATION GLASS CARD BLOCK
                  GlassContainer(
                    borderRadius: 24,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Header Title Label
                        Text(
                          'REMINDER IDENTIFIER MANIFEST',
                          style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: kAccentColor, letterSpacing: 1.0),
                        ),
                        const SizedBox(height: 10),
                        
                        // Main Title Input field
                        TextField(
                          controller: titleController,
                          style: GoogleFonts.plusJakartaSans(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            hintText: 'Enter reminder trigger title...',
                            hintStyle: GoogleFonts.plusJakartaSans(color: kTextSecondary, fontSize: 14, fontWeight: FontWeight.w500),
                            prefixIcon: const Icon(Icons.notifications_none_rounded, color: kTextSecondary, size: 20),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // SCHEDULING TIME INTERACTIVE BOARD
                        Text(
                          'TIME DEPLOYMENT SPECIFICATION',
                          style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: kTextSecondary, letterSpacing: 1.0),
                        ),
                        const SizedBox(height: 10),
                        
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: kCardGlassBorder.withValues(alpha: 0.4)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: kAccentColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                                    child: const Icon(Icons.calendar_month_rounded, color: kAccentColor, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('EXECUTION TIMESTAMP', style: GoogleFonts.plusJakartaSans(fontSize: 9, color: kTextSecondary, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${_weekdayToString(selectedDateTime.weekday)}, ${selectedDateTime.day} ${_monthToString(selectedDateTime.month)}',
                                          style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: kTextPrimary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!allDay)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(10), border: Border.all(color: kCardGlassBorder)),
                                      child: Text(
                                        '${selectedDateTime.hour.toString().padLeft(2, '0')}:${selectedDateTime.minute.toString().padLeft(2, '0')}',
                                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: kAccentColor),
                                      ),
                                    ),
                                ],
                              ),
                              const Padding(padding: EdgeInsets.symmetric(vertical: 12.0), child: Divider(thickness: 0.5)),
                              
                              // Change Date trigger block
                              SizedBox(
                                width: double.infinity,
                                height: 42,
                                child: OutlinedButton.icon(
                                  onPressed: () => _selectDateTime(context),
                                  icon: const Icon(Icons.date_range_rounded, size: 16),
                                  label: Text('Modify Target Clock', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: kCardGlassBorder, width: 1.2),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    foregroundColor: kTextPrimary,
                                    backgroundColor: Colors.white.withValues(alpha: 0.01),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              // All Day Option Switch Row Toggle Component
                              Row(
                                children: [
                                  const Icon(Icons.all_inclusive_rounded, size: 16, color: kTextSecondary),
                                  const SizedBox(width: 8),
                                  Text("24-Hour Continuous Cycle", style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: kTextPrimary)),
                                  const Spacer(),
                                  Transform.scale(
                                    scale: 0.8,
                                    child: Switch(
                                      value: allDay,
                                      activeColor: kAccentColor,
                                      activeTrackColor: kAccentColor.withValues(alpha: 0.2),
                                      inactiveTrackColor: Colors.black45,
                                      onChanged: (val) => setState(() => allDay = val),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // QUICK MACRO SELECT BUTTONS TIME VALUES
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _quickTimeButton('+60 Min Node', DateTime.now().add(const Duration(hours: 1))),
                            _quickTimeButton('07:00 AM Shift', DateTime(selectedDateTime.year, selectedDateTime.month, selectedDateTime.day, 7, 0)),
                            _quickTimeButton('03:00 PM Shift', DateTime(selectedDateTime.year, selectedDateTime.month, selectedDateTime.day, 15, 0)),
                          ],
                        ),
                        
                        const Padding(padding: EdgeInsets.symmetric(vertical: 18.0), child: Divider(thickness: 0.5)),

                        // RECURRING PIPELINES ENGINE CONFIG
                        Text(
                          'TRIGGER REPETITION PARAMETERS',
                          style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: kTextSecondary, letterSpacing: 1.0),
                        ),
                        const SizedBox(height: 12),
                        _repeatOptionTile(RepeatFrequency.none, "Isolated Operation (Don't repeat)"),
                        _repeatOptionTile(RepeatFrequency.daily, "Daily Sync Loop"),
                        _repeatOptionTile(RepeatFrequency.weekly, "Weekly Core Evaluation"),
                        _repeatOptionTile(RepeatFrequency.monthly, "Monthly Asset Reporting"),
                        _repeatOptionTile(RepeatFrequency.custom, "Custom Trigger Sequence"),

                        const SizedBox(height: 32),

                        // BROADCAST AND DEPLOY ACTION FORM SAVE BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (titleController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Please enter a reminder title spec payload.', style: GoogleFonts.plusJakartaSans())),
                                );
                                return;
                              }
                              
                              final reminderData = {
                                "title": titleController.text,
                                "dateTime": Timestamp.fromDate(selectedDateTime),
                                "allDay": allDay,
                                "repeatFrequency": repeatFrequency.name,
                                "repeatCount": repeatFrequency == RepeatFrequency.custom ? customRepeatCount : 1,
                                "repeatUnit": repeatFrequency == RepeatFrequency.custom ? customRepeatUnit.name : null,
                                "completed": widget.existingData?['completed'] ?? false,
                                "createdAt": widget.reminderId == null
                                    ? FieldValue.serverTimestamp()
                                    : widget.existingData?['createdAt'] ?? FieldValue.serverTimestamp(),
                              };

                              final notificationService = NotificationService();
                              String? docId = widget.reminderId;

                              try {
                                if (widget.reminderId != null) {
                                  await notificationService.cancelNotification(widget.reminderId.hashCode);
                                  await FirebaseFirestore.instance
                                      .collection('projects').doc(widget.projectId)
                                      .collection('reminders').doc(widget.reminderId)
                                      .update(reminderData);
                                } else {
                                  final docRef = await FirebaseFirestore.instance
                                      .collection('projects').doc(widget.projectId)
                                      .collection('reminders').add(reminderData);
                                  docId = docRef.id;
                                }

                                // Melaksanakan aturan sistem pemetaan notifikasi automatik
                                if (titleController.text.isNotEmpty) {
                                  final title = titleController.text;
                                  final body = allDay
                                      ? 'System core active alarm grid (All Day)'
                                      : 'Operational reminder sequence cue: ${selectedDateTime.hour.toString().padLeft(2, '0')}:${selectedDateTime.minute.toString().padLeft(2, '0')}';

                                  final notificationId = docId?.hashCode ?? DateTime.now().millisecondsSinceEpoch;

                                  if (repeatFrequency == RepeatFrequency.none) {
                                    await notificationService.scheduleReminderNotification(
                                      id: notificationId,
                                      title: 'Uni-X Reminder: $title',
                                      body: body,
                                      scheduledDateTime: selectedDateTime,
                                      payload: widget.projectId,
                                    );
                                  } else {
                                    await notificationService.scheduleRecurringReminder(
                                      id: notificationId,
                                      title: 'Uni-X Loop Alert: $title',
                                      body: body,
                                      startDateTime: selectedDateTime,
                                      repeatFrequency: repeatFrequency.name,
                                      repeatCount: customRepeatCount,
                                      repeatUnit: customRepeatUnit.name,
                                      payload: widget.projectId,
                                    );
                                  }
                                }

                                if (context.mounted) {
                                  if (widget.reminderId != null) {
                                    Navigator.pop(context, true);
                                  } else {
                                    Navigator.pop(context);
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Pipeline breakdown fault: $e")));
                                }
                              }
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.save_rounded, size: 18),
                                const SizedBox(width: 8),
                                Text('Commit Trigger Log', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

  // --- KEKALKAN STRUKTUR BAHASA LALAI SISTEM BAHASA ANDA ---
  String _monthToString(int month) {
    const months = ['', 'Jan', 'Feb', 'Mac', 'Apr', 'Mei', 'Jun', 'Jul', 'Ogos', 'Sept', 'Okt', 'Nov', 'Dis'];
    return months[month];
  }

  String _weekdayToString(int weekday) {
    const days = ['', 'Isnin', 'Selasa', 'Rabu', 'Khamis', 'Jumaat', 'Sabtu', 'Ahad'];
    return days[weekday];
  }
}