# 이론 및 단계별 학습 색인

각 단계 폴더는 `단계 개요 → 이론 → 구현 및 검증 → 진행 결과` 순서로 구성됩니다.

| 단계 | 주제 | 핵심 이론 |
| ---: | --- | --- |
| 00 | [프로젝트 설정](stages/00_project_setup/00_project_setup.md) | 단위, 인터페이스, 재현 가능한 실험 규칙 |
| 01 | [수학·좌표계·시간](stages/01_math_frames_timing/01_math_frames_timing.md) | SE(2), world/base/sensor frame, angle wrapping, multirate |
| 02 | [로봇 모델링](stages/02_robot_modeling/02_robot_modeling.md) | 차동구동 기구학, 이산 pose 적분, actuator limit |
| 03 | [센서 시뮬레이션](stages/03_sensor_simulation/03_sensor_simulation.md) | LiDAR raycasting, noise, dropout, delay, freshness |
| 04 | [Mapping](stages/04_mapping/04_mapping.md) | occupancy grid, inverse sensor model, log-odds |
| 05 | [Localization](stages/05_localization/05_localization.md) | odometry, EKF covariance, MCL 개념 |
| 06 | [SLAM](stages/06_slam/06_slam.md) | scan matching, loop closure, pose graph |
| 07 | [전역 경로계획](stages/07_global_planning/07_global_planning.md) | costmap inflation, A*, heuristic, smoothing |
| 08 | [지역계획과 제어](stages/08_local_planning_control/08_local_planning_control.md) | local costmap, Pure Pursuit, DWA |
| 09 | [Stateflow Supervisor](stages/09_stateflow_supervisor/09_stateflow_supervisor.md) | 계층 OR 상태, 병렬 AND 영역, event/condition |
| 10 | [안전과 복구](stages/10_safety_recovery/10_safety_recovery.md) | safety gate, watchdog, progress checker, recovery |
| 11 | [시스템 통합](stages/11_system_integration/11_system_integration.md) | Plant/Supervisor adapter와 통합 순서 |
| 12 | [검증](stages/12_verification/12_verification.md) | scenario matrix, pass/fail metric, regression |
| 13 | [배송 확장](stages/13_delivery_extensions/13_delivery_extensions.md) | 배터리, 충전 복귀, 도킹과 임무 확장 |

## 바로 읽을 이론 문서

- [SE(2) 좌표변환과 시간](stages/01_math_frames_timing/01_SE2_좌표변환과_시간이론.md)
- [차동구동과 구동계](stages/02_robot_modeling/01_차동구동과_구동계_이론.md)
- [LiDAR raycasting과 센서 모델](stages/03_sensor_simulation/01_센서모델과_LiDAR_Raycasting_이론.md)
- [점유격자와 log-odds](stages/04_mapping/01_점유격자와_LogOdds_이론.md)
- [Odometry, EKF, MCL](stages/05_localization/01_Odometry_EKF_MCL_이론.md)
- [Scan matching, loop closure, pose graph](stages/06_slam/01_ScanMatching_LoopClosure_PoseGraph_이론.md)
- [Costmap, A*, path smoothing](stages/07_global_planning/01_Costmap_AStar_PathSmoothing_이론.md)
- [Local costmap, Pure Pursuit, DWA](stages/08_local_planning_control/01_LocalCostmap_PurePursuit_DWA_이론.md)
- [계층·병렬 Stateflow](stages/09_stateflow_supervisor/01_계층병렬상태와_임무제어_이론.md)
- [Safety gate, watchdog, recovery](stages/10_safety_recovery/01_SafetyGate_Watchdog_Recovery_이론.md)
- [통합 아키텍처와 인터페이스](stages/11_system_integration/01_통합아키텍처와_인터페이스_이론.md)
- [검증 전략과 성능 지표](stages/12_verification/01_검증전략과_성능지표_이론.md)
- [배송 임무, 배터리와 도킹](stages/13_delivery_extensions/01_배송임무_배터리_도킹_이론.md)

구현 범위와 남은 작업은 [현재 진행 상태](PROGRESS.md), 설계 선택의 이유는 [ADR 기록](DECISIONS.md)에서 확인할 수 있습니다.
