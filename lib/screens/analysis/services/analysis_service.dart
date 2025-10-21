import '../../../models/app_models.dart';
import '../../../models/battery_history_models.dart';
import '../../../services/battery_service.dart';
import '../../../services/battery_history_service.dart';
import '../../../services/battery_analysis_engine.dart';
import '../../../services/battery_analysis_chart_service.dart';
import '../models/analysis_models.dart';

/// 분석 탭의 서비스 로직을 관리하는 클래스
class AnalysisService {
  final BatteryService _batteryService = BatteryService();
  final BatteryHistoryService _batteryHistoryService = BatteryHistoryService();

  /// 배터리 분석을 수행하는 메서드
  Future<BatteryAnalysisResult> performBatteryAnalysis({
    Duration analysisPeriod = const Duration(hours: 24),
  }) async {
    final analysisStartTime = DateTime.now();
    
    // 배터리 히스토리 서비스 초기화
    await _batteryHistoryService.initialize();
    
    // 분석 기간 데이터 조회
    final endTime = DateTime.now();
    final startTime = endTime.subtract(analysisPeriod);
    
    final historyData = await _batteryHistoryService.getBatteryHistoryData(
      startTime: startTime,
      endTime: endTime,
    );
    
    if (historyData.isEmpty) {
      throw AnalysisException(
        '아직 충분한 배터리 사용 데이터가 수집되지 않았습니다.\n\n'
        '앱을 설치한 후 ${analysisPeriod.inHours}시간이 지나면 정확한 분석 결과를 제공할 수 있습니다.\n'
        '현재는 배터리 사용 패턴을 수집하고 있습니다.',
      );
    }
    
    // 실제 분석 수행
    final analysis = await BatteryAnalysisEngine.performComprehensiveAnalysis(
      historyData,
      startTime: startTime,
      endTime: endTime,
    );
    
    // 차트 데이터 생성
    final chartData = BatteryAnalysisChartService.convertAnalysisToChartData(
      analysis,
      historyData,
    );
    
    final analysisEndTime = DateTime.now();
    final analysisDuration = analysisEndTime.difference(analysisStartTime);
    
    // 분석 결과 생성
    return BatteryAnalysisResult(
      analysis: analysis,
      chartData: chartData,
      dataPoints: historyData,
      analysisTime: analysisEndTime,
      analysisDuration: analysisDuration,
    );
  }

  /// 현재 배터리 정보를 가져오는 메서드
  Future<BatteryInfo?> getCurrentBatteryInfo() async {
    try {
      await _batteryService.startMonitoring();
      // BatteryService는 스트림 기반이므로 현재 정보를 직접 가져올 수 없음
      // 대신 스트림에서 최신 정보를 받아야 함
      return null; // TODO: 스트림에서 최신 정보를 가져오는 로직 필요
    } catch (e) {
      return null;
    }
  }

  /// 배터리 히스토리 데이터를 가져오는 메서드
  Future<List<BatteryHistoryDataPoint>> getBatteryHistoryData({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    await _batteryHistoryService.initialize();
    return await _batteryHistoryService.getBatteryHistoryData(
      startTime: startTime,
      endTime: endTime,
    );
  }

  /// 서비스 리소스 정리
  void dispose() {
    _batteryService.dispose();
    _batteryHistoryService.dispose();
  }
}

/// 분석 관련 예외 클래스
class AnalysisException implements Exception {
  final String message;
  
  const AnalysisException(this.message);
  
  @override
  String toString() => 'AnalysisException: $message';
}

/// 분석 상태 관리자
class AnalysisStateManager {
  BatteryAnalysisState _state = BatteryAnalysisState.idle;
  BatteryAnalysisResult? _result;
  String? _statusMessage;

  BatteryAnalysisState get state => _state;
  BatteryAnalysisResult? get result => _result;
  String? get statusMessage => _statusMessage;

  /// 분석 상태 변경
  void setState(BatteryAnalysisState newState, {
    BatteryAnalysisResult? result,
    String? statusMessage,
  }) {
    _state = newState;
    _result = result;
    _statusMessage = statusMessage;
  }

  /// 분석 결과 리셋
  void reset() {
    _state = BatteryAnalysisState.idle;
    _result = null;
    _statusMessage = null;
  }

  /// 분석 중인지 확인
  bool get isAnalyzing => _state == BatteryAnalysisState.analyzing;
  
  /// 분석 완료인지 확인
  bool get isCompleted => _state == BatteryAnalysisState.completed;
  
  /// 분석 대기 중인지 확인
  bool get isIdle => _state == BatteryAnalysisState.idle;
}
