# 13. Delivery, Battery, and Docking Extensions

## 목적

기본 내비게이션이 안정된 후 배송 로봇다운 작업 처리, 배터리, 충전 복귀와 도킹을 추가한다.

## 진입 조건

- [11_system_integration](../11_system_integration/11_system_integration.md) 정상 배송 baseline 통과
- [12_verification](../12_verification/12_verification.md) 핵심 회귀 시나리오 통과

## 학습 및 작업 순서

1. [01_배송임무_배터리_도킹_이론](01_배송임무_배터리_도킹_이론.md)
2. [02_배송확장_구현_및_검증](02_배송확장_구현_및_검증.md)
3. [13_delivery_extensions_진행결과](13_delivery_extensions_진행결과.md)

## 결과물

- order와 payload 상태
- 배터리 SOC와 에너지 소비
- 임무 수락 가능성 판단
- 충전소 복귀
- coarse navigation + fine docking
- 배송 관련 Stateflow 상태

## 완료 조건

- [ ] 배터리가 충분할 때 배송을 완료한다.
- [ ] 배터리가 부족하면 새 임무를 거부하거나 안전하게 복귀한다.
- [ ] docking 실패에 timeout과 retry가 있다.
- [ ] payload 상태와 로봇 위치 상태가 모순되지 않는다.
