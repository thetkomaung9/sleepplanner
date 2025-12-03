import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/env_provider.dart';
import 'lux_noise_detail_screen.dart';
import 'daily_stats_screen.dart';

class LightGuideScreen extends StatelessWidget {
  const LightGuideScreen({super.key});

  List<PieChartSectionData> _buildPieData(
      Map<int, int> stats, BuildContext context) {
    final tot = stats.values.fold(0, (a, b) => a + b);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (tot == 0) {
      return [
        PieChartSectionData(
          value: 1,
          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
          title: "데이터 없음",
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        )
      ];
    }

    return [
      PieChartSectionData(
        value: stats[0]!.toDouble(),
        color: Colors.green.shade600,
        radius: 50,
        title: "좋음\n${(stats[0]! * 100 / tot).toStringAsFixed(0)}%",
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: stats[1]!.toDouble(),
        color: Colors.orange.shade600,
        radius: 50,
        title: "주의\n${(stats[1]! * 100 / tot).toStringAsFixed(0)}%",
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: stats[2]!.toDouble(),
        color: Colors.red.shade600,
        radius: 50,
        title: "방해\n${(stats[2]! * 100 / tot).toStringAsFixed(0)}%",
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    // Theme-aware colors
    final cardColor = colorScheme.surfaceContainerHighest;
    final sensorContainerColor = isDark
        ? colorScheme.surfaceContainerHigh
        : colorScheme.surfaceContainerHighest;
    final criteriaContainerColor = isDark
        ? colorScheme.surfaceContainerLow
        : colorScheme.surfaceContainerLowest;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "빛·소음 노출 가이드",
          style: TextStyle(
            fontFamily: 'Roboto',
            color: colorScheme.onSurface,
          ),
        ),
      ),
      body: Consumer<EnvProvider>(
        builder: (context, provider, _) {
          final latest =
              provider.samples.isNotEmpty ? provider.samples.last : null;
          final stats = provider.getDangerStats();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 서비스 토글
              Card(
                color: cardColor,
                elevation: 2,
                child: SwitchListTile(
                  value: provider.serviceRunning,
                  title: Text(
                    "가이드 활성화",
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      color: colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    provider.useDemoMode ? "데모 모드 (5초마다 시뮬레이션)" : "5초마다 측정",
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  onChanged: (v) =>
                      v ? provider.startService() : provider.stopService(),
                ),
              ),

              const SizedBox(height: 16),

              // 최신 센서 값
              if (latest != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: sensorContainerColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.wb_sunny_outlined,
                            color: Colors.orange.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "밝기: ${latest.lux.toStringAsFixed(1)} lux",
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Roboto',
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.volume_up_outlined,
                            color: Colors.blue.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "소음: ${latest.noiseDb.toStringAsFixed(1)} dB",
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Roboto',
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Status message with demo mode indicator
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: provider.useDemoMode
                      ? Colors.amber.withOpacity(isDark ? 0.2 : 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    if (provider.useDemoMode)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.science_outlined,
                          size: 18,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        provider.message,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 파이 차트 섹션
              Text(
                "환경 방해도 분석 (최근 10분)",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 230,
                child: PieChart(
                  PieChartData(
                    centerSpaceRadius: 45,
                    sectionsSpace: 2,
                    sections: _buildPieData(stats, context),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 기준 설명
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: criteriaContainerColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "환경 기준",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto',
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildCriteriaRow(
                      "좋음",
                      "밝기 ≤ 50 lux, 소음 ≤ 40 dB",
                      Colors.green.shade600,
                      colorScheme,
                    ),
                    const SizedBox(height: 4),
                    _buildCriteriaRow(
                      "주의",
                      "밝기 50~80 lux, 소음 40~50 dB",
                      Colors.orange.shade600,
                      colorScheme,
                    ),
                    const SizedBox(height: 4),
                    _buildCriteriaRow(
                      "방해",
                      "밝기 ≥ 80 lux, 소음 ≥ 50 dB",
                      Colors.red.shade600,
                      colorScheme,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 상세 그래프 버튼
              FilledButton.tonal(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LuxNoiseDetailScreen(
                        samples: provider.samples,
                      ),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.show_chart, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "밝기·소음 상세 그래프",
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 오늘의 통계 버튼
              FilledButton.tonal(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DailyStatsScreen(log: provider.localDb),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "오늘의 통계 보기",
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 데이터 삭제 버튼
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  side: BorderSide(color: colorScheme.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("데이터 삭제"),
                      content: const Text("모든 측정 데이터를 삭제하시겠습니까?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text("취소"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(
                            "삭제",
                            style: TextStyle(color: colorScheme.error),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await provider.clearDb();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "로컬 DB 삭제됨",
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              color: colorScheme.onInverseSurface,
                            ),
                          ),
                          backgroundColor: colorScheme.inverseSurface,
                        ),
                      );
                    }
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_outline,
                        size: 20, color: colorScheme.error),
                    const SizedBox(width: 8),
                    Text(
                      "로컬 데이터 삭제",
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 15,
                        color: colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCriteriaRow(String label, String description, Color dotColor,
      ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 5, right: 8),
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Text(
            "$label: $description",
            style: TextStyle(
              fontFamily: 'Roboto',
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
