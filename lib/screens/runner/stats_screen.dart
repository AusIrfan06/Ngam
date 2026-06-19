
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../models/gig_model.dart';
import '../../services/gig_service.dart';
import '../../services/review_service.dart';
import '../../utils/app_theme.dart';

// ============================================================
// Ngam App — Runner Stats Screen (Redesigned with Charts)
// ============================================================

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  double _totalEarnings = 0.0;
  int _completedTasks = 0;
  double _averageRating = 0.0;
  
  List<GigModel> _allGigs = [];
  Map<String, double> _earningsByCategory = {};
  Map<String, int> _statusCounts = {};
  List<double> _dailyEarnings = List.filled(7, 0.0);
  
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    
    _loadStats();
  }

  Future<void> _loadStats() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id;
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final allGigs = await GigService.fetchRunnerGigs(userId);
      final completedGigs = allGigs.where((g) => g.status == 'COMPLETED').toList();
      
      double earnings = 0.0;
      Map<String, double> earningsByCat = {};
      Map<String, int> statuses = {'COMPLETED': 0, 'CANCELLED': 0, 'IN-PROGRESS': 0, 'OTHER': 0};
      
      // Calculate daily earnings for last 7 days
      final now = DateTime.now();
      List<double> dailyE = List.filled(7, 0.0);

      for (var gig in allGigs) {
        if (gig.status == 'COMPLETED' || gig.status == 'CANCELLED' || gig.status == 'IN-PROGRESS') {
           statuses[gig.status] = (statuses[gig.status] ?? 0) + 1;
        } else {
           statuses['OTHER'] = (statuses['OTHER'] ?? 0) + 1;
        }

        if (gig.status == 'COMPLETED') {
          earnings += gig.bountyAmount;
          
          // Category earnings
          final cat = gig.category.isEmpty ? 'General' : gig.category;
          earningsByCat[cat] = (earningsByCat[cat] ?? 0) + gig.bountyAmount;
          
          // Daily earnings
          final diffDays = now.difference(gig.createdAt).inDays;
          if (diffDays >= 0 && diffDays < 7) {
            // Index 6 is today, 0 is 6 days ago
            dailyE[6 - diffDays] += gig.bountyAmount;
          }
        }
      }
      
      final rating = await ReviewService.getAverageRating(userId);

      if (mounted) {
        setState(() {
          _allGigs = allGigs;
          _completedTasks = completedGigs.length;
          _totalEarnings = earnings;
          _averageRating = rating;
          _earningsByCategory = earningsByCat;
          _statusCounts = statuses;
          _dailyEarnings = dailyE;
          _isLoading = false;
        });
        _animController.forward();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Widget _buildSummaryCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Earnings',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white70 : Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'RM ${_totalEarnings.toStringAsFixed(2)}',
            style: GoogleFonts.outfit(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  icon: Icons.task_alt, 
                  title: 'Completed', 
                  value: _completedTasks.toString(), 
                  color: Colors.green,
                  isDark: isDark,
                ),
              ),
              Container(width: 1, height: 40, color: isDark ? Colors.white24 : Colors.black12),
              Expanded(
                child: _buildMiniStat(
                  icon: Icons.star_rounded, 
                  title: 'Rating', 
                  value: _averageRating > 0 ? _averageRating.toStringAsFixed(1) : '-', 
                  color: Colors.orange,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({required IconData icon, required String title, required String value, required Color color, required bool isDark}) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        Text(title, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54)),
      ],
    );
  }

  Widget _buildChartContainer(String title, Widget chart, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(height: 200, child: chart),
        ],
      ),
    );
  }

  Widget _buildLineChart(bool isDark) {
    if (_dailyEarnings.every((e) => e == 0)) {
      return const Center(child: Text('No recent earnings data.'));
    }

    final maxY = _dailyEarnings.reduce((a, b) => a > b ? a : b) * 1.2;
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final date = DateTime.now().subtract(Duration(days: 6 - value.toInt()));
                final text = DateFormat('E').format(date); // Mon, Tue...
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(text, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: maxY == 0 ? 100 : maxY,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(7, (i) => FlSpot(i.toDouble(), _dailyEarnings[i])),
            isCurved: true,
            color: AppTheme.primary,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.primary.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(bool isDark) {
    if (_allGigs.isEmpty) {
      return const Center(child: Text('No task data.'));
    }

    final int completed = _statusCounts['COMPLETED'] ?? 0;
    final int cancelled = _statusCounts['CANCELLED'] ?? 0;
    final int inProgress = _statusCounts['IN-PROGRESS'] ?? 0;
    final int other = _statusCounts['OTHER'] ?? 0;

    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 40,
        sections: [
          if (completed > 0)
            PieChartSectionData(
              color: Colors.green,
              value: completed.toDouble(),
              title: '$completed\nDone',
              radius: 60,
              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          if (inProgress > 0)
            PieChartSectionData(
              color: Colors.blue,
              value: inProgress.toDouble(),
              title: '$inProgress\nActive',
              radius: 50,
              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          if (cancelled > 0)
            PieChartSectionData(
              color: Colors.red,
              value: cancelled.toDouble(),
              title: '$cancelled\nDrop',
              radius: 50,
              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          if (other > 0)
            PieChartSectionData(
              color: Colors.grey,
              value: other.toDouble(),
              title: '$other\nOther',
              radius: 40,
              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _buildBarChart(bool isDark) {
    if (_earningsByCategory.isEmpty) {
      return const Center(child: Text('No earnings by category.'));
    }

    final categories = _earningsByCategory.keys.toList();
    final values = _earningsByCategory.values.toList();
    final maxY = values.reduce((a, b) => a > b ? a : b) * 1.2;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY == 0 ? 100 : maxY,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final String text = categories[value.toInt()];
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    text.length > 5 ? text.substring(0, 5) : text,
                    style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(
          categories.length,
          (i) => BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: values[i],
                color: Colors.orangeAccent,
                width: 22,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY == 0 ? 100 : maxY,
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Your Stats',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            fontSize: 24,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _buildSummaryCard(isDark),
                    const SizedBox(height: 32),
                    
                    _buildChartContainer(
                      'Earnings (Last 7 Days)',
                      _buildLineChart(isDark),
                      isDark,
                    ),
                    
                    _buildChartContainer(
                      'Task Distribution',
                      _buildPieChart(isDark),
                      isDark,
                    ),
                    
                    if (_earningsByCategory.isNotEmpty)
                      _buildChartContainer(
                        'Earnings by Category',
                        _buildBarChart(isDark),
                        isDark,
                      ),
                      
                    const SizedBox(height: 100), // padding for bottom nav
                  ],
                ),
              ),
            ),
    );
  }
}
