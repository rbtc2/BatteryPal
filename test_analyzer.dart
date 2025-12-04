// 테스트 파일 - VS Code Analyzer 감지 확인용
class TestClass {
  // 이 필드는 사용되지 않아야 unused_field 경고가 발생합니다
  int unusedField = 0;
  
  // 이 메서드는 사용되지 않아야 unused_element 경고가 발생합니다
  void unusedMethod() {}
  
  void test() {
    // 사용되지 않는 변수
    int unused = 0;
  }
}

