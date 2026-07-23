# 12. Verification and Experiments

## 목적

각 알고리즘과 통합 시스템이 의도대로 동작하는지 재현 가능한 MATLAB 검증과 정량 지표로 확인한다.

## 진입 조건

- 이 단계는 00부터 병행한다.
- 통합 검증은 [11_system_integration](../11_system_integration/11_system_integration.md) 이후 수행한다.

## 학습 및 작업 순서

1. [01_검증전략과_성능지표_이론](01_검증전략과_성능지표_이론.md)
2. [02_자동실험과_회귀검증_구현](02_자동실험과_회귀검증_구현.md)
3. [12_verification_진행결과](12_verification_진행결과.md)

## 결과물

- unit verification scripts
- scenario runner
- metric functions
- regression scenario 목록
- Monte Carlo summary
- 단계별 완료 보고서

## 완료 조건

- [ ] 각 핵심 함수에 정상·경계·오류 입력 검증이 있다.
- [ ] 모든 시나리오가 한 명령으로 실행 가능하다.
- [ ] random seed와 parameter가 결과에 기록된다.
- [ ] 실패 원인이 자동 판정 결과에 포함된다.
- [ ] 이전 baseline과 비교할 수 있다.

## 다음 단계

[13_delivery_extensions](../13_delivery_extensions/13_delivery_extensions.md) 또는 프로젝트 baseline 고정
