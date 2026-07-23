# 09. Stateflow Mission Supervisor

## 목적

Stateflow를 최상위 제어기로 사용해 배송 임무, 내비게이션 요청, 복구, health 상태를 계층적으로 관리한다.

## 진입 조건

- [07_global_planning](../07_global_planning/07_global_planning.md)의 planner status 정의 완료
- [08_local_planning_control](../08_local_planning_control/08_local_planning_control.md)의 controller status 정의 완료

## 학습 및 작업 순서

1. [01_계층병렬상태와_임무제어_이론](01_계층병렬상태와_임무제어_이론.md)
2. [02_Stateflow_Supervisor_구현_및_검증](02_Stateflow_Supervisor_구현_및_검증.md)
3. [09_stateflow_supervisor_진행결과](09_stateflow_supervisor_진행결과.md)

## 결과물

- mission state hierarchy
- navigation request/feedback 계약
- health monitoring region
- timeout, retry, cancel, preemption
- Stateflow 상태 및 전이 logging

## 완료 조건

- [ ] 정상 배송 순서가 결정적이다.
- [ ] navigation failure가 recovery 또는 abort로 전달된다.
- [ ] 새 목표와 취소 요청의 우선순위가 명확하다.
- [ ] health fault가 mission보다 높은 우선순위를 가진다.
- [ ] 순간적인 센서 glitch가 즉시 fault 전이를 만들지 않는다.

## 다음 단계

[10_safety_recovery](../10_safety_recovery/10_safety_recovery.md)
