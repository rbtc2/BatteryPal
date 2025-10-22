import 'package:flutter/material.dart';

/// Pro 사용자 전용 고급 분석 섹션
class ProExclusiveSection extends StatelessWidget {
  const ProExclusiveSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withValues(alpha: 0.1),
            Colors.purple.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.purple.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.star,
                  color: Colors.purple,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Pro 전용 고급 분석',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildProFeature('🔮 AI 충전 패턴 예측', '다음 주 충전 패턴을 예측합니다'),
          SizedBox(height: 8),
          _buildProFeature('📊 상세 효율성 분석', '충전 효율을 시간대별로 분석합니다'),
          SizedBox(height: 8),
          _buildProFeature('⚡ 실시간 최적화 제안', '현재 상황에 맞는 충전 최적화를 제안합니다'),
        ],
      ),
    );
  }
  
  Widget _buildProFeature(String title, String description) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 16,
        ),
      ],
    );
  }
}
