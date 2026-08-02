// lib/finance_page.dart (Fixed Stream Thrashing & Premium Glassmorphic Refactor)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'graph_page.dart'; // Memastikan import sepadan dengan nama fail graf kewangan kau
import 'main.dart'; // Mengakses Design Tokens dan GlassContainer global

// Model Data Sedia-Produksi dengan Tipe Casting Selamat
class TransactionModel {
  final String id;
  final String type;
  final double amount;
  final DateTime date;
  final String detail;

  TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.detail,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      type: data['type'] ?? 'Expense',
      amount: (data['amount'] as num).toDouble(),
      detail: data['detail'] ?? '',
      date: (data['date'] is Timestamp)
          ? (data['date'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}

class FinanceTab extends StatefulWidget {
  final String projectId;
  final Map<String, dynamic> projectData;

  const FinanceTab({
    super.key,
    required this.projectId,
    required this.projectData,
  });

  @override
  State<FinanceTab> createState() => _FinanceTabState();
}

class _FinanceTabState extends State<FinanceTab> {
  // PENGALIRAN DATA MEMORI: Diisytiharkan sebagai Late Final untuk mengelakkan Stream Re-creation Bug
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _projectStream;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _financeStream;

  @override
  void initState() {
    super.initState();
    
    // BEST PRACTICE: Mengunci rujukan stream di dalam initState supaya tidak terbina semula di method build
    _projectStream = FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.projectId)
        .snapshots();

    _financeStream = FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.projectId)
        .collection('finance')
        .orderBy('date', descending: true)
        .snapshots();
  }

  void _addTransaction() async {
    final newTx = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: const TransactionForm(),
      ),
    );

    if (newTx != null && newTx is Map<String, dynamic>) {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .collection('finance')
          .add({
        "type": newTx['type'],
        "amount": newTx['amount'],
        "date": newTx['date'], 
        "detail": newTx['detail'],
        "createdAt": FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // NESTED REACTIVE ENGINE: Mengharmonikan aliran data projek dan sub-koleksi transaksi secara serentak
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _projectStream,
      builder: (ctx, projectSnapshot) {
        if (projectSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kAccentColor));
        }
        if (!projectSnapshot.hasData || !projectSnapshot.data!.exists) {
          return Center(child: Text('Project cluster database link offline.', style: GoogleFonts.plusJakartaSans(color: kTextSecondary)));
        }

        final projectData = projectSnapshot.data!.data()!;
        final double projectBudget = (projectData['budget'] is num) ? (projectData['budget'] as num).toDouble() : 0.0;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _financeStream,
          builder: (ctx, financeSnapshot) {
            if (financeSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: kAccentColor));
            }

            final docs = financeSnapshot.data?.docs ?? [];
            final List<TransactionModel> activeTransactions = docs.map((doc) => TransactionModel.fromFirestore(doc)).toList();

            // Penghitungan agregat masa-nyata (Real-time reactive calculation)
            double incomeSum = 0.0;
            double expenseSum = 0.0;
            for (var tx in activeTransactions) {
              if (tx.type == 'Claim') {
                incomeSum += tx.amount;
              } else if (tx.type == 'Expense') {
                expenseSum += tx.amount;
              }
            }

            final double balance = projectBudget + incomeSum - expenseSum;
            final double profit = incomeSum - expenseSum;

            return Stack(
              children: [
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Balance Card Component
                      _buildBalanceCard(balance, projectBudget),

                      // Metrics Summary Blocks Grid
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _summaryCard("Income Spec", incomeSum, const Color(0xFF10B981), Icons.arrow_downward_rounded),
                          const SizedBox(width: 8),
                          _summaryCard("Expense Purge", expenseSum, const Color(0xFFEF4444), Icons.arrow_upward_rounded),
                          const SizedBox(width: 8),
                          _summaryCard("Net Margin", profit, const Color(0xFF8B5CF6), Icons.account_balance_wallet_rounded),
                        ],
                      ),
                      const SizedBox(height: 32),

                      Text(
                        'Ledger Transactions',
                        style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: kTextPrimary, letterSpacing: -0.2),
                      ),
                      const SizedBox(height: 14),

                      // Transactions Render Switch
                      if (activeTransactions.isNotEmpty)
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: activeTransactions.length,
                          itemBuilder: (context, index) {
                            return _buildTransactionItem(activeTransactions[index]);
                          },
                        )
                      else
                        GlassContainer(
                          borderRadius: 20,
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Text("No transactional logs tracked inside this pool.", style: GoogleFonts.plusJakartaSans(color: kTextSecondary, fontSize: 13, fontStyle: FontStyle.italic)),
                          ),
                        ),

                      const SizedBox(height: 28),

                      // Navigasi Menuju Analitik Graf Kewangan (Graph Navigation Trigger)
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FinanceGraphPage(
                                  transactions: docs, // Menghantar data dokumen mentah ke fl_chart
                                  income: incomeSum,
                                  expenses: expenseSum,
                                  budget: projectBudget,
                                  balance: balance,
                                  profit: profit,
                                )),
                            );
                          },
                          child: GlassContainer(
                            borderRadius: 16,
                            fillColor: kAccentColor.withValues(alpha: 0.05),
                            borderColor: kAccentColor.withValues(alpha: 0.25),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.analytics_outlined, size: 20, color: kAccentColor),
                                const SizedBox(width: 10),
                                Text('Launch Financial Projections', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14, color: kAccentColor)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // FLOATING ACTION BUTTON LEDGER CONFIG
                Positioned(
                  bottom: 24,
                  right: 24,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: kAccentColor.withValues(alpha: 0.25), blurRadius: 14, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: FloatingActionButton.extended(
                      backgroundColor: kAccentColor,
                      foregroundColor: kBackgroundColor,
                      onPressed: _addTransaction,
                      icon: const Icon(Icons.add_card_rounded, size: 20),
                      label: Text("Add Log", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13)),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- SUB COMPONENT DESIGN LAYOUTS ---

  Widget _buildBalanceCard(double balance, double budget) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kAccentColor.withValues(alpha: 0.12), kCardGlass],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kAccentColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined, color: kAccentColor, size: 16),
              const SizedBox(width: 8),
              Text("AGGREGATE BALANCE", style: GoogleFonts.plusJakartaSans(color: kTextSecondary, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 10),
          Text("RM ${balance.toStringAsFixed(2)}", style: GoogleFonts.plusJakartaSans(color: kTextPrimary, fontWeight: FontWeight.w900, fontSize: 30, letterSpacing: -0.5)),
          const SizedBox(height: 6),
          Text("Initial Allocation Budget: RM ${budget.toStringAsFixed(2)}", style: GoogleFonts.plusJakartaSans(color: kTextSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(TransactionModel tx) {
    final bool isClaim = tx.type == 'Claim';
    final Color itemColor = isClaim ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        borderRadius: 20,
        borderColor: itemColor.withValues(alpha: 0.2),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: itemColor.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: Icon(isClaim ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded, color: itemColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx.detail, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: kTextPrimary, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('${tx.type} • ${tx.date.day.toString().padLeft(2, '0')}/${tx.date.month.toString().padLeft(2, '0')}/${tx.date.year}', style: GoogleFonts.plusJakartaSans(color: kTextSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Text("${isClaim ? '+' : '-'} RM ${tx.amount.toStringAsFixed(2)}", style: GoogleFonts.plusJakartaSans(color: itemColor, fontWeight: FontWeight.w800, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String title, double amount, Color color, IconData icon) {
    return Expanded(
      child: GlassContainer(
        borderRadius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
        borderColor: color.withValues(alpha: 0.25),
        fillColor: color.withValues(alpha: 0.02),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 14),
            ),
            const SizedBox(height: 8),
            Text(title.toUpperCase(), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: kTextSecondary, fontSize: 9, letterSpacing: 0.3)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                amount == 0 ? 'RM 0' : "RM ${amount.toStringAsFixed(0)}",
                style: GoogleFonts.plusJakartaSans(color: kTextPrimary, fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================= TRANSACTION MODAL INPUT FORM =======================
class TransactionForm extends StatefulWidget {
  const TransactionForm({super.key});
  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController detailCtrl = TextEditingController();
  final TextEditingController amountCtrl = TextEditingController();
  String? selectedType;
  DateTime? selectedDate = DateTime.now();

  @override
  void dispose() {
    detailCtrl.dispose();
    amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: kAccentColor,
              onPrimary: kBackgroundColor,
              surface: Color(0xFF0F1626),
              onSurface: kTextPrimary,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF0F1626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24)), side: BorderSide(color: kCardGlassBorder)),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    String dateHint = selectedDate == null
        ? "Select Date"
        : "${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year}";

    return Container(
      constraints: const BoxConstraints(maxWidth: 550),
      margin: const EdgeInsets.all(16),
      child: GlassContainer(
        borderRadius: 28,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text("Add Asset Log", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 20, color: kTextPrimary, letterSpacing: -0.5)),
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 12.0), child: Divider(thickness: 0.5)),
                
                _buildFieldLabel("Transaction Details / Memo"),
                _buildFormWrapper(
                  child: TextFormField(
                    controller: detailCtrl,
                    style: GoogleFonts.plusJakartaSans(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(hintText: "e.g. Server hosting maintenance purchase", prefixIcon: Icon(Icons.description_outlined, size: 18)),
                    validator: (val) => val == null || val.trim().isEmpty ? "Memo parameter is mandatory" : null,
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildFieldLabel("Transaction Flow Type"),
                _buildFormWrapper(
                  child: DropdownButtonFormField<String>(
                    value: selectedType,
                    dropdownColor: const Color(0xFF0F1626),
                    style: GoogleFonts.plusJakartaSans(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.swap_horiz_rounded, size: 18), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                    items: [
                      DropdownMenuItem(value: "Claim", child: Text("Claim (Income)", style: GoogleFonts.plusJakartaSans(color: const Color(0xFF10B981), fontWeight: FontWeight.w700))),
                      DropdownMenuItem(value: "Expense", child: Text("Expense (Payout)", style: GoogleFonts.plusJakartaSans(color: const Color(0xFFEF4444), fontWeight: FontWeight.w700))),
                    ],
                    onChanged: (val) => setState(() => selectedType = val),
                    validator: (val) => val == null ? "Flow route allocation required" : null,
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildFieldLabel("Amount Valuation"),
                _buildFormWrapper(
                  child: TextFormField(
                    controller: amountCtrl,
                    style: GoogleFonts.plusJakartaSans(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.w800),
                    decoration: const InputDecoration(hintText: "RM 0.00", prefixIcon: Icon(Icons.monetization_on_outlined, size: 18)),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (val) {
                      if (val == null || val.isEmpty) return "Valuation weight required";
                      if (double.tryParse(val) == null || double.parse(val) <= 0) return "Enter a valid numeric scale > 0";
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildFieldLabel("Execution Timestamp"),
                GestureDetector(
                  onTap: _pickDate,
                  child: AbsorbPointer(
                    child: _buildFormWrapper(
                      child: TextFormField(
                        style: GoogleFonts.plusJakartaSans(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: dateHint,
                          hintStyle: GoogleFonts.plusJakartaSans(color: kTextPrimary, fontWeight: FontWeight.w700),
                          prefixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
                        ),
                        validator: (val) => selectedDate == null ? "Timestamp execution marker required" : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                
                // BROADCAST SAVE TRANS BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        Navigator.of(context).pop({
                          "detail": detailCtrl.text.trim(),
                          "type": selectedType,
                          "amount": double.parse(amountCtrl.text),
                          "date": Timestamp.fromDate(selectedDate!),
                        });
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_circle_outline_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text("Broadcast Log", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String labelText) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 2),
      child: Text(
        labelText.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: kTextSecondary, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildFormWrapper({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kCardGlassBorder.withValues(alpha: 0.5)),
      ),
      child: child,
    );
  }
}