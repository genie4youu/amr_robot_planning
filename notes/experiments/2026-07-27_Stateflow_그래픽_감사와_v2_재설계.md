# Stateflow 그래픽 감사와 v2 재설계

## 범위와 보호 조치

- 감사 대상 원본: `models/mission_supervisor/versions/amr_mission_supervisor_v01_logic_baseline_2026_07_24.slx`
- 원본 SHA-256: `6205664FC16980055E717A33EB1B166A804095709F7C3C5F2759D6FDF60DD6B7`
- 재설계 결과: `models/mission_supervisor/versions/amr_mission_supervisor_v02a_curved_attempt_2026_07_27.slx`
- 최종 전체 배치 전 백업:
  `work/backups/amr_mission_supervisor_v2_graphical_pre_layout_20260727_102331.slx`
- 기존 레이아웃 스크립트는 감사 전에 실행하지 않았다.
- 원본 `v1`은 저장하거나 덮어쓰지 않았고, `v2`는 원본에서 새로 복사한 별도 모델이다.

요청된 `exchange/from-vault/2026-07-27_stateflow_graphical_review.md`는 그래픽 검토 본문이
아니라 해당 파일을 생성하는 PowerShell 명령만 들어 있었다. 따라서 감사 기준은 사용자가
대화에서 명시한 과도한 외곽 곡선, child State 쏠림, 전이 routing 및 현재 프로젝트의 실제
표준·스크립트·검사기·테스트로 잡았다.

## 감사 결론

기존 자동화가 문제를 직접 만들거나 통과시킨 부분이 확인되었다.

| 감사 항목 | 확인 결과 | 영향 |
| --- | --- | --- |
| 레이아웃 스크립트 | Navigation T130, T133 등을 매우 먼 midpoint로 보내고 큰 외곽 곡선을 허용 | child State보다 곡선 bounding box가 커짐 |
| RoutingType | 실제 큰 외곽 우회인 일부 경로를 `Bidirectional`로 분류 | 타입과 실제 경로 의도가 어긋남 |
| 검사기 | 외곽 lane 최소 40 px만 검사하고 최대 이격, canvas 활용률과 좌우 균형을 검사하지 않음 | 멀리 보낼수록 통과하기 쉬움 |
| 테스트 | 기존 카운트 테이블 일치만 확인하고 큰 canvas와 비정상 detour를 실패시키지 않음 | 회귀 방지 실패 |
| `fitToView` | 원인은 아니며 큰 그래픽 bounding box를 한 화면에 맞추면서 State를 작게 보이게 함 | 문제를 더 두드러지게 표시 |
| Subviewer 저장 | 저장 후 scope 좌표 평행이동은 확인했으나 시각 균형은 확인하지 않음 | 누적 전체 배치 시 외곽 좌표 증폭 가능 |

원본 NavigationRegion의 State bounding box는 약 `1490 × 540`, 전체 그래픽 bounding box는
약 `2220 × 1200`으로 State 활용률이 `0.302`였다. 방향별 확장은 왼쪽 154, 오른쪽 576,
위 363, 아래 297 px였다. 즉 화면 배율이 아니라 전이 geometry가 canvas를 불필요하게
확장한 것이 핵심 원인이었다.

## 적용한 수정

### 자동화와 안전장치

- 레이아웃 함수에 명시적 `ModelPath`, 원본 쓰기 차단, 그래픽 gate 옵션을 추가했다.
- 전체 배치에서는 State/Transition `LabelString`을 공백과 줄바꿈까지 정확히 보존한다.
- full-layout 반복은 원본에서 새 후보를 만들도록 표준화했다.
- 모든 Transition의 실제 endpoint와 midpoint를 속성 적용 뒤 다시 읽고 저장 후 재검증한다.
- 외곽 lane 최대 180 px, Subviewer State bounding-box 활용률 최소 0.50, 방향별 canvas 확장
  최대 180 px, 양방향 경로 envelope 이탈 최대 120 px와 detour ratio 최대 2.20 검사를
  추가했다.
- Stateflow 속성 결합으로 geometry 적용 순서가 결과를 바꾸는 전이는 행별
  `GeometryApplyOrder`로 명시했다. 특히 T59는 `MidPoint` 뒤 Destination을 다시 설정하면
  midpoint가 약 -724까지 이동하는 현상을 확인해 기본 `DSM` 순서를 유지했다.

### State 재배치 요약

저장 후 재열기한 실제 좌표다. Subchart 내부 좌표는 각 `Subviewer` 기준이다.

| Scope/State | v1 Position | v2 Position | 의도 |
| --- | --- | --- | --- |
| PowerOff | `[80 283 620 320]` | `[105 306 600 300]` | 상위 정상 흐름 시작 |
| Boot | `[1050 283 620 320]` | `[845 306 600 300]` | PowerOff와 간격 축소 |
| Operational | `[2300 283 1500 1120]` | `[1625 306 1900 1120]` | 내부 5개 Region을 균형 배치 |
| ControlledShutdown | `[4000 283 660 280]` | `[3705 306 700 300]` | 정상 흐름 오른쪽 |
| EmergencyStopLatched | `[700 1803 900 380]` | `[725 1646 900 360]` | 하단 예외 흐름 |
| FaultLatched | `[2400 1803 1100 360]` | `[2305 1646 1100 360]` | 하단 실패 흐름 |
| MissionRegion | `[2360 403 660 480]` | `[1685 426 820 500]` | compact snake 흐름 |
| NavigationRegion | `[3080 403 660 480]` | `[2605 426 860 500]` | 정상/복구 두 행 |
| NavIdle | `[234 463 378 130]` | `[80 519 300 130]` | 정상 상단 왼쪽 |
| Planning | `[694 463 390 150]` | `[530 519 330 150]` | 정상 상단 중앙 |
| Tracking | `[1184 463 430 160]` | `[1040 519 380 160]` | 정상 상단 오른쪽 |
| NavFailed | `[1294 803 430 170]` | `[80 869 360 170]` | 실패 하단 왼쪽 |
| Recovery | `[714 723 480 280]` | `[540 789 400 250]` | 복구 하단 중앙 |
| Replanning | `[234 813 396 150]` | `[1040 869 330 150]` | Tracking 바로 아래 |

전체 37개 State의 선언적 좌표는
`scripts/layout_amr_mission_supervisor_v1.m`의 `createStateLayout`이 단일 기준이다.

### Navigation Transition 재라우팅 요약

아래 값도 저장 후 다시 읽은 실제 geometry다. 모든 행의 Source, Destination,
`LabelString`과 `ExecutionOrder`는 v1과 동일하다.

| SSID | Source → Destination | SO/DO | MidPoint | LabelPosition | EO |
| ---: | --- | --- | --- | --- | ---: |
| 125 | default → NavIdle | `-/0` | `[230 459]` | `[229 439 2 16]` | 1 |
| 126 | NavIdle → Planning | `3/9.2` | `[451 584]` | `[80 689 400 54]` | 1 |
| 127 | Planning → Tracking | `3/9.094` | `[946 594]` | `[870 529 160 36]` | 1 |
| 128 | Planning → Recovery | `6.5/11.25` | `[640 725]` | `[500 749 100 36]` | 2 |
| 129 | Planning → Recovery | `5.5/0.075` | `[750 725]` | `[500 719 100 20]` | 3 |
| 130 | Tracking → Replanning | `6.197/0` | `[1160 774]` | `[1040 789 130 20]` | 1 |
| 131 | Tracking → Recovery | `7.974/1.310` | `[977.365 721.365]` | `[950 754 160 20]` | 2 |
| 132 | Tracking → NavIdle | `11.684/0` | `[750 449]` | `[600 374 650 36]` | 3 |
| 133 | Replanning → Tracking | `0/6.197` | `[1300 774]` | `[1200 789 240 20]` | 1 |
| 134 | Replanning → Recovery | `9/3.36` | `[994 944]` | `[850 1054 140 20]` | 2 |
| 135 | Replanning → Recovery | `8/3.96` | `[990 984]` | `[1050 1054 100 20]` | 3 |
| 136 | Recovery → Planning | `11/6.803` | `[606.667 733]` | `[80 749 360 20]` | 1 |
| 137 | Recovery → Planning | `1/4.2` | `[792 729]` | `[80 774 360 36]` | 2 |
| 138 | Recovery → NavFailed | `9/2.294` | `[494 914]` | `[450 1069 100 20]` | 3 |

전체 67개 Transition의 선언적 속성과 `RoutingType`은 같은 스크립트의
`createTransitionLayout`과 `addRoutingMetadata`가 단일 기준이다.

## 검증 결과

| 검증 | 결과 |
| --- | --- |
| v1/v2 Chart 설정 | 동일 |
| State 논리 서명 | 37/37 동일 |
| Transition Source/Destination/LabelString/ExecutionOrder | 67/67 동일 |
| Data 논리 서명 | 42/42 동일 |
| Event 논리 서명 | 0/0 동일 |
| hard graphical violation | 0 |
| exact routing violation | 0 |
| State/State, label/State, label/label 겹침 | 0 |
| 관계없는 State 관통 | 0 |
| label/path 근사 경고 | 0 |
| canvas balance violation | 0 |
| excessive outer lane violation | 0 |
| bidirectional outer/detour violation | 0 |
| 보수적 path/path 근사 경고 | 3 |
| MATLAB Code Analyzer | 변경한 5개 `.m` 파일 issue 0 |
| Update Diagram / 모델 dirty | PASS / `off` |
| `model_check` | healthy |
| 그래픽 단위 테스트 | 15/15 PASS |
| Supervisor 인터페이스 테스트 | 16/16 PASS |
| scripted-plant 시나리오 | v2 모델 9/9 PASS |
| 공통 알고리즘 회귀 | 8/8 PASS |

최종 canvas 활용률은 Chart 0.864, Mission 0.797, Navigation 0.711, Safety 0.593,
Health 0.665, Energy 0.678이다. Navigation 방향별 확장은 왼쪽 10.4, 오른쪽 20,
위 145, 아래 50 px로 원본보다 크게 줄었다.

### 남은 보수적 근사 경고

Stateflow API가 실제 렌더링 spline을 제공하지 않아 검사기는 endpoint–midpoint–endpoint
두 선분을 사용한다. 다음 세 쌍은 hard/exact 또는 label 경고가 아니며 최종 화면 검토 대상과
단위 테스트에 명시적으로 고정했다.

| Transition 쌍 | 이유 |
| --- | --- |
| T60 FaultLatched→Boot / T54 Operational→EmergencyStopLatched | 상위 차트의 서로 다른 장거리 곡선을 두 선분으로 근사할 때 교차 |
| T91 Loading→Aborting / T83 Loading→Aborting | 동일 Source/Destination의 병렬 중단 경로가 하나의 endpoint로 수렴 |
| T80 ValidateJob→Aborting / T87 ReturnHome→Completed | compact two-row Mission 배치에서 취소 경로와 정상 복귀 경로를 두 선분으로 근사할 때 교차 |

Junction을 waypoint로 추가하면 논리 구조가 달라지므로 이번 routing-only 의미 보존 범위에서는
사용하지 않았다. 이 세 경고는 숨기지 않으며, 이후 실제 spline 기반 검사가 가능해지거나
Mission 논리 구조를 별도 리팩터링할 때 다시 제거한다.

`sfprint(..., wholeChart=true)`로 서브차트를 내보내면 객체보다 큰 편집 작업면이 포함되어
오른쪽과 아래에 큰 빈 배경이 생긴다. 이는 저장 후 좌표로 계산한 canvas 지표와 별개다.
최종 판단은 `fitToView` 편집기 화면과 좌표 검사 결과를 함께 사용한다.
