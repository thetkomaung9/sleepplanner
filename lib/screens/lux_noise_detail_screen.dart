import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/env_sample.dart';

class LuxNoiseDetailScreen extends StatelessWidget {
  final List<EnvSample> samples;

  const LuxNoiseDetailScreen({super.key, required this.samples});

  static const int keepSeconds = 600;

  List<EnvSample> get _trim {
    final cutoff =
        DateTime.now().subtract(const Duration(seconds: keepSeconds));
    return samples.where((s) => s.time.isAfter(cutoff)).toList();
  }

  List<FlSpot> _lux(List<EnvSample> s) {
    final base = DateTime.now().subtract(const Duration(seconds: keepSeconds));
    return s
        .map(
            (e) => FlSpot(e.time.difference(base).inMilliseconds / 1000, e.lux))
        .toList();
  }

  List<FlSpot> _noise(List<EnvSample> s) {
    final base = DateTime.now().subtract(const Duration(seconds: keepSeconds));
    return s
        .map((e) =>
            FlSpot(e.time.difference(base).inMilliseconds / 1000, e.noiseDb))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final data = _trim;
    final lux = _lux(data);
    final noise = _noise(data);

    double minLux = lux.isEmpty ? 0 : lux.map((e) => e.y).reduce(min);
    double maxLux = lux.isEmpty ? 100 : lux.map((e) => e.y).reduce(max);

    double minNoise = noise.isEmpty ? 20 : noise.map((e) => e.y).reduce(min);
    double maxNoise = noise.isEmpty ? 60 : noise.map((e) => e.y).reduce(max);

    if (maxLux - minLux < 30) maxLux = minLux + 30;
    if (maxNoise - minNoise < 20) maxNoise = minNoise + 20;

    // Theme-aware chart colors
    final gridColor = colorScheme.outlineVariant.withOpacity(0.5);
    final axisLabelColor = colorScheme.onSurfaceVariant;
    final luxColor = Colors.orange.shade600;
    final noiseColor = Colors.blue.shade600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "상세 그래프 (최근 10분)",
          style: TextStyle(
            fontFamily: 'Roboto',
            color: colorScheme.onSurface,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Empty state message
          if (data.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.show_chart,
                    size: 64,
                    color: colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "데이터가 없습니다",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "가이드를 활성화하면 측정 데이터가 표시됩니다.",
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

          if (data.isNotEmpty) ...[
            // Lux Chart Section
            Row(
              children: [
                Icon(Icons.wb_sunny_outlined, color: luxColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  "밝기 (Lux)",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto',
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 260,
              padding: const EdgeInsets.only(right: 16, top: 16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: LineChart(
                LineChartData(
                  clipData: const FlClipData.all(),
                  minX: 0,
                  maxX: 600,
                  minY: minLux,
                  maxY: maxLux,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: (maxLux - minLux) / 4,
                    verticalInterval: 120,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: gridColor,
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: gridColor,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: lux,
                      isCurved: true,
                      color: luxColor,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: luxColor.withOpacity(0.1),
                      ),
                    )
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        interval: (maxLux - minLux) / 4,
                        getTitlesWidget: (v, meta) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            "${v.toInt()}",
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'Roboto',
                              color: axisLabelColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 120,
                        reservedSize: 30,
                        getTitlesWidget: (v, meta) => Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            "${(v ~/ 60)}m",
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'Roboto',
                              color: axisLabelColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Noise Chart Section
            Row(
              children: [
                Icon(Icons.volume_up_outlined, color: noiseColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  "소음 (dB)",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto',
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 260,
              padding: const EdgeInsets.only(right: 16, top: 16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: LineChart(
                LineChartData(
                  clipData: const FlClipData.all(),
                  minX: 0,
                  maxX: 600,
                  minY: minNoise,
                  maxY: maxNoise,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: (maxNoise - minNoise) / 4,
                    verticalInterval: 120,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: gridColor,
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: gridColor,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: noise,
                      isCurved: true,
                      color: noiseColor,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: noiseColor.withOpacity(0.1),
                      ),
                    )
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        interval: (maxNoise - minNoise) / 4,
                        getTitlesWidget: (v, meta) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            "${v.toInt()}",
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'Roboto',
                              color: axisLabelColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 120,
                        reservedSize: 30,
                        getTitlesWidget: (v, meta) => Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            "${(v ~/ 60)}m",
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'Roboto',
                              color: axisLabelColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
