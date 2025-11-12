import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/battery_history_models.dart';

/// 데이터베이스 경로 관리 클래스
/// 플랫폼별 데이터베이스 파일 경로를 관리합니다.
class DatabasePathManager {
  /// 싱글톤 인스턴스
  static final DatabasePathManager _instance = DatabasePathManager._internal();
  factory DatabasePathManager() => _instance;
  DatabasePathManager._internal();

  /// 데이터베이스 경로를 가져옵니다.
  /// 
  /// 플랫폼에 관계없이 애플리케이션 문서 디렉토리에 데이터베이스 파일을 생성합니다.
  /// 
  /// Returns: 데이터베이스 파일의 전체 경로
  Future<String> getDatabasePath() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return join(documentsDirectory.path, BatteryHistoryDatabaseConfig.databaseName);
  }
}

