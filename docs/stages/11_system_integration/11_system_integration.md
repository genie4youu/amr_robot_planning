# 11. System Integration

## 목적

검증된 subsystem을 하나의 Simulink/Stateflow 시스템으로 연결하고 데이터 흐름, 실행 순서, mode 전환을 안정화한다.

## 진입 조건

- [02_robot_modeling](../02_robot_modeling/02_robot_modeling.md)~[10_safety_recovery](../10_safety_recovery/10_safety_recovery.md) 중 통합에 포함할 기능의 완료 조건 충족
- subsystem별 MATLAB 기준 결과 존재

## 학습 및 작업 순서

1. [01_통합아키텍처와_인터페이스_이론](01_통합아키텍처와_인터페이스_이론.md)
2. [02_통합모델_구현_및_검증](02_통합모델_구현_및_검증.md)
3. [11_system_integration_진행결과](11_system_integration_진행결과.md)

## 결과물

- `amr_system.slx`
- 공통 parameter와 bus 정의
- subsystem execution/sample-time 표
- mapping mode와 delivery mode
- logging과 시각화
- 정상 배송 통합 시나리오

## 완료 조건

- [ ] ground truth와 estimated pose 경계가 유지된다.
- [ ] 모든 주요 interface의 단위, frame, valid 규칙이 일치한다.
- [ ] 초기화 순서와 mode 전환이 결정적이다.
- [ ] 정상 배송과 안전 정지 시나리오가 반복 실행된다.
- [ ] 모델을 새 MATLAB 세션에서 재현할 수 있다.

## 다음 단계

[12_verification](../12_verification/12_verification.md)
