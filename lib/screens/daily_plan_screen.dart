import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sleep_provider.dart';
import '../models/daily_plan.dart';

class DailyPlanScreen extends StatelessWidget {
  const DailyPlanScreen({super.key});

  String _fmt(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
        "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SleepProvider>(context);
    final plan = provider.lastDailyPlan;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Daily Sleep Plan"),
      ),
      body: plan == null
          ? const Center(
              child: Text(
                "아직 Daily Plan 이 없습니다.\n근무 정보를 입력해 계산하세요.",
                textAlign: TextAlign.center,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildMainSleepCard(plan),
                  const SizedBox(height: 16),
                  _buildCaffeineCard(plan),
                  const SizedBox(height: 16),
                  _buildWinddownCard(plan),
                  const SizedBox(height: 16),
                  _buildLightCard(plan),
                  const SizedBox(height: 16),
                  _buildNotesCard(plan),
                ],
              ),
            ),
    );
  }

  Widget _buildMainSleepCard(DailyPlan plan) {
    final dur = plan.mainSleepEnd.difference(plan.mainSleepStart);
    final h = dur.inHours;
    final m = dur.inMinutes.remainder(60);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "🛌 메인 수면 시간",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text("Start: ${_fmt(plan.mainSleepStart)}"),
            Text("End:   ${_fmt(plan.mainSleepEnd)}"),
            const SizedBox(height: 8),
            Text("Duration: ${h}h ${m}m"),
          ],
        ),
      ),
    );
  }

  Widget _buildCaffeineCard(DailyPlan plan) {
    return Card(
      color: Colors.orange.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "☕ 카페인 컷오프",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text("카페인 제한 시작 시간: ${_fmt(plan.caffeineCutoff)}"),
          ],
        ),
      ),
    );
  }

  Widget _buildWinddownCard(DailyPlan plan) {
    return Card(
      color: Colors.blue.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "🌙 취침 준비 시작 시간",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text("Wind-down 시작: ${_fmt(plan.winddownStart)}"),
          ],
        ),
      ),
    );
  }

  Widget _buildLightCard(DailyPlan plan) {
    return Card(
      color: Colors.yellow.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "💡 빛 노출 전략",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...plan.lightPlan.entries
                .map((e) => _buildLightPlanEntry(e.key, e.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildLightPlanEntry(String key, dynamic value) {
    String label;
    Widget valWidget;

    switch (key) {
      case 'strategy':
        label = '전략';
        final v = value?.toString() ?? '';
        String friendly;
        if (v == 'night_shift')
          friendly = '야간 근무';
        else if (v == 'day_shift')
          friendly = '주간 근무';
        else if (v == 'off_day')
          friendly = '비근무일';
        else
          friendly = v;

        valWidget = Row(
          children: [
            const Icon(Icons.swap_horiz, size: 18),
            const SizedBox(width: 8),
            Text(friendly),
          ],
        );
        break;

      case 'light_sensitivity':
        label = '빛 민감도';
        final num? d = (value is num) ? value : null;
        valWidget = Row(children: [
          const Icon(Icons.tune, size: 18),
          const SizedBox(width: 8),
          Text(d != null ? d.toStringAsFixed(2) : value.toString()),
        ]);
        break;

      default:
        // boolean flags like morning_bright_light, evening_dim_light, work_bright_light
        label = key.replaceAll('_', ' ');
        if (value is bool) {
          valWidget = Row(children: [
            Icon(value ? Icons.check_circle : Icons.cancel,
                size: 18, color: value ? Colors.green : Colors.red),
            const SizedBox(width: 8),
            Text(value ? '권장됨' : '권장 안 함'),
          ]);
        } else {
          valWidget = Text(value?.toString() ?? '');
        }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text('- $label',
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(flex: 7, child: valWidget),
        ],
      ),
    );
  }

  Widget _buildNotesCard(DailyPlan plan) {
    return Card(
      color: Colors.green.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "📝 Notes",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...plan.notes.map((n) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(n),
                )),
          ],
        ),
      ),
    );
  }
}
