# 검증 구조

Simulink Test 없이 기본 MATLAB 스크립트와 `assert`를 사용한다.

```text
unit/       순수 MATLAB 함수의 작은 수치 검증
scenarios/  Simulink 통합 시나리오 실행과 판정
```

테스트는 입력, 기대 결과, tolerance, random seed를 명시한다.
