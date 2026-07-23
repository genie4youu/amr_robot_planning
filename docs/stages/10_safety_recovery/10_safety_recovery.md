# 10. Safety Monitoring and Recovery

## 목적

지역 플래너와 별도로 최종 속도 명령을 감시하고, 진행 실패와 subsystem failure에 대해 단계적 복구를 수행한다.

## 진입 조건

- [03_sensor_simulation](../03_sensor_simulation/03_sensor_simulation.md) 완료
- [08_local_planning_control](../08_local_planning_control/08_local_planning_control.md) 완료
- [09_stateflow_supervisor](../09_stateflow_supervisor/09_stateflow_supervisor.md) interface 확정

## 학습 및 작업 순서

1. [01_SafetyGate_Watchdog_Recovery_이론](01_SafetyGate_Watchdog_Recovery_이론.md)
2. [02_안전감시와_복구_구현_및_검증](02_안전감시와_복구_구현_및_검증.md)
3. [10_safety_recovery_진행결과](10_safety_recovery_진행결과.md)

## 결과물

- slowdown/stop zone
- time-to-collision monitor
- sensor/command watchdog
- localization health와 progress checker
- recovery ladder
- latched emergency stop/reset

## 완료 조건

- [ ] 위험한 장애물에서 planner 명령과 무관하게 정지한다.
- [ ] stale LiDAR 또는 pose에서 정지한다.
- [ ] 정지 원인과 recovery 결과가 기록된다.
- [ ] recovery retry가 무한 반복되지 않는다.
- [ ] emergency reset은 명시적이고 안전 조건에서만 허용된다.

## 다음 단계

[11_system_integration](../11_system_integration/11_system_integration.md)
