import 'dart:math';
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
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
import 'package:hugeicons/hugeicons.dart';

// ============================================================
// Ngam App — Runner Stats Screen (Premium Glassmorphism)
// ============================================================

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with TickerProviderStateMixin {
  bool _isLoading = true;
  int _selectedTimeframeIndex = 1; // 0=Today, 1=This Week, 2=This Month, 3=Custom Range
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  double _totalEarnings = 0.0;
  int _completedTasks = 0;

  double _averageRating = 0.0;

  int _activeTasks = 0;

  List<GigModel> _allGigs = [];
  List<GigModel> _recentTransactions = [];

  Map<String, double> _earningsByCategory = {};
  Map<String, int> _statusCounts = {};
  List<double> _chartData = List.filled(7, 0.0);

  late AnimationController _animController;
  late AnimationController _bgAnimController;
  late Animation<double> _fadeAnimation;

  String get _selectedTimeframe {
    const map = ['Today', 'This Week', 'This Month', 'Custom Range'];
    return map[_selectedTimeframeIndex];
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);

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

    final today = DateTime(now.year, now.month, now.day);
    if (_selectedTimeframe == 'Today') {
      filteredGigs = _allGigs.where((g) => g.createdAt.isAfter(today)).toList();
    } else if (_selectedTimeframe == 'This Week') {
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      filteredGigs = _allGigs.where((g) => g.createdAt.isAfter(startOfWeek)).toList();
    } else if (_selectedTimeframe == 'This Month') {
      final startOfMonth = DateTime(now.year, now.month, 1);
      filteredGigs = _allGigs.where((g) => g.createdAt.isAfter(startOfMonth)).toList();
    } else if (_selectedTimeframe == 'Custom Range') {
      if (_customStartDate != null && _customEndDate != null) {
        filteredGigs = _allGigs.where((g) => 
          g.createdAt.isAfter(_customStartDate!.subtract(const Duration(milliseconds: 1))) && 
          g.createdAt.isBefore(_customEndDate!.add(const Duration(days: 1)))
        ).toList();
      }
    }

    _recentTransactions = filteredGigs.where((g) => g.status == GigStatus.completed || g.status == GigStatus.cancelled).toList();
    _recentTransactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final completedGigs = filteredGigs.where((g) => g.status == GigStatus.completed).toList();

    double earnings = 0.0;
    Map<String, double> earningsByCat = {};
    Map<String, int> statuses = {'COMPLETED': 0, 'CANCELLED': 0, 'IN-PROGRESS': 0, 'OTHER': 0};
    int active = 0;

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
        active++;
      } else {
        statuses['OTHER'] = (statuses['OTHER'] ?? 0) + 1;
      }
    }

    // Dynamic Chart Data
    List<double> chartData = [];
    if (_selectedTimeframe == 'Today') {
      chartData = List.filled(24, 0.0);
      for (var gig in completedGigs) {
        if (gig.createdAt.isAfter(today)) {
          chartData[gig.createdAt.hour] += gig.bountyAmount;
        }
      }
    } else if (_selectedTimeframe == 'This Week') {
      chartData = List.filled(7, 0.0);
      for (var gig in completedGigs) {
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        if (gig.createdAt.isAfter(startOfWeek)) {
          chartData[gig.createdAt.weekday - 1] += gig.bountyAmount;
        }
      }
    } else if (_selectedTimeframe == 'This Month') {
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

      _activeTasks = active;
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _bgAnimController.dispose();
    super.dispose();
  }

  // ── Glass Container Helper ──────────────────────────────────
  Widget _glassCard({
    required Widget child,
    double borderRadius = 24,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    bool isDark = true,
    Color? tintColor,
    double blur = 20.0,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: tintColor ?? (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.55)),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.6),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  // ── Timeframe Pill Selector ─────────────────────────────────
  Widget _buildTimeframeSelector(bool isDark) {
    final labels = ['Today', 'Week', 'Month', 'Custom'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              children: List.generate(labels.length, (i) {
                final isSelected = _selectedTimeframeIndex == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      if (i == 3) {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          initialDateRange: _customStartDate != null && _customEndDate != null 
                             ? DateTimeRange(start: _customStartDate!, end: _customEndDate!) 
                             : null,
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: isDark ? const ColorScheme.dark(primary: Colors.blueAccent) : const ColorScheme.light(primary: Colors.blueAccent),
                              ),
                              child: child!,
                            );
                          }
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedTimeframeIndex = i;
                            _customStartDate = picked.start;
                            _customEndDate = picked.end;
                          });
                          _calculateStatsForTimeframe();
                        }
                      } else {
                        setState(() => _selectedTimeframeIndex = i);
                        _calculateStatsForTimeframe();
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? Colors.white.withValues(alpha: 0.15) : Colors.white)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isSelected && !isDark
                            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        labels[i],
                        style: GoogleFonts.outfit(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13,
                          color: isSelected
                              ? (isDark ? Colors.white : Colors.black87)
                              : (isDark ? Colors.white38 : Colors.black38),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  // ── Hero Earnings Card ──────────────────────────────────────
  Widget _buildHeroEarningsCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        Colors.white.withValues(alpha: 0.08),
                        Colors.white.withValues(alpha: 0.03),
                      ]
                    : [
                        AppTheme.primary.withValues(alpha: 0.08),
                        AppTheme.primary.withValues(alpha: 0.03),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : AppTheme.primary.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? AppTheme.primary : Colors.black).withValues(alpha: 0.15),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const HugeIcon(
                        icon: HugeIcons.strokeRoundedMoneyBag02,
                        color: Color(0xFF00E676),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$_selectedTimeframe Earnings',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Trend indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.trending_up_rounded, color: Color(0xFF00E676), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '$_completedTasks done',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF00E676),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Big earnings number
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: _totalEarnings),
                  duration: const Duration(milliseconds: 1400),
                  curve: Curves.easeOutQuart,
                  builder: (context, value, child) {
                    return Text(
                      'RM ${value.toStringAsFixed(2)}',
                      style: GoogleFonts.outfit(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black87,
                        letterSpacing: -2,
                        height: 1.1,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                // Mini stats row
                Row(
                  children: [
                    _buildMiniGlassStat(
                      icon: HugeIcons.strokeRoundedTaskDone01,
                      label: 'Completed',
                      value: _completedTasks.toString(),
                      color: const Color(0xFF00E676),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 12),
                    _buildMiniGlassStat(
                      icon: HugeIcons.strokeRoundedStar,
                      label: 'Rating',
                      value: _averageRating.toStringAsFixed(1),
                      color: const Color(0xFFFFD700),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 12),
                    _buildMiniGlassStat(
                      icon: HugeIcons.strokeRoundedFlash,
                      label: 'Active',
                      value: _activeTasks.toString(),
                      color: const Color(0xFF42A5F5),
                      isDark: isDark,
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

  Widget _buildMiniGlassStat({
    required dynamic icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            HugeIcon(icon: icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: isDark ? Colors.white54 : Colors.black45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Earnings Trend Chart ────────────────────────────────────
  Widget _buildEarningsChart(bool isDark) {
    return _glassCard(
      isDark: isDark,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedChart,
                  color: Color(0xFF00E676),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Earnings Trend',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 200,
            child: _buildLineChart(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(bool isDark) {
    if (_chartData.every((e) => e == 0)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedChartLineData02,
              color: isDark ? Colors.white24 : Colors.black26,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              'No earnings data yet',
              style: GoogleFonts.outfit(
                color: isDark ? Colors.white38 : Colors.black38,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final maxY = _chartData.reduce((a, b) => a > b ? a : b) * 1.3;

    return LineChart(
      LineChartData(
        maxY: maxY == 0 ? 100 : maxY,
        minY: 0,
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (group) => isDark 
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.8),
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            tooltipMargin: 10,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  'RM ${spot.y.toStringAsFixed(0)}',
                  GoogleFonts.outfit(
                    color: isDark ? Colors.white : Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                );
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                String text = '';
                if (_selectedTimeframe == 'Today') {
                  if (value.toInt() % 6 == 0) {
                    text = '${value.toInt()}h';
                  }
                } else if (_selectedTimeframe == 'This Week') {
                  const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                  if (value.toInt() >= 0 && value.toInt() < 7) {
                    text = days[value.toInt()];
                  }
                } else if (_selectedTimeframe == 'This Month') {
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
                    style: GoogleFonts.outfit(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
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
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              _chartData.length,
              (i) => FlSpot(i.toDouble(), _chartData[i]),
            ),
            isCurved: true,
            curveSmoothness: 0.35,
            gradient: const LinearGradient(
              colors: [Color(0xFF00E676), Color(0xFF00BCD4)],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: const Color(0xFF00E676),
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00E676).withValues(alpha: 0.2),
                  const Color(0xFF00E676).withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutQuart,
    );
  }

  // ── Task Completion Donut ───────────────────────────────────
  Widget _buildTaskCompletionCard(bool isDark) {
    final completed = _statusCounts['COMPLETED'] ?? 0;
    final inProgress = _statusCounts['IN-PROGRESS'] ?? 0;
    final cancelled = _statusCounts['CANCELLED'] ?? 0;
    final other = _statusCounts['OTHER'] ?? 0;
    final total = completed + inProgress + cancelled + other;

    return _glassCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedPieChart,
                  color: AppTheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Task Overview',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              Text(
                '$total tasks',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (total == 0)
            SizedBox(
              height: 160,
              child: Center(
                child: Text(
                  'No tasks yet',
                  style: GoogleFonts.outfit(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            Row(
              children: [
                // Donut chart
                SizedBox(
                  width: 130,
                  height: 130,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 35,
                      startDegreeOffset: -90,
                      sections: [
                        if (completed > 0)
                          PieChartSectionData(
                            color: const Color(0xFF00E676),
                            value: completed.toDouble(),
                            title: '',
                            radius: 22,
                          ),
                        if (inProgress > 0)
                          PieChartSectionData(
                            color: const Color(0xFF42A5F5),
                            value: inProgress.toDouble(),
                            title: '',
                            radius: 20,
                          ),
                        if (cancelled > 0)
                          PieChartSectionData(
                            color: const Color(0xFFEF5350),
                            value: cancelled.toDouble(),
                            title: '',
                            radius: 20,
                          ),
                        if (other > 0)
                          PieChartSectionData(
                            color: Colors.grey,
                            value: other.toDouble(),
                            title: '',
                            radius: 18,
                          ),
                      ],
                    ),
                    swapAnimationDuration: const Duration(milliseconds: 800),
                    swapAnimationCurve: Curves.easeOutCubic,
                  ),
                ),
                const SizedBox(width: 24),
                // Legend
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem('Completed', completed, const Color(0xFF00E676), isDark),
                      const SizedBox(height: 12),
                      _buildLegendItem('Active', inProgress, const Color(0xFF42A5F5), isDark),
                      const SizedBox(height: 12),
                      _buildLegendItem('Cancelled', cancelled, const Color(0xFFEF5350), isDark),
                      if (other > 0) ...[
                        const SizedBox(height: 12),
                        _buildLegendItem('Other', other, Colors.grey, isDark),
                      ],
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, int count, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: isDark ? Colors.white60 : Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          count.toString(),
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  // ── Category Breakdown ──────────────────────────────────────
  Widget _buildCategoryBreakdown(bool isDark) {
    if (_earningsByCategory.isEmpty) return const SizedBox.shrink();

    final sortedEntries = _earningsByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = sortedEntries.first.value;

    final categoryColors = <String, Color>{
      'Food': const Color(0xFFFF6B35),
      'Shopping': const Color(0xFF4ECDC4),
      'Print': const Color(0xFF45B7D1),
      'Heavy': const Color(0xFFFF8C94),
      'Parcel': const Color(0xFFA78BFA),
      'Cleaning': const Color(0xFF4FACFE),
      'Pet Care': const Color(0xFFFFB347),
      'Errands': const Color(0xFF5D9CEC),
      'Automotive': const Color(0xFFFC6E51),
      'Others': const Color(0xFFCCD1D9),
      'General': const Color(0xFF78909C),
    };

    return _glassCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFA78BFA).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedDashboardSquare01,
                  color: Color(0xFFA78BFA),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'By Category',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...sortedEntries.map((entry) {
            final color = categoryColors[entry.key] ?? AppTheme.primary;
            final percentage = maxVal > 0 ? entry.value / maxVal : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      Text(
                        'RM ${entry.value.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: percentage),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOutCubic,
                      builder: (context, val, _) {
                        return LinearProgressIndicator(
                          value: val,
                          backgroundColor: color.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation(color),
                          minHeight: 8,
                        );
                      },
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

  // ── Recent Transactions ─────────────────────────────────────
  Widget _buildTransactionList(bool isDark) {
    if (_recentTransactions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB347).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedInvoice03,
                  color: Color(0xFFFFB347),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Recent Activity',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._recentTransactions.take(8).map((gig) {
            final isCompleted = gig.status == GigStatus.completed;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? const Color(0xFF00E676).withValues(alpha: 0.12)
                                : const Color(0xFFEF5350).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: HugeIcon(
                              icon: isCompleted
                                  ? HugeIcons.strokeRoundedTaskDone01
                                  : HugeIcons.strokeRoundedCancel01,
                              color: isCompleted
                                  ? const Color(0xFF00E676)
                                  : const Color(0xFFEF5350),
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                gig.title,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd MMM, hh:mm a').format(gig.createdAt),
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: isDark ? Colors.white38 : Colors.black38,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isCompleted
                              ? '+RM${gig.bountyAmount.toStringAsFixed(0)}'
                              : 'RM0',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: isCompleted
                                ? const Color(0xFF00E676)
                                : (isDark ? Colors.white38 : Colors.black38),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Loading Shimmer ─────────────────────────────────────────
  Widget _buildLoadingShimmer(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Shimmer.fromColors(
            baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
            highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
            child: Column(
              children: [
                Container(
                  width: 180, height: 18,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 120, height: 14,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Main Build ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── Animated Abstract BG ──
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgAnimController,
              builder: (context, child) {
                return Stack(
                  children: [
                    Container(
                      color: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF0F2F5),
                    ),
                    // Floating orbs
                    Positioned(
                      top: -80 + 60 * sin(_bgAnimController.value * 2 * pi),
                      right: -40 + 40 * cos(_bgAnimController.value * 2 * pi),
                      child: Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppTheme.primary.withValues(alpha: isDark ? 0.12 : 0.08),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 100 + 40 * cos(_bgAnimController.value * 2 * pi * 0.7),
                      left: -60 + 50 * sin(_bgAnimController.value * 2 * pi * 0.7),
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF00E676).withValues(alpha: isDark ? 0.08 : 0.05),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 300 + 30 * sin(_bgAnimController.value * 2 * pi * 1.3),
                      right: -20 + 35 * cos(_bgAnimController.value * 2 * pi * 1.3),
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFFA78BFA).withValues(alpha: isDark ? 0.1 : 0.06),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // ── Content ──
          _isLoading
              ? _buildLoadingShimmer(isDark)
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // App Bar
                    SliverAppBar(
                      expandedHeight: 80,
                      floating: true,
                      pinned: true,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      flexibleSpace: ClipRRect(
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: FlexibleSpaceBar(
                            titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
                            title: Text(
                              'Statistics',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w800,
                                fontSize: 26,
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildTimeframeSelector(isDark),
                            const SizedBox(height: 4),
                            _buildHeroEarningsCard(isDark),
                            const SizedBox(height: 4),
                            _buildEarningsChart(isDark),
                            const SizedBox(height: 4),
                            _buildTaskCompletionCard(isDark),
                            const SizedBox(height: 4),
                            _buildCategoryBreakdown(isDark),
                            const SizedBox(height: 4),
                            _buildTransactionList(isDark),
                            const SizedBox(height: 120),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}
