// lib/finance_graph_page.dart (Premium Glassmorphic Financial Engine)

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart'; // Mengakses Design Tokens dan GlassContainer global
import 'widgets/app_background.dart';

class FinanceGraphPage extends StatefulWidget {
  final List<dynamic> transactions;
  final num income;
  final num expenses;
  final num budget;
  final num balance;
  final num profit;

  const FinanceGraphPage({
    super.key,
    required this.transactions,
    required this.income,
    required this.expenses,
    required this.budget,
    required this.balance,
    required this.profit,
  });

  @override
  State<FinanceGraphPage> createState() => _FinanceGraphPageState();
}

class _FinanceGraphPageState extends State<FinanceGraphPage> {
  int touchedIndex = -1;
  late double maxVal;

  @override
  void initState() {
    super.initState();
    maxVal = (widget.income.toDouble() > widget.expenses.toDouble()) 
             ? widget.income.toDouble() : widget.expenses.toDouble();
  }

  double _calculateInterval(double maxValue) {
      if (maxValue <= 0) return 1000; 
      final scale = (maxValue / 4.0);
      double step = 1.0;
      while (step * 10 < scale) {
        step *= 10;
      }
      if (scale / step >= 5) return step * 5;
      if (scale / step >= 2) return step * 2;
      return step;
  }

  @override
  Widget build(BuildContext context) {
    final double income = widget.income.toDouble();
    final double expenses = widget.expenses.toDouble();
    final double budget = widget.budget.toDouble();
    final double balance = widget.balance.toDouble();
    final double profit = widget.profit.toDouble();
    
    final double chartMaxY = (maxVal > 0) ? maxVal * 1.2 : 100;
    final double interval = _calculateInterval(chartMaxY);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent, // Diwajibkan lutsinar untuk mengekalkan cecair ambient wrapper utama
      appBar: AppBar(
        title: Text(
          "Financial Command Console", 
          style: GoogleFonts.plusJakartaSans(color: kTextPrimary, fontWeight: FontWeight.w900, letterSpacing: -0.5)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kTextPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. TOP SUMMARY ROWS OVERVIEW CHIPS
                  _buildSummaryRow(budget, balance, profit),
                  
                  const SizedBox(height: 24),
                  
                  // 2. PIE CHART SECTION (INCOME VS EXPENSES PROJECTIONS)
                  GlassContainer(
                    borderRadius: 24,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          'Yield vs Expenditure Stream',
                          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: kTextPrimary, letterSpacing: -0.2),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Proportional liquidity distribution breakdown',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: kTextSecondary, fontWeight: FontWeight.w500),
                        ),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 12.0), child: Divider(thickness: 0.5)),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 260,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 5,
                              centerSpaceRadius: 65,
                              startDegreeOffset: 270,
                              pieTouchData: PieTouchData(
                                touchCallback: (FlTouchEvent event, PieTouchResponse? response) {
                                  setState(() {
                                    if (!event.isInterestedForInteractions || response == null || response.touchedSection == null) {
                                      touchedIndex = -1;
                                      return;
                                    }
                                    touchedIndex = response.touchedSection!.touchedSectionIndex;
                                  });
                                },
                              ),
                              sections: (income + expenses == 0) 
                                  ? [_noDataPie()] 
                                  : _buildPieSections(income, expenses),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Indicator(color: Color(0xFF10B981), text: 'Income Stream'),
                            SizedBox(width: 28),
                            Indicator(color: Color(0xFFEF4444), text: 'Expenses Purge'),
                          ],
                        )
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 3. BAR CHART SECTION (SUMMARY COMPARISON DATABASES)
                  GlassContainer(
                    borderRadius: 24,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          'Pipeline Scale Metrics',
                          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: kTextPrimary, letterSpacing: -0.2),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Comparative ledger weight assessment',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: kTextSecondary, fontWeight: FontWeight.w500),
                        ),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 12.0), child: Divider(thickness: 0.5)),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 280,
                          child: BarChart(
                            BarChartData(
                              maxY: chartMaxY,
                              alignment: BarChartAlignment.spaceAround,
                              barGroups: [
                                _buildBarGroup(0, income, const Color(0xFF10B981), chartMaxY),
                                _buildBarGroup(1, expenses, const Color(0xFFEF4444), chartMaxY),
                              ],
                              gridData: FlGridData(
                                show: true,
                                horizontalInterval: interval,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: kCardGlassBorder.withValues(alpha: 0.3),
                                  strokeWidth: 0.8,
                                ),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 45,
                                    interval: interval,
                                    getTitlesWidget: (value, meta) {
                                      if (value == 0) return const SizedBox.shrink();
                                      String text = value >= 1000 
                                          ? "${(value/1000).toStringAsFixed(0)}K" 
                                          : value.toInt().toString();
                                      return Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: kTextSecondary, fontWeight: FontWeight.w600));
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      switch (value.toInt()) {
                                        case 0: return Padding(padding: const EdgeInsets.only(top: 10), child: Text("INCOME", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 10, color: kTextPrimary, letterSpacing: 0.5)));
                                        case 1: return Padding(padding: const EdgeInsets.only(top: 10), child: Text("EXPENSES", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 10, color: kTextPrimary, letterSpacing: 0.5)));
                                        default: return const SizedBox.shrink();
                                      }
                                    },
                                  ),
                                ),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              barTouchData: BarTouchData(
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipColor: (group) => const Color(0xFF0F1626),
                                  tooltipBorder: const BorderSide(color: kCardGlassBorder, width: 1),
                                  tooltipRoundedRadius: 10,
                                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                    return BarTooltipItem(
                                      'RM ${rod.toY.toStringAsFixed(0)}',
                                      GoogleFonts.plusJakartaSans(color: kTextPrimary, fontWeight: FontWeight.w800, fontSize: 13),
                                    );
                                  }
                                ),
                              ), 
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildSummaryRow(double budget, double balance, double profit) {
    return Row(
      children: [
        _summaryChip("Budget Spec", budget, Icons.account_balance_wallet_rounded),
        const SizedBox(width: 10),
        _summaryChip("Net Balance", balance, Icons.savings_rounded),
        const SizedBox(width: 10),
        _summaryChip("Yield Margin", profit, Icons.analytics_rounded),
      ],
    );
  }

  Widget _summaryChip(String label, double amount, IconData icon) {
    return Expanded(
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        borderRadius: 20,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kAccentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: kAccentColor.withValues(alpha: 0.15)),
              ),
              child: Icon(icon, color: kAccentColor, size: 18),
            ),
            const SizedBox(height: 10),
            Text(label.toUpperCase(), style: GoogleFonts.plusJakartaSans(color: kTextSecondary, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "RM ${amount >= 1000 ? '${(amount/1000).toStringAsFixed(1)}k' : amount.toStringAsFixed(0)}",
                style: GoogleFonts.plusJakartaSans(color: kTextPrimary, fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, Color color, double maxY) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 26,
          borderRadius: BorderRadius.circular(6),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: maxY,
            color: Colors.white.withValues(alpha: 0.02),
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildPieSections(double income, double expenses) {
    final double total = income + expenses;
    final double incomePct = (income / total) * 100;
    final double expensesPct = (expenses / total) * 100;
    
    final isIncomeTouched = touchedIndex == 0;
    final isExpenseTouched = touchedIndex == 1;

    return [
      PieChartSectionData(
        color: const Color(0xFF10B981),
        value: income,
        title: '${incomePct.toStringAsFixed(0)}%',
        radius: isIncomeTouched ? 68 : 58,
        titleStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
      ),
      PieChartSectionData(
        color: const Color(0xFFEF4444),
        value: expenses,
        title: '${expensesPct.toStringAsFixed(0)}%',
        radius: isExpenseTouched ? 68 : 58,
        titleStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
      ),
    ];
  }

  PieChartSectionData _noDataPie() {
    return PieChartSectionData(
      color: Colors.white.withValues(alpha: 0.04),
      value: 1,
      title: '',
      radius: 58,
    );
  }
}

class Indicator extends StatelessWidget {
  final Color color;
  final String text;
  const Indicator({required this.color, required this.text, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(text, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12, color: kTextSecondary)),
      ],
    );
  }
}