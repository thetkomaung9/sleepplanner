import 'dart:math';
import 'package:flutter/material.dart';
import '../models/env_sample.dart';

class DailyStatsScreen extends StatelessWidget {
  final List<EnvSample> log;

  const DailyStatsScreen({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (log.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            "오늘의 통계",
            style: TextStyle(fontFamily: 'Roboto'),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.insert_chart_outlined,
                size: 64,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                "기록이 없습니다.",
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final avgLux = log.map((e) => e.lux).reduce((a, b) => a + b) / log.length;
    final avgNoise =
        log.map((e) => e.noiseDb).reduce((a, b) => a + b) / log.length;

    final maxLux = log.map((e) => e.lux).reduce(max);
    final maxNoise = log.map((e) => e.noiseDb).reduce(max);

    int good = 0, warn = 0, bad = 0;

    for (var s in log) {
      int l = s.lux <= 50 ? 0 : (s.lux < 80 ? 1 : 2);
      int n = s.noiseDb <= 40 ? 0 : (s.noiseDb < 50 ? 1 : 2);
      int d = max(l, n);

      if (d == 0) good++;
      if (d == 1) warn++;
      if (d == 2) bad++;
    }

    // Theme-aware status colors
    final goodColor = colorScheme.brightness == Brightness.dark
        ? Colors.green.shade300
        : Colors.green.shade700;
    final warnColor = colorScheme.brightness == Brightness.dark
        ? Colors.orange.shade300
        : Colors.orange.shade700;
    final badColor = colorScheme.brightness == Brightness.dark
        ? Colors.red.shade300
        : Colors.red.shade700;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "오늘의 환경 통계",
          style: TextStyle(fontFamily: 'Roboto'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary Card
          Card(
            color: colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    size: 32,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "오늘 측정 수: ${log.length}회",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Roboto',
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Light Stats Card
          Card(
            color: colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.light_mode_outlined,
                        color: colorScheme.tertiary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "밝기 (Lux)",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Roboto',
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildStatRow(
                    "평균",
                    "${avgLux.toStringAsFixed(1)} lux",
                    colorScheme,
                  ),
                  const SizedBox(height: 8),
                  _buildStatRow(
                    "최대",
                    "${maxLux.toStringAsFixed(1)} lux",
                    colorScheme,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Noise Stats Card
          Card(
            color: colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.volume_up_outlined,
                        color: colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "소음 (dB)",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Roboto',
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildStatRow(
                    "평균",
                    "${avgNoise.toStringAsFixed(1)} dB",
                    colorScheme,
                  ),
                  const SizedBox(height: 8),
                  _buildStatRow(
                    "최대",
                    "${maxNoise.toStringAsFixed(1)} dB",
                    colorScheme,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Status Summary Card
          Card(
            color: colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.pie_chart_outline,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "환경 상태 분포",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Roboto',
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildStatusRow(
                    Icons.check_circle_outline,
                    "좋음",
                    "$good 회",
                    goodColor,
                    colorScheme,
                  ),
                  const SizedBox(height: 12),
                  _buildStatusRow(
                    Icons.warning_amber_outlined,
                    "주의",
                    "$warn 회",
                    warnColor,
                    colorScheme,
                  ),
                  const SizedBox(height: 12),
                  _buildStatusRow(
                    Icons.cancel_outlined,
                    "방해",
                    "$bad 회",
                    badColor,
                    colorScheme,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontFamily: 'Roboto',
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            fontFamily: 'Roboto',
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(
    IconData icon,
    String label,
    String count,
    Color statusColor,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        Icon(icon, color: statusColor, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Roboto',
              color: colorScheme.onSurface,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Roboto',
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }
}
