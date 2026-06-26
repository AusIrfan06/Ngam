import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/auth_provider.dart';
import '../../models/gig_model.dart';
import '../../services/gig_service.dart';
import '../../services/review_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

// ============================================================
// Ngam App — Runner Stats Screen (Total Redesign)
// ============================================================

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String _selectedTimeframe = 'Weekly'; // Weekly, Monthly, All-Time
  final List<String> _timeframes = ['Weekly', 'Monthly', 'All-Time'];

  double _totalEarnings = 0.0;
  int _completedTasks = 0;
  double _averageRating = 0.0;
  
  List<GigModel> _allGigs = [];
  List<GigModel> _recentTransactions = [];
  
  Map<String, double> _earningsByCategory = {};
  Map<String, int> _statusCounts = {};
  List<double> _chartData = List.filled(7, 0.0);
  
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    
    _loadAllStats();
  }

  Future<void> _loadAllStats() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id;
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      _allGigs = await GigService.fetchRunnerGigs(userId);
      _averageRating = await ReviewService.getAverageRating(userId);
      
      _calculateStatsForTimeframe();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _animController.forward();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _calculateStatsForTimeframe() {
    final now = DateTime.now();
    List<GigModel> filteredGigs = _allGigs;
    
    if (_selectedTimeframe == 'Weekly') {
      filteredGigs = _allGigs.where((g) => now.difference(g.createdAt).inDays < 7).toList();
    } else if (_selectedTimeframe == 'Monthly') {
      filteredGigs = _allGigs.where((g) => now.difference(g.createdAt).inDays < 30).toList();
    }
    
    _recentTransactions = filteredGigs.where((g) => g.status == GigStatus.completed || g.status == GigStatus.cancelled).toList();
    _recentTransactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final completedGigs = filteredGigs.where((g) => g.status == GigStatus.completed).toList();
    
    double earnings = 0.0;
    Map<String, double> earningsByCat = {};
    Map<String, int> statuses = {'COMPLETED': 0, 'CANCELLED': 0, 'IN-PROGRESS': 0, 'OTHER': 0};
    
    for (var gig in filteredGigs) {
      if (gig.status == GigStatus.completed) {
        statuses['COMPLETED'] = (statuses['COMPLETED'] ?? 0) + 1;
        earnings += gig.bountyAmount;
        final cat = gig.category.isEmpty ? 'General' : gig.category;
        earningsByCat[cat] = (earningsByCat[cat] ?? 0) + gig.bountyAmount;
      } else if (gig.status == GigStatus.cancelled) {
        statuses['CANCELLED'] = (statuses['CANCELLED'] ?? 0) + 1;
      } else if (gig.status == GigStatus.inProgress || gig.status == GigStatus.locked) {
        statuses['IN-PROGRESS'] = (statuses['IN-PROGRESS'] ?? 0) + 1;
      } else {
        statuses['OTHER'] = (statuses['OTHER'] ?? 0) + 1;
      }
    }

    // Dynamic Chart Data
    List<double> chartData = [];
    if (_selectedTimeframe == 'Weekly') {
      chartData = List.filled(7, 0.0);
      for (var gig in completedGigs) {
        final diffDays = now.difference(gig.createdAt).inDays;
        if (diffDays >= 0 && diffDays < 7) {
          chartData[6 - diffDays] += gig.bountyAmount;
        }
      }
    } else if (_selectedTimeframe == 'Monthly') {
      chartData = List.filled(4, 0.0);
      for (var gig in completedGigs) {
        final diffDays = now.difference(gig.createdAt).inDays;
        if (diffDays >= 0 && diffDays < 28) {
          int weekIdx = diffDays ~/ 7;
          chartData[3 - weekIdx] += gig.bountyAmount;
        }
      }
    } else {
      chartData = List.filled(6, 0.0);
      for (var gig in completedGigs) {
        final diffDays = now.difference(gig.createdAt).inDays;
        if (diffDays >= 0 && diffDays < 180) {
          int monthIdx = diffDays ~/ 30;
          chartData[5 - monthIdx] += gig.bountyAmount;
        }
      }
    }

    setState(() {
      _totalEarnings = earnings;
      _completedTasks = completedGigs.length;
      _earningsByCategory = earningsByCat;
      _statusCounts = statuses;
      _chartData = chartData;
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Widget _buildTimeframeSelector(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: _timeframes.map((tf) {
          final isSelected = _selectedTimeframe == tf;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedTimeframe = tf);
                _calculateStatsForTimeframe();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? (isDark ? Colors.white.withValues(alpha: 0.15) : Colors.white) 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected && !isDark ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ] : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  tf,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected 
                        ? (isDark ? Colors.white : Colors.black87)
                        : (isDark ? Colors.white54 : Colors.black54),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
              ? [const Color(0xFF2C3E50), const Color(0xFF000000)]
              : [AppTheme.primary.withValues(alpha: 0.8), AppTheme.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_selectedTimeframe Earnings',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: _totalEarnings),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutQuart,
            builder: (context, value, child) {
              return Text(
                'RM ${value.toStringAsFixed(2)}',
                style: GoogleFonts.outfit(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  icon: Icons.task_alt, 
                  title: 'Completed', 
                  value: _completedTasks.toDouble(), 
                  color: Colors.greenAccent,
                  isDark: isDark,
                  isInteger: true,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              Expanded(
                child: _buildMiniStat(
                  icon: Icons.star_rounded, 
                  title: 'Rating', 
                  value: _averageRating, 
                  color: Colors.orangeAccent,
                  isDark: isDark,
                  isInteger: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({required IconData icon, required String title, required double value, required Color color, required bool isDark, required bool isInteger}) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: value),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutCubic,
          builder: (context, val, child) {
            final displayStr = isInteger ? val.toInt().toString() : val.toStringAsFixed(1);
            return Text(
              displayStr, 
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)
            );
          },
        ),
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }

  Widget _buildChartContainer(String title, Widget chart, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        gradient: isDark ? const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF121212), // Very dark at top
            Color(0xFF0F3025), // Subtle green glow at bottom
          ],
        ) : null,
        color: isDark ? null : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: isDark ? [
          BoxShadow(
            color: const Color(0xFF00FF87).withValues(alpha: 0.05),
            blurRadius: 30,
            offset: const Offset(0, 10),
          )
        ] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
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
          const SizedBox(height: 32),
          SizedBox(height: 220, child: chart),
        ],
      ),
    );
  }

  Widget _buildBarChart(bool isDark) {
    if (_chartData.every((e) => e == 0)) {
      return const Center(child: Text('No earnings data.'));
    }

    final maxY = _chartData.reduce((a, b) => a > b ? a : b) * 1.2;
    
    BarChartData getChartData(bool isGlowLayer) {
      return BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY == 0 ? 100 : maxY,
        barTouchData: BarTouchData(
          enabled: !isGlowLayer,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.black87,
            tooltipPadding: const EdgeInsets.all(8),
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                'RM ${rod.toY.toStringAsFixed(0)}',
                GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: !isGlowLayer,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                String text = '';
                if (_selectedTimeframe == 'Weekly') {
                  final date = DateTime.now().subtract(Duration(days: 6 - value.toInt()));
                  text = DateFormat('E').format(date);
                } else if (_selectedTimeframe == 'Monthly') {
                  text = 'W${value.toInt() + 1}';
                } else {
                  final date = DateTime.now().subtract(Duration(days: (5 - value.toInt()) * 30));
                  text = DateFormat('MMM').format(date);
                }
                
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8,
                  child: Text(
                    text, 
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87, 
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      fontFamily: 'Courier',
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(
          _chartData.length,
          (i) => BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: _chartData[i],
                gradient: LinearGradient(
                  colors: isGlowLayer 
                      ? [const Color(0xFF00E676), const Color(0xFF00E676)]
                      : [const Color(0xFF0D3B2E), const Color(0xFF00E676), const Color(0xFF8BFFC2)], // Softer green/white
                  stops: isGlowLayer ? null : [0.0, 0.7, 1.0],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 20,
                borderRadius: BorderRadius.circular(12),
                backDrawRodData: BackgroundBarChartRodData(
                  show: !isGlowLayer,
                  toY: maxY == 0 ? 100 : maxY,
                  color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.03),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (isDark)
          Positioned.fill(
            child: IgnorePointer(
              child: Transform.translate(
                offset: const Offset(0, -3), // Shift up slightly to avoid label bleed
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 3.5, sigmaY: 6), // Muted, softer blur
                  child: BarChart(
                    getChartData(true),
                    swapAnimationDuration: const Duration(milliseconds: 1000),
                    swapAnimationCurve: Curves.easeOutQuart,
                  ),
                ),
              ),
            ),
          ),
        Positioned.fill(
          child: BarChart(
            getChartData(false),
            swapAnimationDuration: const Duration(milliseconds: 1000),
            swapAnimationCurve: Curves.easeOutQuart,
          ),
        ),
      ],
    );
  }

  Widget _buildPieChart(bool isDark) {
    final completed = _statusCounts['COMPLETED'] ?? 0;
    final inProgress = _statusCounts['IN-PROGRESS'] ?? 0;
    final cancelled = _statusCounts['CANCELLED'] ?? 0;
    final other = _statusCounts['OTHER'] ?? 0;

    if (completed == 0 && inProgress == 0 && cancelled == 0 && other == 0) {
      return const Center(child: Text('No task data.'));
    }

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
      swapAnimationDuration: const Duration(milliseconds: 800),
      swapAnimationCurve: Curves.easeOutCubic,
    );
  }

  Widget _buildTransactionList(bool isDark) {
    if (_recentTransactions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Transactions',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ..._recentTransactions.map((gig) {
            final isCompleted = gig.status == GigStatus.completed;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCompleted ? Icons.check_circle_outline : Icons.cancel_outlined,
                      color: isCompleted ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gig.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd MMM yyyy, hh:mm a').format(gig.createdAt),
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isCompleted ? '+ RM ${gig.bountyAmount.toStringAsFixed(2)}' : 'RM 0.00',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isCompleted ? Colors.green : (isDark ? Colors.white54 : Colors.black54),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading 
          ? Center(
              child: Shimmer.fromColors(
                baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
                child: Container(
                  width: 200,
                  height: 20,
                  color: Colors.white,
                ),
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 80,
                  floating: true,
                  pinned: true,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9),
                  elevation: 0,
                  flexibleSpace: ClipRRect(
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: FlexibleSpaceBar(
                        titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
                        title: Text(
                          'Insights',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                            fontSize: 28,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTimeframeSelector(isDark),
                          _buildSummaryCard(isDark),
                          
                          _buildChartContainer(
                            'Earnings Trend',
                            _buildBarChart(isDark),
                            isDark,
                          ),
                          
                          _buildChartContainer(
                            'Task Completion',
                            _buildPieChart(isDark),
                            isDark,
                          ),
                          
                          _buildTransactionList(isDark),
                            
                          const SizedBox(height: 100), // padding for bottom nav
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
