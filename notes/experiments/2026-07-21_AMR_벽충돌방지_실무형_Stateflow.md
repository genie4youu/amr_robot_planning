# AMR 벽 충돌 방지와 실무형 Stateflow 1차 구현

## 문제

기존 Scenario Lab의 벽은 UI 도형일 뿐 planner와 연결되지 않았다. 기준 waypoint 일부가 내부 벽을 통과했는데도 시뮬레이션은 성공으로 판정했다. 이는 명백한 모델 오류다.

## 수정

- floor-map 벽과 장애물을 `10 cells/m` occupancy grid로 변환
- 계획 지도 `0.40 m`, 독립 안전 지도 `0.30 m` 팽창
- 8-connected A*와 diagonal corner-cut 금지
- line-of-sight smoothing 후 모든 경로 선분 재검사
- 각 시뮬레이션 이동 명령 직전에 다음 pose 선분을 safety gate에서 확인
- playback 전체 pose와 샘플 사이 선분을 별도 verification 함수로 재검사

## Stateflow 확장

`amr_industrial_supervisor.slx`를 만들어 top-level lifecycle과 Operational 내부 5개 병렬 영역을 분리했다. 정상, 장애물, 배터리, health fault, emergency stop 시나리오를 stimulus로 자동 실행한다.

## 결과

- 주행 4개 시나리오 PASS, 모두 `CollisionFree=true`
- Industrial Supervisor 5개 시나리오 PASS
- Stateflow/Simulink 구조 검사 healthy
- 새 UI 캡처: `projects/indoor_delivery_amr/results/2026-07-21_scenario_ui_collision_free.png`
- mode 그림: `projects/indoor_delivery_amr/results/2026-07-21_industrial_supervisor_modes.png`

## 남은 제한

- 장애물 발생 신호는 아직 실제 LiDAR가 아니라 deterministic injection이다.
- global A*는 실제 구현됐지만 local costmap/DWA는 아직 없다.
- Stateflow 모델과 주행 plant는 아직 하나의 top model로 통합하지 않았다.
