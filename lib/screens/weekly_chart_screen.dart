import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/daily_step_data.dart';
import '../providers/providers.dart';

class WeeklyChartScreen extends ConsumerWidget {
  const WeeklyChartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final weeklyAsync = ref.watch(weeklyStepsProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          '이번 주 걸음',
          style: GoogleFonts.gowunBatang(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: weeklyAsync.when(
          loading: () => Center(
            child: CircularProgressIndicator(color: color, strokeWidth: 2),
          ),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                '걸음 데이터를 불러올 수 없습니다',
                style: GoogleFonts.gowunBatang(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (data) {
            if (data.isEmpty) {
              return _EmptyState(color: color, theme: theme);
            }
            return _ChartBody(data: data, color: color, theme: theme);
          },
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Color color;
  final ThemeData theme;

  const _EmptyState({required this.color, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.directions_walk_rounded,
            size: 48,
            color: color.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            '이번 주 걸음 데이터가 없습니다',
            style: GoogleFonts.gowunBatang(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartBody extends StatefulWidget {
  final List<DailyStepData> data;
  final Color color;
  final ThemeData theme;

  const _ChartBody({
    required this.data,
    required this.color,
    required this.theme,
  });

  @override
  State<_ChartBody> createState() => _ChartBodyState();
}

class _ChartBodyState extends State<_ChartBody> {
  late int _selectedIndex;

  static const _dayLabels = ['일', '월', '화', '수', '목', '금', '토'];

  @override
  void initState() {
    super.initState();
    _selectedIndex = DateTime.now().weekday % 7;
  }

  int get _maxSteps {
    final max = widget.data.fold<int>(0, (m, d) => d.steps > m ? d.steps : m);
    return max < 1000 ? 1000 : max;
  }

  String _formatStepsShort(int steps) {
    if (steps >= 10000) {
      final k = steps / 1000;
      return '${k.toStringAsFixed(k.truncateToDouble() == k ? 0 : 1)}k';
    }
    if (steps >= 1000) {
      return '${(steps / 1000).toStringAsFixed(1)}k';
    }
    return steps.toString();
  }

  String _formatSteps(int steps) {
    return steps.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  @override
  Widget build(BuildContext context) {
    final todayWeekday = DateTime.now().weekday % 7;
    final selected = widget.data[_selectedIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 말씀 카드 (고정 높이로 레이아웃 흔들림 방지)
          SizedBox(
            height: 180,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _VerseCard(
                key: ValueKey(_selectedIndex),
                data: selected,
                dayLabel: _dayLabels[_selectedIndex],
                isToday: _selectedIndex == todayWeekday,
                color: widget.color,
                theme: widget.theme,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // 라인 차트 (적당한 고정 높이)
          SizedBox(
            height: 260,
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _maxSteps / 4,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: widget.theme.colorScheme.onSurface
                          .withValues(alpha: 0.08),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 52,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i > 6) return const SizedBox.shrink();
                          final isSelected = i == _selectedIndex;
                          final isToday = i == todayWeekday;
                          final isFuture = i > todayWeekday;
                          final labelColor = isSelected
                              ? widget.color
                              : isFuture
                                  ? widget.theme.colorScheme.onSurface
                                      .withValues(alpha: 0.25)
                                  : widget.theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6);
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: isFuture
                                ? null
                                : () {
                                    HapticFeedback.selectionClick();
                                    setState(() => _selectedIndex = i);
                                  },
                            child: Container(
                              width: 44,
                              height: 48,
                              alignment: Alignment.center,
                              decoration: isSelected
                                  ? BoxDecoration(
                                      color: widget.color
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    )
                                  : null,
                              child: Text(
                                _dayLabels[i],
                                style: GoogleFonts.gowunBatang(
                                  fontSize: 13,
                                  fontWeight: isSelected || isToday
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                  color: labelColor,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        interval: _maxSteps / 4,
                        getTitlesWidget: (value, meta) {
                          if (value == 0 || value > _maxSteps * 0.95) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            _formatStepsShort(value.toInt()),
                            style: GoogleFonts.gowunBatang(
                              fontSize: 10,
                              color: widget.theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 6,
                  minY: 0,
                  maxY: _maxSteps * 1.15,
                  lineTouchData: LineTouchData(
                    touchCallback: (event, response) {
                      if (response?.lineBarSpots != null &&
                          response!.lineBarSpots!.isNotEmpty) {
                        final i = response.lineBarSpots!.first.x.toInt();
                        if (i <= todayWeekday && i != _selectedIndex) {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedIndex = i);
                        }
                      }
                    },
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) =>
                          widget.color.withValues(alpha: 0.9),
                      tooltipRoundedRadius: 12,
                      tooltipPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      getTooltipItems: (spots) => spots.map((spot) {
                        return LineTooltipItem(
                          '${_formatSteps(spot.y.toInt())} 걸음',
                          GoogleFonts.gowunBatang(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(widget.data.length, (i) {
                        return FlSpot(
                            i.toDouble(), widget.data[i].steps.toDouble());
                      }),
                      isCurved: true,
                      curveSmoothness: 0.3,
                      preventCurveOverShooting: true,
                      color: widget.color,
                      barWidth: 2.5,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          final isSelected = index == _selectedIndex;
                          final isToday = index == todayWeekday;
                          return FlDotCirclePainter(
                            radius: isSelected ? 6 : (isToday ? 4.5 : 3),
                            color: isSelected || isToday
                                ? widget.color
                                : widget.color.withValues(alpha: 0.6),
                            strokeWidth: isSelected ? 2 : 0,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            widget.color.withValues(alpha: 0.18),
                            widget.color.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _VerseCard extends StatelessWidget {
  final DailyStepData data;
  final String dayLabel;
  final bool isToday;
  final Color color;
  final ThemeData theme;

  const _VerseCard({
    super.key,
    required this.data,
    required this.dayLabel,
    required this.isToday,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final hasVerse = data.verseText != null;
    final stepsFormatted = data.steps.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isToday ? '오늘' : '$dayLabel요일',
                style: GoogleFonts.gowunBatang(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '·',
                  style: TextStyle(color: color.withValues(alpha: 0.5)),
                ),
              ),
              Text(
                '$stepsFormatted 걸음',
                style: GoogleFonts.gowunBatang(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          if (hasVerse) ...[
            const SizedBox(height: 14),
            Text(
              data.verseText!,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.gowunBatang(
                fontSize: 15,
                height: 1.8,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              data.verseReference!,
              style: GoogleFonts.gowunBatang(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            Text(
              '선택한 말씀이 없습니다',
              style: GoogleFonts.gowunBatang(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
