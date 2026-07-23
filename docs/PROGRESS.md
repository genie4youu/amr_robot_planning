# 프로젝트 진행 현황

최종 갱신: 2026-07-23

## 전체 상태

- 현재 단계: 다중 실내환경·LiDAR 강건성·log-odds/EKF 기초까지 통합 수직 절편 확장
- 실행 모델: `amr_scenario_supervisor.slx`, `amr_industrial_supervisor.slx`, `amr_integrated_delivery_system.slx`
- 알고리즘 코드: 2D LiDAR raycasting/noise/dropout/delay/watchdog, log-odds mapping, pose EKF uncertainty, local costmap, DWA, A*, 독립 안전 게이트
- 최근 검증: 2026-07-22, 3개 환경 × 4개 주행 상황 12/12 및 통합 Stateflow 조합 12/12 PASS
- 지도 UI: 사무실·병원·창고 선택, 실제 scan ray, 동적 장애물, A* 경로, DWA 회피, 배터리와 상태 표시

## 다중 환경 Scenario Lab 결과

| 환경 | 정상 | 돌발 장애물 | 배터리 부족 | 잘못된 길 |
| --- | ---: | ---: | ---: | ---: |
| 사무실/배송 구역 | 26.35 s | 34.40 s | 74.45 s | 35.05 s |
| 병원 중앙 복도 | 26.40 s | 40.00 s | 61.40 s | 35.20 s |
| 물류 창고 랙 구역 | 42.00 s | 56.50 s | 66.30 s | 51.65 s |

- 12개 조합 모두 `CollisionFree`, `LidarValidated`, `DwaValidated` PASS
- 모든 최종 위치 오차: 약 `0.080 m` 이하
- LiDAR range noise, beam dropout, 주기적 frame dropout, 1-sample delay 적용
- stale scan watchdog 단위검사와 dropout 후 복귀 PASS
- 환경 비교 그림: `docs/images/2026-07-22_environment_matrix_trajectories.png`
- 병원 UI 캡처: `docs/images/2026-07-22_hospital_scenario_ui.png`
- 회귀검증 결과: `data/expected/2026-07-22_environment_matrix_verification.mat`

## 실무형 Stateflow Supervisor 결과

- 상위 수명주기: PowerOff, Boot, Operational, ControlledShutdown, FaultLatched, EmergencyStopLatched
- `Operational` 병렬 영역: Mission, Navigation, Energy, Safety, Health
- 자동 시나리오: nominal, obstacle, battery, health fault, emergency stop
- 구조 검사: unconnected port/line 없음, Stateflow lint 정상
- 결과 그림: `docs/images/2026-07-21_industrial_supervisor_modes.png`
- 검증 데이터: `data/expected/2026-07-21_industrial_supervisor_verification.mat`

## 통합 모델 결과

- 모델: `models/system/amr_integrated_delivery_system.slx`
- 실제 Scenario Plant 신호를 Industrial Supervisor 20개 입력으로 변환
- 장애물: Navigation `[0 1 2 3 2 0]`, Safety `[0 1 2 0]`
- 배터리: Energy `[0 1 2 3 0]`
- lifecycle: 모든 시나리오 `[0 1 2 3 0]`
- `NavFailed` 없이 정상 종료, 최종 위치 오차 `0.077 m` 이하
- 3개 환경 × 4개 상황에서도 lifecycle `[0 1 2 3 0]`, NavFailed 없음
- 통합 12개 조합 결과: `data/expected/2026-07-22_integrated_environment_matrix.mat`

## Mapping과 Localization 기초 결과

- inverse range sensor model의 free/occupied log-odds 누적 구현
- free ray cell, hit cell, hit 뒤 unknown cell 검증 PASS
- `[x,y,theta]` pose EKF prediction/update와 covariance 기반 health 판정 구현
- 장시간 prediction에서 uncertainty 증가, 반복 측정 update 후 health 복귀 PASS
- 두 기능은 아직 주행 제어 루프에 연결하지 않은 알고리즘 prototype 단계

## 단계 대시보드

| 단계 | 상태 | 완료 기준 확인 | 다음 작업 |
| --- | --- | --- | --- |
| 00 Project Setup | 진행 중 | 부분 | 데이터 계약과 artifact 규칙 확정 |
| 01 Math/Frames/Timing | 다음 | 아니요 | 좌표계와 다중 rate 규칙 고정 |
| 02 Robot Modeling | 진행 중 | 부분 | 포화·지연·폐루프 제어 추가 |
| 03 Sensor Simulation | 진행 중 | 부분 | encoder/IMU 모델 추가 |
| 04 Mapping | 진행 중 | 부분 | log-odds 지도를 온라인 주행에 연결 |
| 05 Localization | 진행 중 | 부분 | odometry/IMU 입력과 landmark 측정 연결 |
| 06 SLAM | 대기 | 아니요 | mapping/localization 검증 후 시작 |
| 07 Global Planning | 진행 중 | 부분 | 경로 없음/재계획 timeout 확장 |
| 08 Local Planning | 진행 중 | 부분 | no-valid-candidate/oscillation 복구 추가 |
| 09 Stateflow Supervisor | 진행 중 | 부분 | debounce, retry 제한, operator ack 추가 |
| 10 Safety/Recovery | 진행 중 | 부분 | TTC와 복합 fault 우선순위 추가 |
| 11 Integration | 진행 중 | 부분 | typed bus와 rate transition 정리 |
| 12 Verification | 상시 | 부분 | 복합 fault와 경계값 시나리오 누적 |
| 13 Delivery Extensions | 보류 | 아니요 | 기본 배송 성공 후 시작 |

## 다음 세션 시작점

MATLAB에서 다음 명령으로 현재 Scenario Lab을 재현한다.

```matlab
projectRoot = setup_amr_project();
amrScenarioApp = launch_amr_scenario_ui("obstacle", "hospital");
```

3개 환경 × 4개 시나리오 자동 검증은 다음 명령으로 실행한다.

```matlab
environmentSummary = run_environment_matrix();
```

실무형 감독 제어기 검증은 다음 명령으로 실행한다.

```matlab
industrialSummary = run_industrial_supervisor_scenarios();
```

통합 Plant/Supervisor의 12개 조합 검증은 다음 명령으로 실행한다.

```matlab
load_system('models/system/amr_integrated_delivery_system.slx')
open_system('models/system/amr_integrated_delivery_system.slx')
integratedEnvironmentSummary = run_integrated_environment_matrix();
```

다음 구현은 log-odds 지도를 Scenario Plant의 온라인 local/global costmap에 연결하고, pose EKF health를 Industrial Supervisor 입력으로 전달하는 것이다.

## 갱신 규칙

- 작업을 시작하면 해당 단계를 `진행 중`으로 바꾼다.
- 완료 조건을 모두 확인한 후에만 `완료`로 바꾼다.
- 막힌 문제와 해결은 해당 단계의 `진행결과.md`에 함께 기록한다.
- 다음 세션에서 바로 재개할 수 있도록 마지막 수행 명령과 다음 한 가지 작업을 남긴다.
