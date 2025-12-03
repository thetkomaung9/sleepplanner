import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/env_sample.dart';

const _channel = MethodChannel('light_guide_channel');

class EnvProvider extends ChangeNotifier {
  bool _serviceRunning = false;
  String _message = "서비스가 꺼져 있습니다.";
  List<EnvSample> _samples = [];
  List<EnvSample> _localDb = [];
  Timer? _poller;
  bool _useDemoMode = false; // Demo mode when native plugin unavailable

  static const int keepSeconds = 600; // 최근 10분
  static const int keepHours = 24; // 24시간 로그

  bool get serviceRunning => _serviceRunning;
  String get message => _message;
  List<EnvSample> get samples => _samples;
  List<EnvSample> get localDb => _localDb;
  bool get useDemoMode => _useDemoMode;

  EnvProvider() {
    _loadLocalDb();
  }

  // ========== 로컬 DB 관리 ==========
  Future<void> _loadLocalDb() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString("env_history");
      if (raw == null) return;

      final list = jsonDecode(raw) as List;
      _localDb = list.map((e) => EnvSample.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading local DB: $e');
    }
  }

  Future<void> _saveLocalDb() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _localDb.map((e) => e.toJson()).toList();
      await prefs.setString("env_history", jsonEncode(list));
    } catch (e) {
      debugPrint('Error saving local DB: $e');
    }
  }

  Future<void> clearDb() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove("env_history");
      _localDb.clear();
      _samples.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing DB: $e');
    }
  }

  // ========== 서비스 제어 ==========
  Future<void> startService() async {
    try {
      await _channel.invokeMethod("startLightService");
      _serviceRunning = true;
      _useDemoMode = false;
      _message = "실시간 측정 중…";
      _startPolling();
      notifyListeners();
    } on MissingPluginException {
      // Native plugin not available, use demo mode
      _serviceRunning = true;
      _useDemoMode = true;
      _message = "데모 모드로 실행 중 (시뮬레이션)";
      _startDemoPolling();
      notifyListeners();
    } catch (e) {
      _message = "서비스 시작 실패: $e";
      notifyListeners();
    }
  }

  Future<void> stopService() async {
    try {
      if (!_useDemoMode) {
        await _channel.invokeMethod("stopLightService");
      }
    } catch (e) {
      debugPrint('Error stopping native service: $e');
    }
    _poller?.cancel();
    _serviceRunning = false;
    _useDemoMode = false;
    _message = "서비스 중지됨.";
    _samples.clear();
    notifyListeners();
  }

  // ========== 데모 모드 폴링 (시뮬레이션) ==========
  void _startDemoPolling() {
    _poller?.cancel();
    final random = Random();

    _poller = Timer.periodic(const Duration(seconds: 5), (_) async {
      // Generate realistic demo data
      final lux = 20.0 + random.nextDouble() * 100; // 20-120 lux
      final noiseDb = 25.0 + random.nextDouble() * 40; // 25-65 dB

      final sample = EnvSample(DateTime.now(), lux, noiseDb);

      _samples.add(sample);
      _localDb.add(sample);

      // 최근 10분만 유지
      final cutoff =
          DateTime.now().subtract(const Duration(seconds: keepSeconds));
      _samples = _samples.where((s) => s.time.isAfter(cutoff)).toList();

      // 24시간만 유지
      final dayCutoff =
          DateTime.now().subtract(const Duration(hours: keepHours));
      _localDb = _localDb.where((s) => s.time.isAfter(dayCutoff)).toList();

      await _saveLocalDb();
      notifyListeners();
    });
  }

  // ========== 폴링 (5초마다 센서 측정) ==========
  void _startPolling() {
    _poller?.cancel();

    _poller = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final raw = await _channel.invokeMethod("getEnvSamples");
        final data = (raw as List).map((e) {
          final m = Map<String, dynamic>.from(e);
          return EnvSample(
            DateTime.fromMillisecondsSinceEpoch(m["timestampMillis"]),
            (m["lux"] as num).toDouble(),
            (m["noiseDb"] as num).toDouble(),
          );
        }).toList();

        if (data.isEmpty) return;

        _samples.addAll(data);

        // 최근 10분만 유지
        final cutoff =
            DateTime.now().subtract(const Duration(seconds: keepSeconds));
        _samples = _samples.where((s) => s.time.isAfter(cutoff)).toList();

        // 로컬 DB에도 저장
        _localDb.addAll(data);

        // 24시간만 유지
        final dayCutoff =
            DateTime.now().subtract(const Duration(hours: keepHours));
        _localDb = _localDb.where((s) => s.time.isAfter(dayCutoff)).toList();

        await _saveLocalDb();
        notifyListeners();
      } catch (e) {
        debugPrint('Polling error: $e');
      }
    });
  }

  // ========== 환경 방해도 계산 ==========
  int danger(double lux, double db) {
    int l = lux <= 50 ? 0 : (lux < 80 ? 1 : 2);
    int n = db <= 40 ? 0 : (db < 50 ? 1 : 2);
    return max(l, n);
  }

  Map<int, int> getDangerStats() {
    final map = {0: 0, 1: 0, 2: 0};
    for (final s in _samples) {
      map[danger(s.lux, s.noiseDb)] = map[danger(s.lux, s.noiseDb)]! + 1;
    }
    return map;
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }
}
