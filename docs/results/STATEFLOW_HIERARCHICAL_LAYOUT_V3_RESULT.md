# Mission Supervisor 재귀 Stateflow 레이아웃 v3 결과

## 1. 대상과 결론

- 원본: `models/mission_supervisor/amr_mission_supervisor.slx`
- 후보: `work/layout_candidates/amr_mission_supervisor_layout_v3.slx`
- 실행일: 2026-07-28
- 원본 모델은 수정하지 않았다.
- State 37개, Transition 67개, Junction 0개, Data 42개를 유지했다.
- State/Transition SSID, 이름·LabelString, Source/Destination, 계층, decomposition,
  State type, 모든 ExecutionOrder와 outgoing 순서, Data/Event/Message/Function 서명이
  저장·재열기 전후 동일했다.
- 최종 검사 결과는 hard 0, exact routing 0, layout-quality 0, advisory 0이다.
- Stateflow spline을 두 선분으로 근사할 때만 보이는 path–path 경고 1건(T60/T54)은
  Junction 없이 제거할 수 없는 루트 장애물 연결 때문에 검토 예외로 고정했다.

## 2. 발견한 전체 계층

하드코딩된 Region 목록이 아니라 부모 관계를 재귀 탐색해 다음 7개 container를 발견했다.
가장 깊은 Subchart부터 처리하고, 각 scope에서 State 배치 직후 Transition을 다시 라우팅했다.

| 순서 | 경로 | 종류 | 깊이 | 직접 State | 직접 Transition | Junction |
| ---: | --- | --- | ---: | ---: | ---: | ---: |
| 1 | `MissionSupervisor/Operational/MissionRegion` | Subchart | 2 | 9 | 18 | 0 |
| 2 | `MissionSupervisor/Operational/NavigationRegion` | Subchart | 2 | 6 | 14 | 0 |
| 3 | `MissionSupervisor/Operational/SafetyRegion` | Subchart | 2 | 3 | 6 | 0 |
| 4 | `MissionSupervisor/Operational/HealthRegion` | Subchart | 2 | 3 | 6 | 0 |
| 5 | `MissionSupervisor/Operational/EnergyRegion` | Subchart | 2 | 5 | 8 | 0 |
| 6 | `MissionSupervisor/Operational` | Composite State | 1 | 5 | 0 | 0 |
| 7 | `MissionSupervisor` | Chart | 0 | 6 | 15 | 0 |

## 3. 계층별 State Position 전후

MissionRegion의 직접 자식 State만 이동·크기 조정했다. 나머지 State 위치가 동일한 것은
검사 누락이 아니라 기존 위치가 새 품질 기준을 만족해 보존된 결과다.

| 전체 경로 | SSID | 변경 전 Position | 변경 후 Position |
| --- | ---: | --- | --- |
| MissionSupervisor/PowerOff | 43 | `[80 306 600 300]` | `[80 306 600 300]` |
| MissionSupervisor/Boot | 44 | `[820 306 600 300]` | `[820 306 600 300]` |
| MissionSupervisor/Operational | 45 | `[1600 306 1900 1120]` | `[1600 306 1900 1120]` |
| MissionSupervisor/ControlledShutdown | 46 | `[3680 306 700 300]` | `[3680 306 700 300]` |
| MissionSupervisor/FaultLatched | 47 | `[2450 1976 1100 360]` | `[2450 1976 1100 360]` |
| MissionSupervisor/EmergencyStopLatched | 48 | `[500 1976 900 360]` | `[500 1976 900 360]` |
| MissionSupervisor/Operational/MissionRegion | 62 | `[1660 426 820 500]` | `[1660 426 820 500]` |
| MissionSupervisor/Operational/EnergyRegion | 64 | `[2820 976 560 320]` | `[2820 976 560 320]` |
| MissionSupervisor/Operational/SafetyRegion | 65 | `[1660 976 520 320]` | `[1660 976 520 320]` |
| MissionSupervisor/Operational/HealthRegion | 66 | `[2240 976 520 320]` | `[2240 976 520 320]` |
| MissionSupervisor/Operational/MissionRegion/Idle | 67 | `[147 226 300 120]` | `[197 199 300 120]` |
| MissionSupervisor/Operational/MissionRegion/ValidateJob | 68 | `[537 226 320 120]` | `[532 199 320 120]` |
| MissionSupervisor/Operational/MissionRegion/NavigatePickup | 69 | `[947 226 340 120]` | `[887 199 340 120]` |
| MissionSupervisor/Operational/MissionRegion/Loading | 70 | `[1377 226 300 120]` | `[1262 199 300 120]` |
| MissionSupervisor/Operational/MissionRegion/NavigateDropoff | 71 | `[1767 226 340 120]` | `[1597 199 340 120]` |
| MissionSupervisor/Operational/MissionRegion/Unloading | 72 | `[2197 226 320 120]` | `[1972 199 320 120]` |
| MissionSupervisor/Operational/MissionRegion/ReturnHome | 73 | `[2607 226 320 120]` | `[2327 199 320 120]` |
| MissionSupervisor/Operational/MissionRegion/Aborting | 75 | `[537 646 2780 140]` | `[1389.5 469 400 100]` |
| MissionSupervisor/Operational/MissionRegion/Completed | 76 | `[3017 226 300 120]` | `[2682 199 300 120]` |
| MissionSupervisor/Operational/NavigationRegion | 118 | `[2580 426 860 500]` | `[2580 426 860 500]` |
| MissionSupervisor/Operational/NavigationRegion/NavIdle | 119 | `[80 165 300 130]` | `[80 165 300 130]` |
| MissionSupervisor/Operational/NavigationRegion/Planning | 120 | `[530 165 330 150]` | `[530 165 330 150]` |
| MissionSupervisor/Operational/NavigationRegion/Tracking | 121 | `[1040 165 380 160]` | `[1040 165 380 160]` |
| MissionSupervisor/Operational/NavigationRegion/Replanning | 122 | `[1040 515 330 150]` | `[1040 515 330 150]` |
| MissionSupervisor/Operational/NavigationRegion/Recovery | 123 | `[540 435 400 250]` | `[540 435 400 250]` |
| MissionSupervisor/Operational/NavigationRegion/NavFailed | 124 | `[80 515 360 170]` | `[80 515 360 170]` |
| MissionSupervisor/Operational/EnergyRegion/EnergyNormal | 139 | `[80 100 300 120]` | `[80 100 300 120]` |
| MissionSupervisor/Operational/EnergyRegion/EnergyLow | 140 | `[480 100 300 120]` | `[480 100 300 120]` |
| MissionSupervisor/Operational/EnergyRegion/EnergyCritical | 141 | `[880 100 340 130]` | `[880 100 340 130]` |
| MissionSupervisor/Operational/EnergyRegion/GoToCharger | 142 | `[280 400 360 140]` | `[280 400 360 140]` |
| MissionSupervisor/Operational/EnergyRegion/Charging | 143 | `[860 400 340 140]` | `[860 400 340 140]` |
| MissionSupervisor/Operational/SafetyRegion/SafetyClear | 152 | `[80 100 320 120]` | `[80 100 320 120]` |
| MissionSupervisor/Operational/SafetyRegion/Slowdown | 153 | `[500 100 320 120]` | `[500 100 320 120]` |
| MissionSupervisor/Operational/SafetyRegion/ProtectiveStop | 154 | `[290 400 400 150]` | `[290 400 400 150]` |
| MissionSupervisor/Operational/HealthRegion/Healthy | 161 | `[80 100 320 120]` | `[80 100 320 120]` |
| MissionSupervisor/Operational/HealthRegion/Degraded | 162 | `[500 100 340 120]` | `[500 100 340 120]` |
| MissionSupervisor/Operational/HealthRegion/FaultRequest | 163 | `[290 400 420 150]` | `[290 400 420 150]` |

## 4. 계층별 bounds와 route 지표

Bounds는 `[minX minY maxX maxY]`다. Route ratio 열은 최대값, deviation은 px다.

| 계층 | State bbox 전 | State bbox 후 | Graphic bbox 전 | Graphic bbox 후 | 최대 route ratio 전→후 | 최대 deviation 전→후 |
| --- | --- | --- | --- | --- | ---: | ---: |
| MissionRegion | `[147 226 3317 786]` | `[197 199 2982 569]` | `[77 96 3317 786]` | `[107 99 2982 569]` | 1.616→1.001 | 271.4→60.0 |
| NavigationRegion | `[80 165 1420 685]` | 동일 | `[69.6 20 1440 735]` | `[20 65 1420 685]` | 1.491→1.491 | 95.0→95.0 |
| SafetyRegion | `[80 100 820 550]` | 동일 | `[20 4 820 706]` | `[20 4 832 550]` | 1.187→1.187 | 120.8→120.8 |
| HealthRegion | `[80 100 840 550]` | 동일 | `[80 3.2 1020 550]` | `[80 3.2 930 550]` | 1.037→1.037 | 60.0→60.0 |
| EnergyRegion | `[80 100 1220 540]` | 동일 | `[20 3.2 1220 620]` | 동일 | 1.437→1.437 | 402.7→402.7 |
| Operational | `[1660 426 3440 1296]` | 동일 | 동일 | 동일 | 1.000→1.000 | 0.0→0.0 |
| MissionSupervisor | `[80 306 4380 2336]` | 동일 | `[0 126 4380 2506]` | `[20 206 4380 2336]` | 2.041→1.094 | 964.2→413.9 |

최종 mean/max route length ratio는 Mission 1.000/1.001, Navigation 1.099/1.491,
Safety 1.040/1.187, Health 1.006/1.037, Energy 1.060/1.437, Operational 1.000/1.000,
Chart 1.006/1.094다.

Energy의 T151은 direct segment가 GoToCharger State 또는 T149 path와 충돌해 한 midpoint로
직선화할 수 없다. maximum deviation은 402.7px이지만 State envelope 확장은 왼쪽 60px,
아래 80px이고 route ratio는 1.437이므로 외곽 lane 예외로 유지했다.

## 5. MissionRegion 상세 결과

- 정상 행 State 높이: 모두 120px
- 정상 행 수직 중심: 모두 y=259px
- 정상 행 수평 간격: 모두 35px
- 정상 행 bbox: `[197 199 2982 319]`
- Aborting: `[1389.5 469 400 100]`
- 정상 행과 Aborting 사이 간격: 150px
- 정상 행 중심과 Aborting 중심: 모두 x=1589.5px
- Aborting 폭: 2780→400px, 2380px(85.6%) 감소
- Mission State bbox: `[197 199 2982 569]`, 크기 2785×370px
- Mission 전체 graphic bbox: `[107 99 2982 569]`, 크기 2875×470px

초기 배치는 로컬 `[100 120]`에서 시작했지만 Stateflow가 첫 저장 때 scope 전체를
평행이동해 재열기 후 `[197 199]`로 안정화했다. 이는 부모 MissionRegion State의 Position을
내부 정렬 영역으로 사용한 결과가 아니며, 200px 초과 offset 경고 기준 안에서 두 번째 실행
변화 0으로 확인했다.

### 정상·복귀 Transition

- 정상 진행 7개(T78, T79, T81, T82, T84, T85, T87)는 모두 3시→9시 수평 직선이다.
- T88 Completed→Idle은 `[2832 199] → [1589.5 139] → [347 199]`다.
  상단 최대 이탈은 80→60px으로 줄었고 한 번만 완만하게 휜다.
- T89 Aborting→Idle은 `[1389.5 505.87] → [924.82 412.43] → [460.13 319]`다.
  midpoint deviation은 271.4→0px, 왼쪽 State envelope 이탈은 60→0px이다.

### Aborting 진입 대각선 직선

다음 8개 Transition의 Source는 정상 State 아래쪽(y=319), Destination은 Aborting
위쪽(y=469)이며 midpoint는 endpoint 평균이다. Destination x는 1419.5부터 1759.5까지
좌우 순서를 보존해 분산했고 실제 DestinationOClock은 약 10.72시부터 1.28시까지 모두 다르다.

| SSID | Source | Source x | Destination x | Source/Destination OClock |
| ---: | --- | ---: | ---: | --- |
| T80 | ValidateJob | 692.0 | 1419.5 | 6.00 / 10.72 |
| T90 | NavigatePickup | 1057.0 | 1468.1 | 6.00 / 11.09 |
| T91 | Loading | 1312.0 | 1516.6 | 7.00 / 11.45 |
| T83 | Loading | 1512.0 | 1565.2 | 5.00 / 11.82 |
| T92 | NavigateDropoff | 1767.0 | 1613.8 | 6.00 / 0.18 |
| T93 | Unloading | 2025.3 | 1662.4 | 7.00 / 0.55 |
| T86 | Unloading | 2238.7 | 1710.9 | 5.00 / 0.91 |
| T94 | ReturnHome | 2487.0 | 1759.5 | 6.00 / 1.28 |

## 6. 직선화와 외곽 lane

직선화된 Transition은 T89 Aborting→Idle(271.4→0px)과 T149
EnergyCritical→GoToCharger(43.7→0px)다. T50 PowerOff→EmergencyStopLatched도
다른 복귀 통로를 막지 않도록 아래쪽→상단 좌측 포트의 직접 대각선으로 재지정했다.

제거한 외곽 lane은 T89다. 남은 외곽 lane은 다음과 같다.

| Transition | 경로/이유 |
| --- | --- |
| T59 ControlledShutdown→PowerOff | 루트 정상 행 위 60px의 단일 복귀 lane |
| T60 FaultLatched→Boot | Operational 왼쪽 아래 모서리를 100px만 비키는 단일 bend; State 관통 없음 |
| T88 Completed→Idle | Mission 정상 행 위 60px의 단일 복귀 lane |
| T132 Tracking→NavIdle | Navigation 정상 행 위 70px의 단일 복귀 lane |
| T151 Charging→EnergyNormal | GoToCharger와 T149가 direct corridor를 막아 왼쪽 60px/아래 80px lane 유지 |

T60과 T54는 Stateflow가 렌더링 spline을 제공하지 않아 endpoint–midpoint–endpoint 두 선분으로
근사할 때 교차 1건으로 남는다. T60을 더 크게 외곽으로 보내면 deviation이 1754px까지
악화되므로 채택하지 않았다. 현재 T60 deviation은 413.9px이고 전체 Chart 최대 route ratio는
1.094다. Junction 추가는 논리 구조를 바꾸므로 사용하지 않았다.

## 7. 검사기·테스트·표준 변경

- `layout_amr_mission_supervisor.m`은 보호된 원본 대신 명시적 후보를 만들고 재귀 엔진을 호출한다.
- `layoutHierarchicalChart.m`은 container 자동 수집, depth-first State/Transition 처리,
  그래프 기반 main path·hub 분류, Subchart 좌표 정규화, ordered fan-in, nearest-port 직접선,
  label–path 회피와 안정화 후 라우팅 분류를 구현한다.
- 검사기는 7개 scope 각각의 child/graphic bbox, 로컬 offset, 중심 차이, 과대 State,
  canvas 확장, direct-route opportunity, route ratio/deviation을 보고한다.
- direct-route opportunity는 State뿐 아니라 sibling Transition 교차도 확인한다.
- 그래픽 테스트는 `AMR_SUPERVISOR_LAYOUT_MODEL`로 후보를 주입하며, 후보에서는 새 재귀
  quality gate를 0건으로 강제한다. 보호된 원본의 기존 검토 경고도 계속 호환한다.
- 그래픽 표준에 Subchart 로컬 좌표, 과대 State, ordered diagonal fan-in, 재귀 순서,
  idempotence와 bbox 기반 viewport 맞춤 규칙을 추가했다.

원본을 새 검사기로 감사하면 layout-quality 9건(과대 State 1, 로컬 offset 1,
Transition canvas 확장 5, direct-route opportunity 2)이었고 후보는 0건이다.

## 8. 저장·재열기·idempotence

- 최초 적용은 저장 안정화 2회가 필요했다. 첫 저장의 최대 State 위치 평행이동은 97px이었다.
- 저장→닫기→재열기 후 논리 서명과 geometry가 허용 오차 내 동일했다.
- 최종 후보에서 레이아웃을 다시 실행한 결과 안정화 1회였다.
- 두 번째 실행 변화: State Position 0, SourceEndpoint 0, MidPoint 0,
  DestinationEndpoint 0, LabelPosition 0, Source/DestinationOClock 0.

## 9. fitToView와 최종 화면 검토

Subchart State 자체를 맞추지 않고 내부 graphical bbox 중심에 가장 가까운 객체를 view하고
fitToView한 뒤, 화면의 55%×40% 안에 bbox가 들어오도록 scope별 ZoomFactor를 계산했다.

| Scope | Graphic bounds | 중심 객체 | ZoomFactor | 화면 결과 |
| --- | --- | --- | ---: | --- |
| MissionRegion | `[107 99 2982 569]` | T83 | 0.249 | 양 끝과 상·하단 lane 모두 표시, 중앙 정렬 |
| NavigationRegion | `[20 65 1420 685]` | T129 | 0.472 | 전체 State/label 표시 |
| SafetyRegion | `[20 4 832 550]` | T157 | 0.536 | 하단 ProtectiveStop 포함 표시 |
| HealthRegion | `[80 3.2 930 550]` | T169 | 0.536 | 상·하 여백 내 전체 표시 |
| EnergyRegion | `[20 3.2 1220 620]` | T149 | 0.475 | 하단 복귀 lane 포함 표시 |
| Operational | `[1600 306 3500 1426]` | Operational | 0.455 | 5개 Region 균형 표시 |
| MissionSupervisor | `[20 206 4380 2336]` | Chart | 0.206 | 루트 전체 표시 |

`wholeChart=true` PNG는 Subchart의 큰 작업면까지 포함해 빈 배경이 생기므로 판정에 쓰지 않았다.
최종 판정은 `wholeChart=false` 현재 viewport PNG와 저장 후 bounds 지표를 함께 사용했다.
검토 PNG는 `work/layout_review/*_final3.png`에 있다.

## 10. 최종 검증

| 검증 | 결과 |
| --- | --- |
| 논리 서명 및 SSID/ExecutionOrder/outgoing 순서 | PASS |
| hard / exact / layout-quality / advisory | 0 / 0 / 0 / 0 |
| conservative path–path warning | 1건, T60/T54 고정 검토 예외 |
| 저장·재열기 geometry | PASS |
| 두 번째 실행 idempotence | 모든 geometry delta 0 |
| Update Diagram | PASS |
| `model_check` | healthy (`unconnected_ports`, `unconnected_lines`, `stateflow_lint`) |
| Code Analyzer | 변경 MATLAB 파일 5개, issue 0 |
| Supervisor interface tests | 16/16 PASS |
| Stateflow graphical tests | 18/18 PASS |
| Supervisor scenarios | 9/9 PASS |
| 공통 알고리즘 회귀 | 8/8 PASS |

시나리오 결과 파일은 `results/2026-07-27_amr_mission_supervisor_layout_v3_verification.mat`이다.
