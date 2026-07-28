# AMR Scenario Lab — 장애물·배터리·경로이탈

- 날짜: 2026-07-21
- 결과: 네 시나리오 PASS
- 선행 실험: [[2026-07-20_AMR_실내맵_UI]]

## 목적

12m × 8m 실내 지도에서 정상 배송뿐 아니라 돌발 장애물, 배터리 부족, 잘못된 길 진입을 재현하고 Stateflow 상위 제어기가 정지·우회·충전·재경로 후 배송을 완료하는지 확인한다.

## 모델 구조

- `amr_scenario_supervisor.slx`
- Stateflow 입력: obstacle, batteryLow, offRoute, atCharger, recoveryComplete, goalReached
- Stateflow 출력: missionMode 0~8
- Scenario engine: pose feedback waypoint 이동, 배터리 drain/charge, deterministic fault injection
- UI: 시나리오 드롭다운, 대형 지도, 동적 장애물, 충전소, 배터리, 경고, pose 재생

## 실행

```matlab
cd('<작업공간>/projects/indoor_delivery_amr')
addpath('scripts','src')
amrScenarioApp = launch_amr_scenario_ui("obstacle");
scenarioSummary = run_all_amr_scenarios();
```

## 검증 결과

| 상황 | 완료 시간 | 최소 배터리 | mode 순서 | 최종 위치 오차 |
| --- | ---: | ---: | --- | ---: |
| normal | 32.45s | 93.50% | `[0 1 8]` | 0.0796m |
| obstacle | 44.15s | 91.16% | `[0 1 2 3 1 8]` | 0.0789m |
| battery | 60.20s | 19.66% | `[0 1 4 5 1 8]` | 0.0795m |
| wrong_turn | 38.40s | 92.31% | `[0 1 6 7 1 8]` | 0.0795m |

- 모델 unconnected port/line 검사와 Stateflow lint 통과
- UI의 장애물 우회 상태, pose, 속도와 배터리 표시 확인
- 결과: `projects/indoor_delivery_amr/results/2026-07-21_scenario_verification.mat`
- 캡처: `projects/indoor_delivery_amr/results/2026-07-21_scenario_ui_obstacle.png`

## 시행착오

1. MATLAB Function 블록이 외부 package 함수의 여러 출력 타입을 code generation 대상으로 추론하지 못했다.
2. desktop simulation-only `coder.extrinsic` 호출로 선언하고 출력 타입을 명시해 해결했다.
3. R2025b UI control은 일부 cell label 표현을 거부해 string array로 변경했다.
4. 요약 table의 name-value는 `VariableNames=...` 최신 문법으로 변경했다.

## 현재 한계

- 장애물과 경로이탈은 센서 검출이 아니라 deterministic fault injection이다.
- 우회·복귀 경로는 A*/DWA가 아니라 사전 정의 waypoint다.
- 맵 벽과 차체 충돌 판정은 아직 없다.
- UI는 solver 완료 후 로그를 재생한다.

## 다음 작업

2D range sensor의 ray-map 교차 계산을 구현해 장애물 감지를 실제 센서 출력으로 교체한다.
