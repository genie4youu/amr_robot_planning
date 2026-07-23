# Integrated System Model

핵심 subsystem의 입출력이 안정된 후 통합 모델을 둔다.

## 현재 모델

`amr_industrial_supervisor.slx`는 실무형 감독 제어 구조를 학습하기 위한 1차 모델이다.

- 상위 배타 상태: PowerOff, Boot, Operational, ControlledShutdown, FaultLatched, EmergencyStopLatched
- Operational 병렬 영역: Mission, Navigation, Energy, Safety, Health
- 20개 boolean event/condition 입력과 6개 uint8 mode 출력
- 정상 임무, 장애물, 저전압, 장치 고장, 비상정지 stimulus 포함
- 생성 스크립트: `scripts/build_amr_industrial_supervisor.m`
- 검증 스크립트: `scripts/run_industrial_supervisor_scenarios.m`

`amr_industrial_supervisor.slx`는 supervisory logic만 독립 검증하는 core/harness 모델이며, 아래 통합 모델에서 실제 Plant 신호와 함께 실행한다.

## 통합 모델

`amr_integrated_delivery_system.slx`는 Scenario Plant와 두 Stateflow Chart를 한 모델에서 실행한다.

- `ScenarioSupervisor`: 장애물/배터리/경로이탈 복구를 직접 제어
- `NavigationPlant`: LiDAR, A*, local costmap, DWA와 배터리/pose 모델
- `SupervisorAdapter`: plant 신호를 20개 industrial condition으로 변환
- `IndustrialSupervisor`: lifecycle과 Mission/Navigation/Energy/Safety/Health 병렬 mode
- 검증: `scripts/run_integrated_delivery_scenarios.m`
- 다중환경 검증: `scripts/run_integrated_environment_matrix.m`

Scenario code는 Simulink 포트를 늘리지 않고 `1..12`로 인코딩한다. `1..4`는 사무실, `5..8`은 병원, `9..12`는 창고이며 각 묶음 안에서 normal/obstacle/battery/wrong-turn 순서다. Scenario Engine은 이를 environment ID와 scenario ID로 다시 분리해 같은 제어 구조를 세 지도에 적용한다.

2026-07-22 기준 12개 조합 모두 lifecycle `[0 1 2 3 0]`, 최종 위치 오차 약 `0.080 m` 이하, `NavFailed` 없이 PASS했다. 결과는 `results/2026-07-22_integrated_environment_matrix.mat`에 저장한다.

현재 adapter는 scalar port를 사용한다. 다음 버전은 typed bus와 data dictionary로 계약을 고정한다.

목표 최상위 구성:

- Mission Supervisor
- Navigation
- Safety Monitor
- Robot Plant
- Sensors
- Visualization and Logging
