import 'package:flutter/material.dart';
import '../../widgets/common/common_widgets.dart';
import '../../utils/dialog_utils.dart';
import '../../constants/app_constants.dart';

/// Pro 업그레이드 카드 위젯
class ProUpgradeCard extends StatelessWidget {
  final VoidCallback onUpgrade;

  const ProUpgradeCard({
    super.key,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Pro 업그레이드',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                '무제한 배터리 부스트와 고급 분석 기능을 사용하세요',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => DialogUtils.showSettingsProUpgradeDialog(
                        context,
                        onUpgrade: onUpgrade,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Pro로 업그레이드',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pro 설정 섹션 위젯
class ProSettingsSection extends StatelessWidget {
  const ProSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Pro 설정',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.auto_awesome),
            title: const Text('자동 최적화'),
            subtitle: const Text('켜짐'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.notifications_active),
            title: const Text('고급 알림'),
            subtitle: const Text('켜짐'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.cloud_sync),
            title: const Text('데이터 백업'),
            subtitle: const Text('켜짐'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.widgets),
            title: const Text('위젯 설정'),
            subtitle: const Text('홈 화면 위젯'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

/// Pro 구독 관리 카드 위젯
class ProSubscriptionCard extends StatelessWidget {
  const ProSubscriptionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      elevation: 2,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.star,
                color: Colors.amber,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Pro 구독 관리',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '연간 구독 (2024.12.31까지)',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '월 ${AppConstants.proMonthlyPrice.toInt()}원',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              TextButton(
                onPressed: () => DialogUtils.showSubscriptionDialog(context),
                child: const Text('관리'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
