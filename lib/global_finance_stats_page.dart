// lib/global_finance_stats_page.dart (Premium Glassmorphic Portfolio Analytics Engine)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'main.dart'; // Design tokens & GlassContainer
import 'widgets/app_background.dart';

class GlobalFinanceStatsPage extends StatefulWidget {
  const GlobalFinanceStatsPage({super.key});

  @override
  State<GlobalFinanceStatsPage> createState() => _GlobalFinanceStatsPageState();
}

class _GlobalFinanceStatsPageState extends State<GlobalFinanceStatsPage> {
  int touchedIndex = -1;
  bool _loading = true;

  int _activeProjects = 0;
  int _totalProjects = 0;
  double _portfolioROI = 0.0;
  double _avgVarianceDays = 0.0;
  double _avgHealthScore = 100.0;
  double _totalAllocatedBudget = 0.0;
  double _totalExpenses = 0.0;
  double _totalRevenue = 0.0;
  List<Map<String, dynamic>> _projectStats = [];

  StreamSubscription<QuerySnapshot>? _projectsSub;

  @override
  void initState() {
    super.initState();
    _initDataStream();
  }

  @override
  void dispose() {
    _projectsSub?.cancel();
    super.dispose();
  }

  void _initDataStream() {
    _projectsSub = FirebaseFirestore.instance
        .collection('projects')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((projectsSnapshot) async {
      if (!mounted) return;

      final projectDocs = projectsSnapshot.docs;
      if (projectDocs.isEmpty) {
        if (mounted) {
          setState(() {
            _loading = false;
            _projectStats = [];
            _activeProjects = 0;
            _totalProjects = 0;
            _portfolioROI = 0.0;
            _avgVarianceDays = 0.0;
            _avgHealthScore = 100.0;
            _totalAllocatedBudget = 0.0;
            _totalExpenses = 0.0;
          });
        }
        return;
      }

      try {
        // Fetch the subcollection transactions for each project in parallel
        final financeSnapshots = await Future.wait(
          projectDocs.map(
            (doc) => FirebaseFirestore.instance
                .collection('projects')
                .doc(doc.id)
                .collection('finance')
                .get(),
          ),
        );

        int activeProjects = 0;
        double totalAllocatedBudget = 0.0;
        double totalClaims = 0.0;
        double totalExpenses = 0.0;
        double totalHealthScore = 0.0;
        int totalVarianceDays = 0;
        int projectsWithTimeline = 0;

        final List<Map<String, dynamic>> projectStats = [];

        for (int i = 0; i < projectDocs.length; i++) {
          final projectData = projectDocs[i].data();
          final projectName = projectData['projectName'] ?? 'Unnamed Asset';
          final String status = projectData['status'] ?? 'Active';
          final budget = (projectData['budget'] is num)
              ? (projectData['budget'] as num).toDouble()
              : 0.0;

          totalAllocatedBudget += budget;
          if (status != 'Completed') {
            activeProjects++;
          }

          double projectClaims = 0.0;
          double projectExpenses = 0.0;

          final txDocs = financeSnapshots[i].docs;
          for (var txDoc in txDocs) {
            final txData = txDoc.data();
            final amount = (txData['amount'] is num)
                ? (txData['amount'] as num).toDouble()
                : 0.0;
            final type = txData['type'] ?? 'Expense';

            if (type == 'Claim') {
              projectClaims += amount;
            } else {
              projectExpenses += amount;
            }
          }

          totalClaims += projectClaims;
          totalExpenses += projectExpenses;

          // 1. ROI Calculation
          double projectROI = 0.0;
          if (projectExpenses > 0) {
            projectROI = ((projectClaims - projectExpenses) / projectExpenses) * 100.0;
          } else if (projectClaims > 0) {
            projectROI = 100.0;
          }

          // 2. Schedule Variance & Expected Progress Calculation
          int varianceDays = 0;
          double expectedProgress = 0.0;
          final startVal = projectData['startDate'];
          final endVal = projectData['endDate'];

          if (startVal is Timestamp && endVal is Timestamp) {
            final start = startVal.toDate();
            final end = endVal.toDate();
            final now = DateTime.now();
            final totalDuration = end.difference(start).inDays;
            final elapsed = now.difference(start).inDays;

            if (totalDuration > 0) {
              projectsWithTimeline++;
              expectedProgress = (elapsed / totalDuration) * 100.0;
              if (expectedProgress > 100.0) expectedProgress = 100.0;
              if (expectedProgress < 0.0) expectedProgress = 0.0;
            }

            if (status != 'Completed') {
              if (now.isAfter(end)) {
                varianceDays = now.difference(end).inDays;
              } else if (totalDuration > 0) {
                double actualProgress = (projectData['progress'] is num)
                    ? (projectData['progress'] as num).toDouble()
                    : 0.0;
                if (actualProgress < expectedProgress) {
                  double expectedDaysDone = (expectedProgress / 100.0) * totalDuration;
                  double actualDaysDone = (actualProgress / 100.0) * totalDuration;
                  varianceDays = (expectedDaysDone - actualDaysDone).round();
                }
              }
            }
          }
          totalVarianceDays += varianceDays;

          // 3. Health Score Calculation
          double budgetScore = 100.0;
          if (budget > 0) {
            if (projectExpenses > budget) {
              double overrun = projectExpenses - budget;
              budgetScore = 100.0 - ((overrun / budget) * 100.0);
              if (budgetScore < 0.0) budgetScore = 0.0;
            }
          } else if (projectExpenses > 0) {
            budgetScore = 50.0;
          }

          double progressScore = 100.0;
          if (startVal is Timestamp && endVal is Timestamp && status != 'Completed') {
            double actualProgress = (projectData['progress'] is num)
                ? (projectData['progress'] as num).toDouble()
                : 0.0;
            if (actualProgress < expectedProgress) {
              progressScore = 100.0 - (expectedProgress - actualProgress);
              if (progressScore < 0.0) progressScore = 0.0;
            }
          }

          double healthScore = (budgetScore * 0.6) + (progressScore * 0.4);
          totalHealthScore += healthScore;

          projectStats.add({
            'projectName': projectName,
            'status': status,
            'budget': budget,
            'claims': projectClaims,
            'expenses': projectExpenses,
            'netProfit': projectClaims - projectExpenses,
            'roi': projectROI,
            'health': healthScore,
            'variance': varianceDays,
            'progress': (projectData['progress'] is num) ? (projectData['progress'] as num).toInt() : 0,
            'startDate': startVal,
            'endDate': endVal,
          });
        }

        final double portfolioROI = totalExpenses > 0
            ? ((totalClaims - totalExpenses) / totalExpenses) * 100.0
            : (totalClaims > 0 ? 100.0 : 0.0);
        final double avgHealthScore = projectDocs.isNotEmpty
            ? (totalHealthScore / projectDocs.length)
            : 100.0;
        final double avgVarianceDays = projectsWithTimeline > 0
            ? (totalVarianceDays.toDouble() / projectsWithTimeline.toDouble())
            : 0.0;

        if (mounted) {
          setState(() {
            _activeProjects = activeProjects;
            _totalProjects = projectDocs.length;
            _portfolioROI = portfolioROI;
            _avgVarianceDays = avgVarianceDays;
            _avgHealthScore = avgHealthScore;
            _totalAllocatedBudget = totalAllocatedBudget;
            _totalExpenses = totalExpenses;
            _totalRevenue = totalClaims;
            _projectStats = projectStats;
            _loading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _loading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading performance details: $e')),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kTextPrimary, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Global Asset Performance',
            style: GoogleFonts.plusJakartaSans(
              color: kTextPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: -0.5,
            ),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: kAccentColor))
            : _projectStats.isEmpty
                ? Center(
                    child: Text(
                      'No portfolio assets registered.',
                      style: GoogleFonts.plusJakartaSans(color: kTextSecondary, fontSize: 14),
                    ),
                  )
                : SafeArea(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 700),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 1. KPI GRID (Financial ROI, Total Revenue, Active Projects, Portfolio Health)
                              _buildKPIGrid(
                                _activeProjects,
                                _totalProjects,
                                _portfolioROI,
                                _totalRevenue,
                                _avgHealthScore,
                              ),
                              const SizedBox(height: 24),

                              // 2. BUDGET VS CURRENT EXPENSES CHART & PROGRESS BAR
                              _buildBudgetComparisonCard(_totalAllocatedBudget, _totalExpenses),
                              const SizedBox(height: 24),

                              // 3. PIE CHART CARD (BUDGET DISTRIBUTION)
                              if (_totalAllocatedBudget > 0) ...[
                                _buildBudgetChartCard(_projectStats),
                                const SizedBox(height: 24),
                              ],

                              // 4. DETAILED PROJECT PERFORMANCE CONSOLE
                              _buildProjectBreakoutCard(_projectStats),
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

  Widget _buildKPIGrid(
    int activeCount,
    int totalCount,
    double roi,
    double totalRevenue,
    double health,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 450;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isNarrow ? 2 : 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.05,
          children: [
            _buildKPICard(
              'FINANCIAL ROI',
              '${roi.toStringAsFixed(1)}%',
              roi >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              Icons.donut_large_rounded,
              'Yield return rate',
            ),
            _buildKPICard(
              'TOTAL REVENUE',
              'RM ${totalRevenue.toStringAsFixed(0)}',
              const Color(0xFF10B981),
              Icons.payments_outlined,
              'Total claimed revenue',
            ),
            _buildKPICard(
              'ACTIVE PROJECTS',
              '$activeCount / $totalCount',
              kAccentColor,
              Icons.folder_special_rounded,
              'Active project count',
            ),
            _buildKPICard(
              'PORTFOLIO HEALTH',
              '${health.toStringAsFixed(0)}%',
              health >= 90
                  ? const Color(0xFF10B981)
                  : (health >= 70 ? Colors.orange : const Color(0xFFEF4444)),
              Icons.health_and_safety_outlined,
              health >= 90 ? 'Optimal state' : (health >= 70 ? 'Warning / Stable' : 'Critical alert'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKPICard(String title, String value, Color color, IconData icon, String desc) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(fontSize: 8.5, fontWeight: FontWeight.w800, color: kTextSecondary, letterSpacing: 0.5),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w900, color: kTextPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(fontSize: 9.5, color: kTextSecondary, fontWeight: FontWeight.w500),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBudgetComparisonCard(double budget, double expenses) {
    final double ratio = budget > 0 ? (expenses / budget) : 0.0;
    final double displayRatio = ratio > 1.0 ? 1.0 : ratio;
    final Color barColor = ratio > 0.8 ? const Color(0xFFEF4444) : kAccentColor;

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BUDGET VS CURRENT EXPENDITURE',
                style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: kTextSecondary, letterSpacing: 0.8),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: barColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(ratio * 100).toStringAsFixed(1)}% Spent',
                  style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: barColor),
                ),
              )
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _miniInfoBlock("Total Allocation", budget, kTextPrimary, Icons.account_balance_wallet_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _miniInfoBlock("Current Expenses", expenses, const Color(0xFFEF4444), Icons.payments_outlined),
              )
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: displayRatio,
              minHeight: 8,
              color: barColor,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniInfoBlock(String label, double val, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.01),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kCardGlassBorder.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(fontSize: 8, color: kTextSecondary, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  "RM ${val.toStringAsFixed(0)}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kTextPrimary, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBudgetChartCard(List<Map<String, dynamic>> stats) {
    final List<PieChartSectionData> sections = [];
    double totalBudget = 0.0;
    for (var s in stats) {
      totalBudget += s['budget'];
    }

    final colors = [
      kAccentColor,
      const Color(0xFF10B981),
      const Color(0xFF8B5CF6),
      const Color(0xFFEF4444),
      const Color(0xFFF59E0B),
      const Color(0xFF3B82F6),
    ];

    for (int i = 0; i < stats.length; i++) {
      final s = stats[i];
      final budget = s['budget'] as double;
      if (budget <= 0) continue;

      final double percentage = (budget / totalBudget) * 100;
      final isTouched = i == touchedIndex;
      final double radius = isTouched ? 62 : 52;

      sections.add(
        PieChartSectionData(
          color: colors[i % colors.length],
          value: budget,
          title: '${percentage.toStringAsFixed(0)}%',
          radius: radius,
          titleStyle: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      );
    }

    return GlassContainer(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Portfolio Budget Allocation",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: SizedBox(
                  height: 120,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 28,
                      sections: sections.isEmpty ? [_noDataPie()] : sections,
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              touchedIndex = -1;
                              return;
                            }
                            touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(stats.length, (i) {
                    final s = stats[i];
                    final budget = s['budget'] as double;
                    if (budget <= 0) return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colors[i % colors.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              s['projectName'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                color: kTextPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  PieChartSectionData _noDataPie() {
    return PieChartSectionData(
      color: Colors.white.withValues(alpha: 0.04),
      value: 1,
      title: '',
      radius: 52,
    );
  }

  Widget _buildProjectBreakoutCard(List<Map<String, dynamic>> projects) {
    return GlassContainer(
      borderRadius: 24,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Project Performance Breakdown",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Detailed operational, timeline adherence, and ROI status metrics.",
            style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: kTextSecondary),
          ),
          const SizedBox(height: 20),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final p = projects[index];
              final double budget = p['budget'];
              final double expenses = p['expenses'];
              final double claims = (p['claims'] as num).toDouble();
              final double health = (p['health'] as num).toDouble();
              final double roi = (p['roi'] as num).toDouble();

              final double budgetRatio = budget > 0 ? (expenses / budget) : 0.0;
              final double displayRatio = budgetRatio > 1.0 ? 1.0 : budgetRatio;
              final Color budgetBarColor = budgetRatio > 0.85 ? const Color(0xFFEF4444) : kAccentColor;

              final Color healthColor = health >= 90
                  ? const Color(0xFF10B981)
                  : (health >= 70 ? Colors.orange : const Color(0xFFEF4444));

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.01),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: kCardGlassBorder.withValues(alpha: 0.6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // A. Top Title Line
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p['projectName'],
                                style: GoogleFonts.plusJakartaSans(
                                  color: kTextPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Status: ${p['status'].toUpperCase()}",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: p['status'] == 'Completed' ? const Color(0xFF10B981) : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: healthColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: healthColor.withValues(alpha: 0.25)),
                          ),
                          child: Text(
                            "Health: ${health.toStringAsFixed(0)}%",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: healthColor,
                            ),
                          ),
                        )
                      ],
                    ),
                    const Divider(color: kCardGlassBorder, height: 24, thickness: 0.5),

                    // B. Metrics Grid Inside Card
                    Row(
                      children: [
                        Expanded(
                          child: _breakoutGridItem(
                            "Financial ROI",
                            "${roi.toStringAsFixed(1)}%",
                            roi >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _breakoutGridItem(
                            "Total Revenue",
                            "RM ${claims.toStringAsFixed(0)}",
                            const Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _breakoutGridItem(
                            "Project Status",
                            (p['status'] ?? 'Active').toString().toUpperCase(),
                            kAccentColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // C. Budget Consumption Linear Progress
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "BUDGET CAPACITY",
                          style: GoogleFonts.plusJakartaSans(fontSize: 8.5, color: kTextSecondary, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                        ),
                        Text(
                          "RM ${expenses.toStringAsFixed(0)} / RM ${budget.toStringAsFixed(0)} (${(budgetRatio * 100).toStringAsFixed(0)}%)",
                          style: GoogleFonts.plusJakartaSans(fontSize: 9.5, color: kTextPrimary, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: displayRatio,
                        minHeight: 5,
                        color: budgetBarColor,
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _breakoutGridItem(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.005),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kCardGlassBorder.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(fontSize: 8, color: kTextSecondary, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: valueColor, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
