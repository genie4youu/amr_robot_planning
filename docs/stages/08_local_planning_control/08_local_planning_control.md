# 08. Local Planning and Motion Control

## 목적

로봇 주변의 동적 장애물을 반영하고 운동 제약을 만족하는 `v`, `omega` 명령을 선택한다.

## 진입 조건

- [02_robot_modeling](../02_robot_modeling/02_robot_modeling.md) 완료
- [03_sensor_simulation](../03_sensor_simulation/03_sensor_simulation.md) 완료
- [07_global_planning](../07_global_planning/07_global_planning.md) 완료

## 학습 및 작업 순서

1. [01_LocalCostmap_PurePursuit_DWA_이론](01_LocalCostmap_PurePursuit_DWA_이론.md)
2. [02_지역계획과_제어_구현_및_검증](02_지역계획과_제어_구현_및_검증.md)
3. [08_local_planning_control_진행결과](08_local_planning_control_진행결과.md)

## 결과물

- rolling local costmap
- Pure Pursuit 기준 제어기
- DWA velocity search
- footprint collision check
- velocity shaping과 wheel command

## 완료 조건

- [ ] 장애물이 없을 때 global path를 추종한다.
- [ ] 현재 속도와 가속도에서 불가능한 명령을 선택하지 않는다.
- [ ] 정지할 수 없는 충돌 후보를 제거한다.
- [ ] 모든 후보가 위험하면 0 속도를 반환한다.
- [ ] Pure Pursuit와 DWA 결과를 비교했다.

## 다음 단계

[09_stateflow_supervisor](../09_stateflow_supervisor/09_stateflow_supervisor.md) · [10_safety_recovery](../10_safety_recovery/10_safety_recovery.md)
