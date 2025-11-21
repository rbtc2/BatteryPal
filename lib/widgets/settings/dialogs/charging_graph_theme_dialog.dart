import 'package:flutter/material.dart';
import '../../../models/models.dart';
import 'widgets/theme_preview_card.dart';

/// 충전 그래프 테마 선택 다이얼로그
/// PageView 기반 미리보기 UI
class ChargingGraphThemeDialog extends StatefulWidget {
  final ChargingGraphTheme initialTheme;
  final ValueChanged<ChargingGraphTheme> onThemeSelected;

  const ChargingGraphThemeDialog({
    super.key,
    required this.initialTheme,
    required this.onThemeSelected,
  });

  static void show(
    BuildContext context,
    ChargingGraphTheme initialTheme,
    ValueChanged<ChargingGraphTheme> onThemeSelected,
  ) {
    showDialog(
      context: context,
      builder: (context) => ChargingGraphThemeDialog(
        initialTheme: initialTheme,
        onThemeSelected: onThemeSelected,
      ),
    );
  }

  @override
  State<ChargingGraphThemeDialog> createState() => _ChargingGraphThemeDialogState();
}

class _ChargingGraphThemeDialogState extends State<ChargingGraphThemeDialog> with TickerProviderStateMixin {
  late PageController _pageController;
  late int _currentPageIndex;
  late ChargingGraphTheme _selectedTheme;
  late AnimationController _animationController;
  double _animationValue = 0.0;

  // 구현된 테마만 필터링
  List<ChargingGraphTheme> get _implementedThemes {
    return ChargingGraphTheme.values.where((theme) => _isThemeImplemented(theme)).toList();
  }

  @override
  void initState() {
    super.initState();
    
    // 초기 테마가 스켈레톤 테마인 경우, 구현된 테마로 변경
    final initialTheme = _isThemeImplemented(widget.initialTheme)
        ? widget.initialTheme
        : ChargingGraphTheme.ecg;
    
    _selectedTheme = initialTheme;
    _currentPageIndex = _implementedThemes.indexOf(initialTheme);
    if (_currentPageIndex < 0) {
      _currentPageIndex = 0;
      _selectedTheme = _implementedThemes[0];
    }
    
    _pageController = PageController(initialPage: _currentPageIndex);
    
    // 애니메이션 컨트롤러 (그래프 애니메이션용)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    
    _animationController.addListener(() {
      setState(() {
        _animationValue = _animationController.value;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// 테마가 구현 완료되었는지 확인
  bool _isThemeImplemented(ChargingGraphTheme theme) {
    switch (theme) {
      case ChargingGraphTheme.ecg:
      case ChargingGraphTheme.spectrum:
      case ChargingGraphTheme.wave:
      case ChargingGraphTheme.aurora:
        return true;
    }
  }

  /// 이전 페이지로 이동
  void _previousPage() {
    if (_currentPageIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// 다음 페이지로 이동
  void _nextPage() {
    if (_currentPageIndex < _implementedThemes.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// 페이지 변경 처리
  void _onPageChanged(int index) {
    setState(() {
      _currentPageIndex = index;
      _selectedTheme = _implementedThemes[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_implementedThemes.isEmpty) {
      return AlertDialog(
        title: const Text('충전 그래프 테마'),
        content: const Text('사용 가능한 테마가 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      );
    }

    final currentTheme = _implementedThemes[_currentPageIndex];
    final canGoPrevious = _currentPageIndex > 0;
    final canGoNext = _currentPageIndex < _implementedThemes.length - 1;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.palette),
          SizedBox(width: 8),
          Text('충전 그래프 테마'),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 네비게이션 바 (테마 이름과 좌우 버튼)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 좌측 버튼
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: canGoPrevious ? _previousPage : null,
                  style: IconButton.styleFrom(
                    backgroundColor: canGoPrevious
                        ? Theme.of(context).colorScheme.surfaceContainerHighest
                        : Colors.transparent,
                  ),
                ),
                // 테마 이름
                Expanded(
                  child: Text(
                    currentTheme.displayName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // 우측 버튼
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: canGoNext ? _nextPage : null,
                  style: IconButton.styleFrom(
                    backgroundColor: canGoNext
                        ? Theme.of(context).colorScheme.surfaceContainerHighest
                        : Colors.transparent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // PageView (미리보기)
            SizedBox(
              height: 320,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _implementedThemes.length,
                itemBuilder: (context, index) {
                  final theme = _implementedThemes[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ThemePreviewCard(
                      theme: theme,
                      animationValue: _animationValue,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // 페이지 인디케이터
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _implementedThemes.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == _currentPageIndex
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () {
            widget.onThemeSelected(_selectedTheme);
            Navigator.of(context).pop();
          },
          child: const Text('확인'),
        ),
      ],
    );
  }
}
