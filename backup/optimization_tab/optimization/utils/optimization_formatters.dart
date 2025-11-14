// 최적화 관련 포맷팅 유틸리티 함수들

/// 시간 경과를 "N분 전", "N시간 전", "N일 전" 형식으로 포맷팅
String formatTimeAgo(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inHours < 1) {
    return '${difference.inMinutes}분 전';
  } else if (difference.inHours < 24) {
    return '${difference.inHours}시간 전';
  } else {
    return '${difference.inDays}일 전';
  }
}

/// Duration을 "+N시간 N분" 또는 "+N분" 형식으로 포맷팅
String formatDuration(Duration duration) {
  if (duration.inHours > 0) {
    return '+${duration.inHours}시간 ${duration.inMinutes % 60}분';
  } else {
    return '+${duration.inMinutes}분';
  }
}

/// 저장 시간을 "방금 전", "N분 전", "N시간 전", "N일 전" 형식으로 포맷팅
String formatSavedTime(DateTime savedAt) {
  final now = DateTime.now();
  final difference = now.difference(savedAt);

  if (difference.inDays > 0) {
    return '${difference.inDays}일 전';
  } else if (difference.inHours > 0) {
    return '${difference.inHours}시간 전';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes}분 전';
  } else {
    return '방금 전';
  }
}

