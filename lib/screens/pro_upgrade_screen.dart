import 'package:flutter/material.dart';
import '../widgets/common/common_widgets.dart';
import '../constants/app_constants.dart';

/// Pro 업그레이드 화면
/// 기본 기능과 Pro 기능을 비교하고 결제로 넘어갈 수 있는 화면
class ProUpgradeScreen extends StatelessWidget {
  final VoidCallback? onUpgrade;

  const ProUpgradeScreen({
    super.key,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pro 업그레이드'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero 섹션
            _buildHeroSection(context),
            
            const SizedBox(height: 32),
            
            // 기능 비교 테이블
            _buildFeatureComparison(context),
            
            const SizedBox(height: 32),
            
            // 가격 정보
            _buildPricingSection(context),
            
            const SizedBox(height: 32),
            
            // 결제 버튼
            _buildUpgradeButton(context),
            
            const SizedBox(height: 16),
            
            // 이용 약관 링크
            _buildTermsLinks(context),
          ],
        ),
      ),
    );
  }

  /// Hero 섹션 위젯
  Widget _buildHeroSection(BuildContext context) {
    return CustomCard(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star,
                color: Colors.amber,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'BatteryPal Pro',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '배터리 관리를 한 단계 업그레이드하세요',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 기능 비교 테이블 위젯
  Widget _buildFeatureComparison(BuildContext context) {
    final features = [
      _FeatureItem(
        title: '배터리 부스트',
        freeText: '일일 3회 제한',
        proText: '무제한',
      ),
      _FeatureItem(
        title: '고급 분석',
        freeText: '제한적',
        proText: '전체 데이터',
      ),
      _FeatureItem(
        title: '배터리 건강도',
        freeText: '기본 정보',
        proText: '상세 분석 및 트렌드',
      ),
      _FeatureItem(
        title: '앱 사용량 분석',
        freeText: '상위 5개 앱만',
        proText: '모든 앱 분석',
      ),
      _FeatureItem(
        title: '자동 최적화',
        freeText: '없음',
        proText: '스마트 최적화',
      ),
      _FeatureItem(
        title: '충전 패턴 분석',
        freeText: '없음',
        proText: '상세 패턴 및 인사이트',
      ),
      _FeatureItem(
        title: 'AI 인사이트',
        freeText: '없음',
        proText: '개인화된 추천',
      ),
      _FeatureItem(
        title: '데이터 백업',
        freeText: '없음',
        proText: '클라우드 백업',
      ),
      _FeatureItem(
        title: '우선 지원',
        freeText: '일반 지원',
        proText: '우선 지원',
      ),
      _FeatureItem(
        title: '광고',
        freeText: '있음',
        proText: '없음',
      ),
    ];

    return CustomCard(
      elevation: 2,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '기능 비교',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          // 테이블 헤더
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  '기능',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  '기본',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Pro',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.amber,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const Divider(height: 24),
          
          // 기능 목록
          ...features.map((feature) => _buildFeatureRow(context, feature)),
        ],
      ),
    );
  }

  /// 기능 행 위젯
  Widget _buildFeatureRow(BuildContext context, _FeatureItem feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              feature.title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              feature.freeText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              feature.proText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.amber,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 가격 정보 섹션
  Widget _buildPricingSection(BuildContext context) {
    return CustomCard(
      elevation: 2,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '가격 정보',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '월간 구독',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${AppConstants.proMonthlyPrice.toInt().toStringAsFixed(0)}원',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: const Text(
                  '인기',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          const Divider(),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Icon(
                Icons.check_circle,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '언제든지 취소 가능',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Row(
            children: [
              Icon(
                Icons.check_circle,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '7일 무료 체험',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Row(
            children: [
              Icon(
                Icons.check_circle,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '첫 달 할인 적용',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 업그레이드 버튼
  Widget _buildUpgradeButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          // TODO: 실제 결제 프로세스로 연결
          // 현재는 콜백 실행 또는 다이얼로그 표시
          if (onUpgrade != null) {
            onUpgrade!();
          } else {
            _showPaymentConfirmation(context);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment, size: 24),
            SizedBox(width: 8),
            Text(
              'Pro로 업그레이드',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 이용 약관 링크
  Widget _buildTermsLinks(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () {
            // TODO: 이용약관 페이지로 이동
          },
          child: const Text(
            '이용약관',
            style: TextStyle(fontSize: 12),
          ),
        ),
        Text(
          '|',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
        ),
        TextButton(
          onPressed: () {
            // TODO: 개인정보처리방침 페이지로 이동
          },
          child: const Text(
            '개인정보처리방침',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  /// 결제 확인 다이얼로그
  void _showPaymentConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pro 업그레이드'),
        content: Text(
          'Pro 구독을 시작하시겠습니까?\n\n'
          '7일 무료 체험 후 ${AppConstants.proMonthlyPrice.toInt()}원이 결제됩니다.\n'
          '언제든지 취소할 수 있습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: 실제 결제 프로세스 시작
              // Google Play Billing 또는 App Store Connect 연동
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('결제 프로세스 시작 (스켈레톤)'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('구독 시작'),
          ),
        ],
      ),
    );
  }
}

/// 기능 비교 아이템 모델
class _FeatureItem {
  final String title;
  final String freeText;
  final String proText;

  _FeatureItem({
    required this.title,
    required this.freeText,
    required this.proText,
  });
}

