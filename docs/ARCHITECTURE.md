# 시스템 아키텍처

## 책임 분리

```text
Scenario / Mission Request
          ↓
Stateflow Mission & Recovery Supervisor
          ├─ mission mode
          ├─ navigation mode
          ├─ energy mode
          ├─ safety mode
          └─ health mode
          ↓
Global Planning: Occupancy Grid → Inflation → A* → Smoothing
          ↓
Local Planning: LiDAR → Local Costmap → DWA Rollout
          ↓
Independent Safety Gate
          ↓
Differential-Drive Plant
          ↓
Logging → MATLAB Playback UI
```

Stateflow는 이산 mode orchestration, latch, reset과 recovery 순서를 담당합니다. A*, raycasting, trajectory collision과 연속 제어 수학은 MATLAB 함수에 둡니다. 이렇게 하면 상위 상태기계와 수치 알고리즘을 독립적으로 검사하고 교체할 수 있습니다.

## 코드 패키지

| 패키지 | 책임 |
| --- | --- |
| `amr.common` | 각도 wrapping 등 공통 수학 |
| `amr.modeling` | 차동구동 순·역기구학과 pose 적분 |
| `amr.mapping` | floor map rasterization, 좌표 변환, collision query, log-odds |
| `amr.sensors` | 2D LiDAR, noise/dropout/delay, safety zone와 watchdog |
| `amr.planning` | A*, path smoothing, local costmap, DWA rollout/scoring |
| `amr.localization` | pose EKF prediction/update와 uncertainty health |
| `amr.scenarios` | 환경·상황별 동적 Plant 실행 |
| `amr.ui` | floor map과 simulation log playback |
| `amr.verification` | 연속 선분을 포함한 collision assertion |

## Simulink/Stateflow 모델

### `amr_milestone01.slx`

Stateflow 명령, 차동구동 변환, pose 적분과 로깅을 연결한 가장 작은 수직 절편입니다.

### `amr_scenario_supervisor.slx`

정상 배송, 돌발 장애물, 저전압 복귀, 경로이탈 복구를 실행합니다. 환경과 상황은 하나의 scenario code `1..12`로 전달합니다.

### `amr_industrial_supervisor.slx`

상위 lifecycle과 Operational 내부의 Mission, Navigation, Energy, Safety, Health 병렬 영역을 포함한 감독 제어기입니다.

### `amr_integrated_delivery_system.slx`

Scenario Plant 신호를 adapter로 변환해 Industrial Supervisor의 20개 조건 입력과 연결합니다.

## 지도 계약

모든 합성 지도는 다음 필드를 공유합니다.

- world bounds
- walls와 static obstacles
- dynamic obstacle와 appearance time
- start, goal, charger, wrong-turn pose
- label과 reference route

UI가 그리는 벽과 planner/safety가 사용하는 occupancy grid는 같은 floor-map 정의에서 생성됩니다. 계획 지도는 `0.40 m`, 독립 안전 지도는 `0.30 m`만큼 팽창합니다.

## 센서와 지역계획

LiDAR는 truth occupancy grid에 beam을 투사하지만, 지역 계획기는 전체 truth dynamic map을 직접 받지 않습니다. 정적 local window와 LiDAR에서 관측한 새로운 hit만 local costmap에 표시합니다.

DWA는 dynamic window 안의 후보 명령을 rollout하고 다음 조건을 만족하는 후보만 평가합니다.

- rollout trajectory 비충돌
- braking trajectory 비충돌
- 선속도·각속도와 가속도 한계
- path/goal/heading progress
- 속도 보상과 명령 smoothness

최종 명령 뒤에는 planner와 독립적인 safety gate가 다시 적용됩니다.

## 현재 통합 경계

log-odds mapping과 pose EKF는 단위검사를 통과했지만 전체 Plant에는 아직 연결하지 않았습니다. 현재 global A*는 known static map과 scenario가 제공한 동적 사각형을 사용하고, local DWA는 scan-derived hit를 사용합니다.
